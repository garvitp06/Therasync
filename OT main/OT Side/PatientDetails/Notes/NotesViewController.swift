import UIKit
import Supabase

struct Note: Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var dateCreated: String
    var patient_id: String

    enum CodingKeys: String, CodingKey {
        case id, title, content
        case dateCreated = "created_at"
        case patient_id
    }

    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.id == rhs.id
    }
}

class NotesViewController: UIViewController {

    var notes: [Note] = []
    var patientID: String?
    
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        tv.separatorStyle = .none
        tv.register(NoteCell.self, forCellReuseIdentifier: NoteCell.identifier)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Add your first note"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .gray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var firstAddButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Note", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleAddNote), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        title = "Notes"
        if let navBar = navigationController?.navigationBar {
            if #available(iOS 13.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
                navBar.standardAppearance = appearance
                navBar.scrollEdgeAppearance = appearance
            } else {
                navBar.titleTextAttributes = [.foregroundColor: UIColor.black]
            }
        }
        setupNavBar()
        setupLoadingIndicator()
        setupTableView()
        setupEmptyStateView()
        updateUIState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchNotes()
    }
    
    private func setupNavBar() {
        let backBtn = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(handleBack))
        navigationItem.leftBarButtonItem = backBtn
        
    }
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemBlue
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    private func setupEmptyStateView() {
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyLabel)
        emptyStateView.addSubview(firstAddButton)

        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            emptyLabel.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),

            firstAddButton.topAnchor.constraint(equalTo: emptyLabel.bottomAnchor, constant: 20),
            firstAddButton.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            firstAddButton.widthAnchor.constraint(equalToConstant: 120),
            firstAddButton.heightAnchor.constraint(equalToConstant: 44),
            firstAddButton.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    private func fetchNotes() {
        guard let pID = patientID else { return }
        
        // 1. Start UI state
        loadingIndicator.startAnimating()
        tableView.isHidden = true
        emptyStateView.isHidden = true
        
        Task {
            do {
                let fetched: [Note] = try await supabase
                    .from("notes")
                    .select()
                    .eq("patient_id", value: pID)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                await MainActor.run {
                    // 2. Data arrived, update local array
                    self.notes = fetched
                    self.tableView.reloadData()
                    
                    // 3. STOP indicator and update visibility
                    self.loadingIndicator.stopAnimating()
                    self.updateUIState()
                }
            } catch {
                print("Error fetching notes: \(error)")
                await MainActor.run {
                    // 4. STOP indicator even if it fails
                    self.loadingIndicator.stopAnimating()
                    self.showToast(message: "Failed to load notes.")
                    self.updateUIState() // This will show the empty state if fetch failed
                }
            }
        }
    }
    
    private func updateUIState() {
        let isEmpty = notes.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        
        if isEmpty {
            navigationItem.rightBarButtonItem = nil
        } else {
            let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddNote))
            navigationItem.rightBarButtonItem = addBtn
        }
    }
    
    @objc func handleAddNote() {
        let now = Date()
        
        // ISO string for Supabase storage
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fullDateISO = isoFormatter.string(from: now)
        
        // Title for the TableView Cell (IST)
        let titleFormatter = DateFormatter()
        titleFormatter.timeZone = TimeZone(secondsFromGMT: 19800)
        titleFormatter.dateFormat = "d MMMM yyyy"
        let titleOnlyDate = titleFormatter.string(from: now)
        
        guard let pID = patientID else { return }

        let newNote = Note(title: titleOnlyDate,
                           content: "",
                           dateCreated: fullDateISO,
                           patient_id: pID)
        
        notes.insert(newNote, at: 0)
        tableView.reloadData()
        updateUIState()
        navigateToDetail(for: newNote)
    }
    
    private func navigateToDetail(for note: Note) {
        let detailVC = NoteDetailViewController()
        detailVC.noteID = note.id
        detailVC.patientID = self.patientID
        detailVC.fullDateString = note.dateCreated
        detailVC.delegate = self
        detailVC.loadViewIfNeeded()
        detailVC.titleTextField.text = note.title
        
        if note.content.isEmpty {
            detailVC.textView.text = "Start typing your note..."
            detailVC.textView.textColor = .lightGray
        } else {
            detailVC.textView.text = note.content
            detailVC.textView.textColor = .label
        }
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    @objc func handleBack() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - TableView Delegate & DataSource
extension NotesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let noteToDelete = notes[indexPath.row]
            
            // Show loading or disable interaction if needed
            Task {
                do {
                    // 1. Delete from Supabase first
                    try await supabase
                        .from("notes")
                        .delete()
                        .eq("id", value: noteToDelete.id)
                        .execute()
                    
                    await MainActor.run {
                        // 2. Remove from local array
                        self.notes.remove(at: indexPath.row)
                        
                        // 3. Update TableView with animation
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        
                        // 4. Update Empty State if needed
                        self.updateUIState()
                        
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                } catch {
                    print("❌ Error deleting note: \(error)")
                    await MainActor.run {
                        self.showToast(message: "Failed to delete note. Try again.")
                    }
                }
            }
        }
    }
    private func showToast(message: String) {
        let toastContainer = UIView()
        toastContainer.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastContainer.layer.cornerRadius = 20
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.textColor = .white
        label.text = message
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        toastContainer.addSubview(label)
        view.addSubview(toastContainer)
        
        NSLayoutConstraint.activate([
            toastContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            toastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastContainer.heightAnchor.constraint(equalToConstant: 40),
            label.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -20),
            label.centerYAnchor.constraint(equalTo: toastContainer.centerYAnchor)
        ])
        
        toastContainer.alpha = 0
        UIView.animate(withDuration: 0.5, animations: { toastContainer.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.5, delay: 2.0, animations: { toastContainer.alpha = 0 }) { _ in
                toastContainer.removeFromSuperview()
            }
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoteCell.identifier, for: indexPath) as? NoteCell else {
            return UITableViewCell()
        }
        // Configure using the Note's title
        cell.configure(date: notes[indexPath.row].title)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigateToDetail(for: notes[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    // Context Menu
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.notes.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.updateUIState()
            }
            return UIMenu(title: "", children: [deleteAction])
        }
    }
}
// MARK: - NoteDetailDelegate Implementation
extension NotesViewController: NoteDetailDelegate {
    func didUpdateNote(id: UUID, newTitle: String, newBody: String) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].title = newTitle
            notes[index].content = newBody
            
            // Refresh the specific row so the new title appears in the list
            let indexPath = IndexPath(row: index, section: 0)
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}
