//
//  ChatListViewController.swift
//  OT main
//
//  Created by Alishri Poddar on 18/01/26.
//

import UIKit
import Supabase
import FirebaseFirestore

// MARK: - Model Definition
struct ChatSummary {
    let id: UUID
    let name: String
    let message: String
    let time: String
    let timestamp: Date
    let avatar: UIImage?
    let avatarURL: String?
    let unreadCount: Int
}

// MARK: - View Controller
class ChatListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    // MARK: - UI Components
    private var gradientView: GradientView!
    private let db = Firestore.firestore()
    private var chatListeners: [ListenerRegistration] = []
    
    // MARK: - Dynamic Height Properties
    private var containerHeightConstraint: NSLayoutConstraint?
    private let rowHeight: CGFloat = 80
    private let reservedTabBarHeight: CGFloat = 100 // Matches PatientListVC to clear the tab bar
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Chat"
        lbl.font = .systemFont(ofSize: 34, weight: .bold)
        lbl.textColor = .white
        return lbl
    }()
    
    private lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search"
        sb.searchBarStyle = .minimal
        sb.delegate = self
        if let textField = sb.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
            textField.textColor = .white
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search",
                attributes: [.foregroundColor: UIColor(white: 1.0, alpha: 0.6)]
            )
        }
        return sb
    }()
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 30
        v.layer.masksToBounds = true
        return v
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0)
        return tv
    }()

    private var chatSummariesMap: [UUID: ChatSummary] = [:]
    private var sortedChats: [ChatSummary] = []
    private var filteredChats: [ChatSummary] = []
    private var currentOtID: String?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupLayout()
        setupTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchPatientsAndListenForUpdates()
    }
    
    // NEW: Update height when subviews layout (ensures accurate frame calculations)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCardHeightIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        chatListeners.forEach { $0.remove() }
        chatListeners.removeAll()
    }
    
    // MARK: - Data Fetching & Real-time Listeners
    private func fetchPatientsAndListenForUpdates() {
            chatListeners.forEach { $0.remove() }
            chatListeners.removeAll()
            
            Task {
                do {
                    let user = try await supabase.auth.session.user
                    let otId = user.id.uuidString
                    self.currentOtID = otId
                    let safeOtId = otId.lowercased()
                    
                    let response = try await supabase
                        .from("patients")
                        .select()
                        .eq("ot_id", value: otId)
                        .execute()
                    
                    let decoder = JSONDecoder()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    decoder.dateDecodingStrategy = .formatted(formatter)
                    let fetchedPatients = try decoder.decode([Patient].self, from: response.data)
                    
                    for patient in fetchedPatients {
                        guard let patientId = patient.id?.uuidString, let patientUUID = patient.id else { continue }
                        let safePatientId = patientId.lowercased()
                        
                        // --- CAPTURE IMAGE URL HERE ---
                        let patientAvatarURL = patient.imageURL // From your Supabase Patient model
                        
                        let chatId = safeOtId < safePatientId ? "\(safeOtId)_\(safePatientId)" : "\(safePatientId)_\(safeOtId)"
                        
                        let listener = db.collection("chats").document(chatId).addSnapshotListener { [weak self] (document, error) in
                            guard let self = self else { return }
                            
                            var lastText = "No messages yet"
                            var timeString = ""
                            var count = 0
                            var timestampDate = Date.distantPast
                            
                            if let document = document, document.exists, let data = document.data() {
                                lastText = data["lastMessage"] as? String ?? "No messages yet"
                                if let timestamp = data["lastMessageTime"] as? Timestamp {
                                    timestampDate = timestamp.dateValue()
                                    timeString = self.formatMessageDate(timestampDate)
                                }
                                
                                let myUnreadKey = "unreadCount_\(safeOtId)"
                                count = data[myUnreadKey] as? Int ?? 0
                            }
                            
                            // --- POPULATE ChatSummary WITH THE URL ---
                            let chatSummary = ChatSummary(
                                id: patientUUID,
                                name: patient.fullName,
                                message: lastText,
                                time: timeString,
                                timestamp: timestampDate,
                                avatar: nil,
                                avatarURL: patientAvatarURL, // Pass the URL to the model
                                unreadCount: count
                            )
                            
                            self.chatSummariesMap[patientUUID] = chatSummary
                            self.updateFilteredChats()
                        }
                        self.chatListeners.append(listener)
                    }
                    
                } catch {
                    print("Error setting up listeners: \(error)")
                }
            }
        }
    
    private func updateFilteredChats() {
        self.sortedChats = Array(self.chatSummariesMap.values).sorted(by: { $0.timestamp > $1.timestamp })
        
        if let searchText = searchBar.text, !searchText.isEmpty {
            self.filteredChats = sortedChats.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        } else {
            self.filteredChats = sortedChats
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.updateCardHeightIfNeeded()
        }
    }
    
    // MARK: - Dynamic Height Logic (From PatientListVC)
    private func updateCardHeightIfNeeded() {
        guard let heightConstraint = containerHeightConstraint else { return }
        
        if filteredChats.isEmpty {
            // Optional: You can set a minimum height for empty state or 0
             heightConstraint.constant = 100 // Example placeholder height
        } else {
            // 1. Calculate content height: Rows * 80 + Padding (20)
            let totalNeeded = CGFloat(filteredChats.count) * rowHeight + 20
            
            // 2. Calculate max available space
            // Start Y position roughly below search bar. If frame not set yet, guess ~130.
            let topOfCard = searchBar.frame.maxY > 0 ? searchBar.frame.maxY + 20 : 130
            
            // Available space = Screen Height - Top Offset - TabBar Space - Safe Area
            let maxAvailable = view.bounds.height - topOfCard - reservedTabBarHeight - view.safeAreaInsets.bottom
            
            // 3. Set Height: Use the smaller of the two (Content vs Max)
            heightConstraint.constant = min(totalNeeded, maxAvailable)
            
            // 4. Enable scroll only if content is taller than the card
            tableView.isScrollEnabled = totalNeeded > maxAvailable
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private func formatMessageDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "dd/MM/yy"
        }
        return formatter.string(from: date)
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(containerView)
        containerView.addSubview(tableView)
        
        [titleLabel, searchBar, containerView, tableView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        let safe = view.safeAreaLayoutGuide
        
        // 1. Initialize Height Constraint (Set to 0 initially)
        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)
        containerHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 0),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            
            containerView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            // REMOVED: bottomAnchor constraint. We now control size strictly via height.
            
            tableView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
    }

    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatCell.self, forCellReuseIdentifier: ChatCell.identifier)
        tableView.rowHeight = rowHeight
        // Start with scroll disabled until we have enough content
        tableView.isScrollEnabled = false
        tableView.tableFooterView = UIView()
    }

    // MARK: - TableView Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return filteredChats.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatCell.identifier, for: indexPath) as! ChatCell
        let chat = filteredChats[indexPath.row]
        cell.configure(with: chat)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = filteredChats[indexPath.row]
        let detailVC = ChatDetailViewController()
        detailVC.chatName = chat.name
        detailVC.currentUserId = self.currentOtID
        detailVC.otherUserId = chat.id.uuidString
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Search
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateFilteredChats()
    }
    
    private func setupBackground() {
        gradientView = GradientView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientView)
        view.sendSubviewToBack(gradientView)
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
