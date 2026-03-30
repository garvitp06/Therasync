import UIKit
import FirebaseFirestore

class ChatDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ChatInputAccessoryViewDelegate {

    var chatName: String = "Chat"
    var currentUserId: String?
    var otherUserId: String?
    
    private let db = Firestore.firestore()
    private var allMessages: [MessageModel] = []
    
    private enum ChatItem {
        case message(MessageModel)
        case date(Date)
    }
    private var chatItems: [ChatItem] = []
    
    private var listener: ListenerRegistration?
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .white // Match background
        tv.separatorStyle = .none
        tv.allowsSelection = false
        tv.keyboardDismissMode = .interactive
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
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
        view.backgroundColor = .white
        setupUI()
        // REMOVED: setupKeyboardObservers() - No longer needed!
        
        tableView.register(OTIncomingMessageCell.self, forCellReuseIdentifier: "Incoming")
        tableView.register(OTOutgoingMessageCell.self, forCellReuseIdentifier: "Outgoing")
        tableView.register(DateSeparatorCell.self, forCellReuseIdentifier: "DateSeparator")
        
        tableView.dataSource = self
        tableView.delegate = self
        listenForMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        setupNativeNavBar()
        resetMyUnreadCount()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
        resetMyUnreadCount()
        // REMOVED: NotificationCenter removal - No observers to remove
    }
    
    // REMOVED: viewDidLayoutSubviews() manual inset adjustments.
    // The constraints now handle this automatically.

    private func resetMyUnreadCount() {
        guard let chatId = getChatId(), let myId = currentUserId else { return }
        let safeMyId = myId.lowercased()
        db.collection("chats").document(chatId).updateData(["unreadCount_\(safeMyId)": 0]) { _ in }
    }

    private func getChatId() -> String? {
        guard let myId = currentUserId, let otherId = otherUserId else { return nil }
        let safeMyId = myId.lowercased()
        let safeOtherId = otherId.lowercased()
        return safeMyId < safeOtherId ? "\(safeMyId)_\(safeOtherId)" : "\(safeOtherId)_\(safeMyId)"
    }
    
    // MARK: - Messages Logic
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
                    self.scrollToBottom(animated: true)
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
        guard let chatId = getChatId(), let myId = currentUserId, let otherId = otherUserId else { return }
        let safeMyId = myId.lowercased()
        let safeOtherId = otherId.lowercased()
        let messageData: [String: Any] = ["senderId": safeMyId, "receiverId": safeOtherId, "content": text, "date": FieldValue.serverTimestamp()]
        
        db.collection("chats").document(chatId).collection("messages").addDocument(data: messageData)
        let summaryData: [String: Any] = ["lastMessage": text, "lastMessageTime": FieldValue.serverTimestamp(), "lastSenderId": safeMyId, "participants": [safeMyId, safeOtherId], "unreadCount_\(safeOtherId)": FieldValue.increment(Int64(1))]
        db.collection("chats").document(chatId).setData(summaryData, merge: true)
        
        // Ensure scroll happens immediately
        scrollToBottom(animated: true)
    }

    // MARK: - UI Setup (The Fix)
    private func setupUI() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // KEY FIX: Constraint to keyboardLayoutGuide.topAnchor
            // This Guide automatically tracks the top of the keyboard OR the top of the inputAccessoryView.
            // It eliminates the white space and the hidden message issues simultaneously.
            tableView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
    }

    private func setupNativeNavBar() {
        self.title = chatName
        navigationItem.largeTitleDisplayMode = .never
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func scrollToBottom(animated: Bool) {
        guard !chatItems.isEmpty else { return }
        // We use a tiny delay to allow the layout (frame resize) to complete before scrolling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(row: self.chatItems.count - 1, section: 0)
            if self.tableView.numberOfRows(inSection: 0) > indexPath.row {
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
            }
        }
    }

    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return chatItems.count }

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
            let isIncoming = senderSafeId != mySafeId
            if isIncoming {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Incoming", for: indexPath) as! OTIncomingMessageCell
                cell.configure(text: msg.content)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Outgoing", for: indexPath) as! OTOutgoingMessageCell
                cell.configure(text: msg.content)
                return cell
            }
        }
    }
}

// MARK: - CELLS
// (Cells remain unchanged as they are correct)
class OTIncomingMessageCell: UITableViewCell {
    private let bubbleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.9, alpha: 1)
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let label: UILabel = {
        let l = UILabel()
        l.textColor = .black
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(label)
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
    required init?(coder: NSCoder) { fatalError() }
    func configure(text: String) { label.text = text }
}

class OTOutgoingMessageCell: UITableViewCell {
    private let bubbleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let label: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(label)
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
    required init?(coder: NSCoder) { fatalError() }
    func configure(text: String) { label.text = text }
}

class DateSeparatorCell: UITableViewCell {
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.9, alpha: 1)
        v.layer.cornerRadius = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .medium)
        l.textColor = .darkGray
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(containerView)
        containerView.addSubview(dateLabel)
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            containerView.heightAnchor.constraint(equalToConstant: 24),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            dateLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(with date: Date) {
        if Calendar.current.isDateInToday(date) { dateLabel.text = "Today" }
        else if Calendar.current.isDateInYesterday(date) { dateLabel.text = "Yesterday" }
        else {
            let f = DateFormatter(); f.dateFormat = "EEE, dd MMM"
            dateLabel.text = f.string(from: date)
        }
    }
}
