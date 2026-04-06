//
//  ParentChatDetailViewController.swift
//  OT main
//
//  Created by Garvit Pareek on 05/02/2026.
//


import UIKit
import Supabase
import FirebaseFirestore

class ParentChatDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ChatInputAccessoryViewDelegate {

    // MARK: - Properties
    var patientID: String?
    
    private let db = Firestore.firestore()
    private var allMessages: [MessageModel] = []
    
    private enum ChatItem {
        case message(MessageModel)
        case date(Date)
    }
    private var chatItems: [ChatItem] = []
    
    private var listener: ListenerRegistration?
    private var currentUserId: String?
    private var otId: String?
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .none
        tv.allowsSelection = false
        tv.keyboardDismissMode = .interactive
        tv.translatesAutoresizingMaskIntoConstraints = false
        // REMOVED: contentInsetAdjustmentBehavior = .never (We want default system behavior now)
        return tv
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = .gray
        ai.hidesWhenStopped = true
        return ai
    }()
    
    private lazy var customInputView: ChatInputAccessoryView = {
        let v = ChatInputAccessoryView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 60))
        v.delegate = self
        return v
    }()
    
    override var inputAccessoryView: UIView? { return customInputView }
    override var canBecomeFirstResponder: Bool { return true }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        tableView.register(ParentIncomingCell.self, forCellReuseIdentifier: "Incoming")
        tableView.register(ParentOutgoingCell.self, forCellReuseIdentifier: "Outgoing")
        tableView.register(DateSeparatorCell.self, forCellReuseIdentifier: "DateSeparator")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        setupUI()
        // REMOVED: setupKeyboardObservers() - Not needed with keyboardLayoutGuide
        
        fetchSessionAndOT()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        setupNativeNavBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    // REMOVED: viewDidLayoutSubviews with manual inset calculation.
    // The constraint to keyboardLayoutGuide handles this automatically now.
    
    // MARK: - Setup Logic
    private func setupNativeNavBar() {
        self.title = "Therapist"
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 1.00, green: 0.73, blue: 0.20, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .label
        navigationItem.rightBarButtonItem = nil
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            // Match the top constraint from ChatDetailViewController (use Safe Area)
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // KEY FIX FROM REFERENCE: Pin to keyboardLayoutGuide.topAnchor
            // This ensures the table resizes exactly with the keyboard/input bar, preventing white space.
            tableView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
    }
    
    // MARK: - Data Fetching
    private func fetchSessionAndOT() {
        loadingIndicator.startAnimating()
        Task {
            do {
                let user = try await supabase.auth.session.user
                let parentAuthId = user.id.uuidString
                
                let targetPatientID = self.patientID ?? UserDefaults.standard.string(forKey: "LastSelectedChildID")
                
                guard let searchID = targetPatientID else {
                    await MainActor.run { self.loadingIndicator.stopAnimating() }
                    return
                }
                
                let response = try await supabase
                    .from("patients")
                    .select("id, ot_id")
                    .eq("patient_id_number", value: searchID)
                    .eq("parent_uid", value: parentAuthId)
                    .single()
                    .execute()
                
                struct PatientIds: Decodable {
                    let id: UUID
                    let ot_id: UUID?
                }
                
                let data = try JSONDecoder().decode(PatientIds.self, from: response.data)
                
                if let otUUID = data.ot_id {
                    self.otId = otUUID.uuidString
                    self.currentUserId = data.id.uuidString
                    
                    await MainActor.run {
                        self.loadingIndicator.stopAnimating()
                        self.listenForMessages()
                    }
                }
            } catch {
                print("Error: \(error)")
                await MainActor.run { self.loadingIndicator.stopAnimating() }
            }
        }
    }
    
    // MARK: - Firestore & Grouping Logic
    private func getChatId() -> String? {
        guard let myId = currentUserId, let partnerId = otId else { return nil }
        let safeMyId = myId.lowercased()
        let safePartnerId = partnerId.lowercased()
        return safeMyId < safePartnerId ? "\(safeMyId)_\(safePartnerId)" : "\(safePartnerId)_\(safeMyId)"
    }
    
    private func listenForMessages() {
        guard let chatId = getChatId() else { return }
        
        listener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                self.allMessages = documents.compactMap { doc -> MessageModel? in
                    let data = doc.data()
                    guard let timestamp = data["date"] as? Timestamp else { return nil }
                    return MessageModel(
                        id: doc.documentID,
                        senderId: data["senderId"] as? String ?? "",
                        receiverId: data["receiverId"] as? String ?? "",
                        content: data["content"] as? String ?? "",
                        date: timestamp.dateValue()
                    )
                }
                
                self.processMessagesWithDates()
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToBottom()
                }
            }
    }
    
    private func processMessagesWithDates() {
        var newItems: [ChatItem] = []
        var lastDate: Date? = nil
        
        for msg in allMessages {
            let msgDate = Calendar.current.startOfDay(for: msg.date)
            
            if lastDate == nil || msgDate != lastDate {
                newItems.append(.date(msgDate))
                lastDate = msgDate
            }
            newItems.append(.message(msg))
        }
        self.chatItems = newItems
    }
    
    func didTapSend(text: String) {
        guard let chatId = getChatId(), let myId = currentUserId, let partnerId = otId else { return }
        let safeMyId = myId.lowercased()
        let safePartnerId = partnerId.lowercased()
        
        let messageData: [String: Any] = [
            "senderId": safeMyId,
            "receiverId": safePartnerId,
            "content": text,
            "date": FieldValue.serverTimestamp()
        ]
        
        db.collection("chats").document(chatId).collection("messages").addDocument(data: messageData)
        
        let summaryData: [String: Any] = [
            "lastMessage": text,
            "lastMessageTime": FieldValue.serverTimestamp(),
            "lastSenderId": safeMyId,
            "participants": [safeMyId, safePartnerId],
            "unreadCount_\(safePartnerId)": FieldValue.increment(Int64(1))
        ]
        db.collection("chats").document(chatId).setData(summaryData, merge: true)
        
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        guard !chatItems.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(row: self.chatItems.count - 1, section: 0)
            if self.tableView.numberOfRows(inSection: 0) > indexPath.row {
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = chatItems[indexPath.row]
        
        switch item {
        case .date(let date):
            let cell = tableView.dequeueReusableCell(withIdentifier: "DateSeparator", for: indexPath) as! DateSeparatorCell
            cell.configure(with: date)
            return cell
            
        case .message(let msg):
            let mySafeId = (currentUserId ?? "").lowercased()
            let senderSafeId = msg.senderId.lowercased()
            let isOutgoing = senderSafeId == mySafeId
            
            if isOutgoing {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Outgoing", for: indexPath) as! ParentOutgoingCell
                cell.configure(text: msg.content)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Incoming", for: indexPath) as! ParentIncomingCell
                cell.configure(text: msg.content)
                return cell
            }
        }
    }
}

// MARK: - CELLS (Unchanged)
class ParentOutgoingCell: UITableViewCell {
    private let bubbleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 1.00, green: 0.73, blue: 0.20, alpha: 1)
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
        return v
    }()
    private let label: UILabel = {
        let l = UILabel()
        l.textColor = .black
        l.numberOfLines = 0
        return l
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup() {
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(label)
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 260),
            label.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12)
        ])
    }
    func configure(text: String) { label.text = text }
}

class ParentIncomingCell: UITableViewCell {
    private let bubbleView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemFill
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        return v
    }()
    private let label: UILabel = {
        let l = UILabel()
        l.textColor = .label
        l.numberOfLines = 0
        return l
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup() {
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(label)
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 260),
            label.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12)
        ])
    }
    func configure(text: String) { label.text = text }
}
