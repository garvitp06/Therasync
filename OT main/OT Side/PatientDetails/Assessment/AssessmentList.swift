import UIKit

final class AssessmentList: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var assessmentsToDisplay: [String] = []
    var patientID: String?
    
    // We remove the strictly local logic and rely on the Manager for state
    private var visitedAssessments: Set<String> = []

    // MARK: - UI Components
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private let endButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("End Assessment", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 25
        button.layer.masksToBounds = true
        button.isHidden = true
        button.alpha = 0
        return button
    }()
    
    private var cardHeightConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Selected Assessments"
        setupViews()
        setupConstraints()
        
        // 1. LOAD PREVIOUS PROGRESS for this Patient
        if let pid = patientID {
            visitedAssessments = AssessmentSessionManager.shared.getVisitedAssessments(for: pid)
            
            // Check if we need to show the End Button immediately
            if !assessmentsToDisplay.isEmpty && visitedAssessments.count >= assessmentsToDisplay.count {
                endButton.isHidden = false
                endButton.alpha = 1.0
                
                // If it was already submitted, maybe disable interaction?
                if AssessmentSessionManager.shared.isSubmitted(for: pid) {
                    endButton.setTitle("Assessment Submitted", for: .normal)
                    endButton.backgroundColor = .systemGray
                    endButton.isEnabled = false
                }
            }
        }
        
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        
        // Listen for assessment completion notifications
        NotificationCenter.default.addObserver(self, selector: #selector(assessmentDidComplete(_:)), name: NSNotification.Name("AssessmentDidComplete"), object: nil)
    }
    
    deinit {
        tableView.removeObserver(self, forKeyPath: "contentSize")
        NotificationCenter.default.removeObserver(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            let height = tableView.contentSize.height
            let maxHeight = view.safeAreaLayoutGuide.layoutFrame.height - 120
            let finalHeight = min(height, maxHeight)
            cardHeightConstraint?.constant = finalHeight
            tableView.isScrollEnabled = height > maxHeight
        }
    }

    // MARK: - Setup
    private func setupViews() {
        view.addSubview(cardView)
        cardView.addSubview(tableView)
        view.addSubview(endButton)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.backgroundColor = .systemBackground
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        endButton.addTarget(self, action: #selector(didTapEndAssessment), for: .touchUpInside)
    }

    private func setupConstraints() {
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            endButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            endButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            endButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -20),
            endButton.heightAnchor.constraint(equalToConstant: 50),
            
            cardView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: cardView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
        ])
        
        cardHeightConstraint = cardView.heightAnchor.constraint(equalToConstant: 50)
        cardHeightConstraint?.isActive = true
    }
    
    // MARK: - Table Logic
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assessmentsToDisplay.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        var config = cell.defaultContentConfiguration()
        let name = assessmentsToDisplay[indexPath.row]
        config.text = name
        
        // Check local state (which mirrors Manager state)
        if visitedAssessments.contains(name) {
            config.textProperties.color = .secondaryLabel
            config.image = UIImage(systemName: "checkmark.circle.fill")
            config.imageProperties.tintColor = .systemGreen
            cell.accessoryType = .none
        } else {
            config.textProperties.color = .label
            config.image = UIImage(systemName: "circle")
            config.imageProperties.tintColor = .systemBlue
            cell.accessoryType = .disclosureIndicator
        }
        
        cell.contentConfiguration = config
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let name = assessmentsToDisplay[indexPath.row]

        // Navigation
        var vc: UIViewController?
        
        switch name {
        case "ADOS":
            let a = ADOSAssessmentViewController()
            a.patientID = self.patientID
            vc = a
        case "Birth History":
            let a = BirthHistoryViewController()
            a.patientID = self.patientID
            vc = a
        case "Sensory Profile":
            let a = SensoryProfileViewController()
            a.patientID = self.patientID
            vc = a
        case "School Complaints":
            let a = SchoolComplaintsViewController()
            a.patientID = self.patientID
            vc = a
        case "Medical History":
            let a = MedicalHistoryViewController()
            a.patientID = self.patientID
            vc = a
        case "Cognitive Skills":
            let a = CognitiveSkillsViewController()
            a.patientID = self.patientID
            vc = a
        case "Gross Motor Skills":
            let a = GrossMotorSkillsViewController()
            a.patientID = self.patientID
            vc = a
        case "Fine Motor Skills":
            let a = FineMotorSkillsViewController()
            a.patientID = self.patientID
            vc = a
        case "Language & Communication", "Social Milestones", "Self-Care Milestones":
            let a = DevelopmentalHistoryViewController()
            a.patientID = self.patientID
            a.subSection = name
            vc = a
        case "Feeding", "Dressing", "Bathing & Hygiene", "Toileting", "Sleep":
            let a = DailyLivingViewController()
            a.patientID = self.patientID
            a.subSection = name
            vc = a
        case "Family History", "Social & Environmental":
            let a = FamilyEnvironmentViewController()
            a.patientID = self.patientID
            a.subSection = name
            vc = a
        default:
            break
        }
        
        if let vc = vc {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // Called when any assessment VC posts its completion notification
    @objc private func assessmentDidComplete(_ notification: Notification) {
        guard let completedName = notification.userInfo?["assessmentName"] as? String else { return }
        
        if let pid = patientID {
            AssessmentSessionManager.shared.markAssessmentVisited(for: pid, assessmentName: completedName)
        }
        visitedAssessments.insert(completedName)
        tableView.reloadData()
        
        // Check if all done
        if visitedAssessments.count == assessmentsToDisplay.count {
            endButton.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.endButton.alpha = 1.0
            }
        }
    }
    
    @objc private func didTapEndAssessment() {
        // 3. MARK SUBMITTED IN MANAGER
        if let pid = patientID {
            AssessmentSessionManager.shared.markAsSubmitted(for: pid)
        }
        navigationController?.popToRootViewController(animated: true)
    }
}
