import UIKit
import Supabase

class AssignmentListViewController: UIViewController {
    private var isManualUpdate = false
    var patientID: String? // Set this from ProfileViewController
    var assignments: [Assignment] = [] {
        didSet {
            if !isManualUpdate{
                updateUIForDataState()
                updateCardHeightIfNeeded()
            }
        }
    }

    // UI ELEMENTS
    private let emptyCenterPlusButton: UIButton = {
        let b = UIButton(type: .system)
        let conf = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        b.setImage(UIImage(systemName: "plus", withConfiguration: conf), for: .normal)
        b.tintColor = .white
        b.backgroundColor = UIColor(red: 0.11, green: 0.45, blue: 0.98, alpha: 1.0)
        b.layer.cornerRadius = 36
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let emptyCenterLabel: UILabel = {
        let l = UILabel()
        l.text = "Add new Assignment"
        l.textColor = .white
        l.font = .systemFont(ofSize: 16)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let cardShadowContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.shadowOpacity = 0.12
        v.layer.shadowRadius = 12
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.layer.cornerRadius = 20
        tv.backgroundColor = .systemBackground
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private var cardHeightConstraint: NSLayoutConstraint?
    private let rowHeight: CGFloat = 76

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupNavigationBar()
        setupUI()
        
        tableView.register(AssignmentCell.self, forCellReuseIdentifier: AssignmentCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        
        emptyCenterPlusButton.addTarget(self, action: #selector(handleAddButtonTap), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchAssignments()
        self.tabBarController?.tabBar.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func fetchAssignments() {
        guard let pID = patientID else { return }
        
        Task {
            do {
                let fetched: [Assignment] = try await supabase
                    .from("assignments")
                    .select()
                    .eq("patient_id", value: pID)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.assignments = fetched
                    self.tableView.reloadData()
                }
            } catch {
                print("❌ Fetch Error: \(error)")
            }
        }
    }

    private func setupGradientBackground() {
        let gradient = GradientView() // Ensure this class exists in your project
        gradient.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradient)
        view.sendSubviewToBack(gradient)
        
        NSLayoutConstraint.activate([
            gradient.topAnchor.constraint(equalTo: view.topAnchor),
            gradient.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradient.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradient.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupNavigationBar() {
        self.title = "Assignments"
        navigationItem.largeTitleDisplayMode = .never
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 18, weight: .bold)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupUI() {
        [emptyCenterPlusButton, emptyCenterLabel, cardShadowContainer].forEach { view.addSubview($0) }
        cardShadowContainer.addSubview(tableView)

        cardHeightConstraint = cardShadowContainer.heightAnchor.constraint(equalToConstant: 0)
        cardHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            emptyCenterPlusButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyCenterPlusButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyCenterPlusButton.widthAnchor.constraint(equalToConstant: 72),
            emptyCenterPlusButton.heightAnchor.constraint(equalToConstant: 72),

            emptyCenterLabel.topAnchor.constraint(equalTo: emptyCenterPlusButton.bottomAnchor, constant: 12),
            emptyCenterLabel.centerXAnchor.constraint(equalTo: emptyCenterPlusButton.centerXAnchor),

            cardShadowContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cardShadowContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardShadowContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: cardShadowContainer.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: cardShadowContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: cardShadowContainer.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: cardShadowContainer.bottomAnchor)
        ])
    }

    private func updateUIForDataState() {
        let hasData = !assignments.isEmpty
        emptyCenterPlusButton.isHidden = hasData
        emptyCenterLabel.isHidden = hasData
        cardShadowContainer.isHidden = !hasData
        
        if hasData {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddButtonTap))
            tableView.reloadData()
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    private func updateCardHeightIfNeeded() {
        guard let constraint = cardHeightConstraint else { return }
        let finalH = assignments.isEmpty ? 0 : CGFloat(assignments.count) * rowHeight
        UIView.animate(withDuration: 0.2) {
            constraint.constant = min(finalH, self.view.frame.height * 0.7)
            self.view.layoutIfNeeded()
        }
    }

    @objc private func handleAddButtonTap() {
        let newVC = NewAssignmentViewController()
        newVC.delegate = self
        newVC.patientID = self.patientID // CRITICAL: Pass the ID here
        let nav = UINavigationController(rootViewController: newVC)
        present(nav, animated: true)
    }
}

extension AssignmentListViewController: UITableViewDataSource, UITableViewDelegate, NewAssignmentDelegate {
    func didCreateAssignment(){
        // Re-fetch to get the object with the DB-generated ID
        fetchAssignments()
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            let assignmentToDelete = self.assignments[indexPath.row]
            
            Task {
                do {
                    // STEP 1: Delete Attachments from Storage
                    // We need to extract just the filename (e.g., "uuid_image.jpg") from the full URL
                    let filePaths = assignmentToDelete.attachmentUrls.compactMap { urlString -> String? in
                        guard let url = URL(string: urlString) else { return nil }
                        return url.lastPathComponent
                    }
                    
                    if !filePaths.isEmpty {
                        // We use 'try?' so that if the file is already gone, it doesn't stop the DB deletion
                        try? await supabase.storage
                            .from("assignment-attachments")
                            .remove(paths: filePaths)
                    }
                    
                    // STEP 2: Delete from Database
                    try await supabase
                        .from("assignments")
                        .delete()
                        .eq("id", value: assignmentToDelete.id)
                        .execute()
                    
                    await MainActor.run {
                        // STEP 3: Update UI
                        self.isManualUpdate = true
                        
                        self.assignments.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        
                        self.isManualUpdate = false
                        
                        if self.assignments.isEmpty {
                            self.updateUIForDataState()
                        }
                        self.updateCardHeightIfNeeded()
                        
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        completionHandler(true)
                    }
                } catch {
                    print("❌ Delete Error: \(error)")
                    await MainActor.run {
                        self.showErrorAlert()
                        completionHandler(false)
                    }
                }
            }
        }
        
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    private func showErrorAlert() {
            let alert = UIAlertController(title: "Delete Failed", message: "Could not remove assignment. Please check your connection.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assignments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AssignmentCell.reuseId, for: indexPath) as! AssignmentCell
        cell.configure(with: assignments[indexPath.row])
        cell.showDivider(indexPath.row != assignments.count - 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detailVC = AssignmentViewController()
        detailVC.assignment = assignments[indexPath.row]
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
