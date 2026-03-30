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
class ChatListViewController: UIViewController {

    // MARK: - UI Components
    private let db = Firestore.firestore()
    private var chatListeners: [ListenerRegistration] = []
    
    private let rowHeight: CGFloat = 80
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.backgroundView = GradientView()
        tv.rowHeight = 80
        tv.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0)
        return tv
    }()

    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: - State
    private var chatSummariesMap: [UUID: ChatSummary] = [:]
    private var sortedChats: [ChatSummary] = []
    private var filteredChats: [ChatSummary] = []
    private var currentOtID: String?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        setupNavigationBar()
        setupSearchController()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        
        fetchPatientsAndListenForUpdates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        chatListeners.forEach { $0.remove() }
        chatListeners.removeAll()
    }
    
    // MARK: - Layout Setup
    private func setupNavigationBar() {
        self.title = "Chat"
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Chats"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatCell.self, forCellReuseIdentifier: ChatCell.identifier)
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
        
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            self.filteredChats = sortedChats.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        } else {
            self.filteredChats = sortedChats
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
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
}

// MARK: - TableView Extensions
extension ChatListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 
        return filteredChats.count 
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatCell.identifier, for: indexPath) as! ChatCell
        let chat = filteredChats[indexPath.row]
        cell.configure(with: chat)
        cell.backgroundColor = .secondarySystemGroupedBackground
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
}

// MARK: - Search Extension
extension ChatListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        updateFilteredChats()
    }
}
