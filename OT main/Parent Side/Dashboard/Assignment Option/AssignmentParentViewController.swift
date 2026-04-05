import UIKit
import Supabase
import Storage

// 1. Helper Struct
struct AssignmentWithStatus: Codable {
    let id: UUID
    let title: String
    let instruction: String
    let type: String
    let dueDate: Date
    let quiz_questions: [String]?
    let attachment_urls: [String]?
    let assignment_submissions: [SubmissionScoreCheck]?
    
    var submission: SubmissionScoreCheck? {
            return assignment_submissions?.first
        }
    var isSubmitted: Bool {
        guard let submissions = assignment_submissions else { return false }
        return !submissions.isEmpty
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, instruction, type
        case dueDate = "due_date"
        case quiz_questions, attachment_urls, assignment_submissions
    }
}

struct SubmissionIdCheck: Codable {
    let id: UUID
}

struct SubmissionScoreCheck: Codable {
    let id: UUID
    let score: Int? // Fetch score now
}

class AssignmentParentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    var patientID: String?
    private var assignmentsWithStatus: [AssignmentWithStatus] = []
    
    // MARK: - UI Components
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = .gray
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let noAssignmentsLabel: UILabel = {
        let label = UILabel()
        label.text = "No assignments added yet."
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[DEBUG] View Did Load")
        setupUI()
        setupNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("[DEBUG] View Will Appear")
        fetchAssignments()
    }
    
    // MARK: - Data Fetching
    private func fetchAssignments() {
            guard let pID = patientID else { return }
            loadingIndicator.startAnimating()
            
            Task {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    // CRITICAL CHANGE: Request 'score' inside assignment_submissions
                    let response = try await supabase
                        .from("assignments")
                        .select("*, assignment_submissions(id, score)")
                        .eq("patient_id", value: pID)
                        .order("due_date", ascending: true)
                        .execute()
                    
                    let fetchedData = try decoder.decode([AssignmentWithStatus].self, from: response.data)
                    
                    await MainActor.run {
                        self.assignmentsWithStatus = fetchedData
                        self.loadingIndicator.stopAnimating()
                        self.noAssignmentsLabel.isHidden = !fetchedData.isEmpty
                        self.tableView.isHidden = fetchedData.isEmpty
                        self.tableView.reloadData()
                    }
                } catch {
                    print("❌ Fetch Error: \(error)")
                    await MainActor.run { self.loadingIndicator.stopAnimating() }
                }
            }
        }
    
    // MARK: - Navigation Bar
    private func setupNavBar() {
        self.title = "Assignments"
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        let isDark = traitCollection.userInterfaceStyle == .dark
        let color: UIColor = isDark ? .white : .black
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: color]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = color
        
        let backBtn = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(handleBack))
        navigationItem.leftBarButtonItem = backBtn
    }
    
    @objc func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - UI Layout
    private func setupUI() {
        let bg = ParentGradientView()
        bg.frame = view.bounds
        view.addSubview(bg)
        view.sendSubviewToBack(bg)
        
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        view.addSubview(noAssignmentsLabel)
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            noAssignmentsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noAssignmentsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - TableView Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return assignmentsWithStatus.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let item = assignmentsWithStatus[indexPath.section]
            
            var config = cell.defaultContentConfiguration()
            config.text = item.title
            config.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
            
            // Logic to show Due Date OR Score
            if let sub = item.submission {
                if let score = sub.score {
                    // Graded
                    config.secondaryText = "Score: \(score)/10"
                    config.secondaryTextProperties.color = .systemGreen
                    config.secondaryTextProperties.font = .systemFont(ofSize: 14, weight: .bold)
                    
                    let icon = UIImageView(image: UIImage(systemName: "star.fill"))
                    icon.tintColor = .systemYellow
                    cell.accessoryView = icon
                } else {
                    // Submitted, pending grade
                    config.secondaryText = "Submitted (Pending Grade)"
                    config.secondaryTextProperties.color = .systemOrange
                    
                    let icon = UIImageView(image: UIImage(systemName: "clock.fill"))
                    icon.tintColor = .systemOrange
                    cell.accessoryView = icon
                }
            } else {
                // Not submitted
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                config.secondaryText = "Due: \(formatter.string(from: item.dueDate))"
                config.secondaryTextProperties.color = .gray
                
                let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
                arrow.tintColor = .lightGray
                cell.accessoryView = arrow
            }
            
            cell.contentConfiguration = config
            cell.backgroundColor = .systemBackground
            cell.layer.cornerRadius = 10
            cell.clipsToBounds = true
            return cell
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("[DEBUG] Tapped Row: \(indexPath.section)")
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selected = assignmentsWithStatus[indexPath.section]
        let detailVC = AssignmentDetailViewController()
        
        detailVC.assignmentTitle = selected.title
        
        let assignmentModel = Assignment(
            id: selected.id,
            title: selected.title,
            instruction: selected.instruction,
            dueDate: selected.dueDate,
            type: selected.type,
            quizQuestions: selected.quiz_questions ?? [],
            attachmentUrls: selected.attachment_urls ?? [],
            patient_id: self.patientID,
            videoUrl: nil
        )
        
        detailVC.currentAssignment = assignmentModel
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
