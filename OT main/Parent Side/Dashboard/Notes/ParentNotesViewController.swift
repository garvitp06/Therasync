import UIKit
import Supabase

class ParentNotesViewController: UIViewController {
    var notes: [Note] = []
    var patientID: String?
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .systemGroupedBackground
        tv.separatorStyle = .none
        tv.register(ParentNoteCell.self, forCellReuseIdentifier: ParentNoteCell.identifier)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.delegate = self
        tv.dataSource = self
        return tv
    }()
    
    private let noNotesLabel: UILabel = {
            let label = UILabel()
            label.text = "No notes added"
            label.font = .systemFont(ofSize: 20, weight: .medium)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private lazy var centerAddButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Add Your First Note", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 15
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleAddNote), for: .touchUpInside)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        fetchParentNotes()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        setupNavBar()

    }

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingIndicator) 
        
        emptyStateView.addSubview(noNotesLabel)
        emptyStateView.addSubview(centerAddButton)
        
        NSLayoutConstraint.activate([
            // TableView remains full screen
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Fix: Center the emptyStateView container itself
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: view.widthAnchor), // Match view width
            
            // Fix: Center the Label inside the container
            noNotesLabel.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            noNotesLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            
            // Fix: Center the Button inside the container
            centerAddButton.topAnchor.constraint(equalTo: noNotesLabel.bottomAnchor, constant: 20),
            centerAddButton.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            centerAddButton.widthAnchor.constraint(equalToConstant: 240),
            centerAddButton.heightAnchor.constraint(equalToConstant: 54),
            centerAddButton.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }

    private func setupNavBar() {
        title = "Notes"
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemGroupedBackground // Match your view bg
        
        // Set Title to BLACK
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        // Apply to the bar
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        // Set Button colors (Back and Add)
        navigationController?.navigationBar.tintColor = .systemBlue
        
        // Left Item: Back Button
        let backBtn = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(handleBack))
        navigationItem.leftBarButtonItem = backBtn
        
        // Right Item: Add Button (if notes exist)
        if !notes.isEmpty {
            let addBtn = UIBarButtonItem(barButtonSystemItem: .add,
                                         target: self,
                                         action: #selector(handleAddNote))
            navigationItem.rightBarButtonItem = addBtn
        }
    }
    private func fetchParentNotes() {
        guard let pID = patientID else { return }
        loadingIndicator.startAnimating()
        Task {
            do {
                let user = try await supabase.auth.session.user
                let fetched: [Note] = try await supabase.from("notes").select()
                    .eq("patient_id", value: pID).eq("parent_uid", value: user.id.uuidString)
                    .order("created_at", ascending: false).execute().value
                await MainActor.run {
                    self.notes = fetched
                    self.loadingIndicator.stopAnimating()
                    self.updateState()
                    self.tableView.reloadData()
                }
            } catch { print(error) }
        }
    }

    private func updateState() {
        let isEmpty = notes.isEmpty
        tableView.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
        setupNavBar()
    }

    @objc func handleAddNote() {
        let now = Date()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let titleFormatter = DateFormatter()
        titleFormatter.timeZone = TimeZone(secondsFromGMT: 19800) // IST
        titleFormatter.dateFormat = "d MMMM yyyy"
        
        guard let pID = patientID else { return }

        Task {
            do {
                let user = try await supabase.auth.session.user
                let newNoteID = UUID()
                
                // Create the local note object with all required fields
                let newNote = Note(
                    id: newNoteID,
                    title: titleFormatter.string(from: now),
                    content: "",
                    dateCreated: isoFormatter.string(from: now),
                    patient_id: pID
                )

                // OPTIONAL: Immediately insert into DB to prevent sync gaps
                try await supabase.from("notes").insert([
                    "id": newNoteID.uuidString,
                    "patient_id": pID,
                    "parent_uid": user.id.uuidString, // Critical for your fetch query
                    "title": newNote.title,
                    "content": ""
                ]).execute()

                await MainActor.run {
                    self.notes.insert(newNote, at: 0)
                    self.updateState()
                    self.tableView.reloadData()
                    self.navigateToDetail(for: newNote)
                }
            } catch {
                print("❌ Error adding note: \(error)")
            }
        }
    }

    private func navigateToDetail(for note: Note) {
        let detailVC = ParentNoteDetailViewController()
        detailVC.noteID = note.id
        detailVC.patientID = self.patientID
        detailVC.noteContent = note.content
        detailVC.fullDateString = note.dateCreated
        detailVC.delegate = self
        detailVC.loadViewIfNeeded()
        detailVC.titleTextField.text = note.title
        navigationController?.pushViewController(detailVC, animated: true)
    }

    @objc func handleBack() { navigationController?.popViewController(animated: true) }
}

extension ParentNotesViewController: UITableViewDelegate, UITableViewDataSource, ParentNoteDetailDelegate {
    func didUpdateParentNote(id: UUID, newTitle: String, newBody: String) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].title = newTitle
            notes[index].content = newBody
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return notes.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ParentNoteCell.identifier, for: indexPath) as! ParentNoteCell
        cell.configure(title: notes[indexPath.row].title)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { navigateToDetail(for: notes[indexPath.row]) }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 92 }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completion) in
            guard let self = self else { return }
            let note = self.notes[indexPath.row]
            Task {
                do {
                    try await supabase.from("notes").delete().eq("id", value: note.id).execute()
                    await MainActor.run {
                        self.notes.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        self.updateState()
                        completion(true)
                    }
                } catch { completion(false) }
            }
        }
        delete.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
