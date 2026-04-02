import UIKit

class AssessmentListViewController: UIViewController {

    var patientID: String?

    // MARK: - Section Data
    private struct AssessmentSection {
        let title: String
        let items: [String]
    }

    private let sections: [AssessmentSection] = [
        AssessmentSection(title: "History", items: [
            "Birth History",
            "Medical History"
        ]),
        AssessmentSection(title: "Complaints", items: [
            "Sensory Profile",
            "School Complaints"
        ]),
        AssessmentSection(title: "Skills", items: [
            "Gross Motor Skills",
            "Fine Motor Skills",
            "Cognitive Skills",
            "ADOS"
        ]),
        AssessmentSection(title: "Developmental", items: [
            "Language & Communication",
            "Social Milestones",
            "Self-Care Milestones"
        ]),
        AssessmentSection(title: "Daily Living", items: [
            "Feeding",
            "Dressing",
            "Bathing & Hygiene",
            "Toileting",
            "Sleep"
        ]),
        AssessmentSection(title: "Family & Environment", items: [
            "Family History",
            "Social & Environmental"
        ])
    ]

    // MARK: - UI Components
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        return tv
    }()

    private let beginButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Begin Assessment", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.backgroundColor = .systemBlue
        b.layer.cornerRadius = 25
        b.layer.masksToBounds = true
        return b
    }()

    // MARK: - Lifecycle
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        setupLayout()
        beginButton.addTarget(self, action: #selector(didTapBeginButton), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData() // Refresh checkmarks from session
    }

    // MARK: - Navigation Bar
    private func setupNavigationBar() {
        title = "Assessment List"
        navigationItem.largeTitleDisplayMode = .never
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    // MARK: - UI Setup
    private func setupViews() {
        view.addSubview(tableView)
        view.addSubview(beginButton)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AssessmentCell")
    }

    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: beginButton.topAnchor, constant: -10),

            beginButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            beginButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            beginButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -10),
            beginButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Actions
    @objc private func didTapBeginButton() {
        guard let pid = patientID else { return }

        let currentSelection = AssessmentSessionManager.shared.getSelectedAssessments(for: pid)

        if currentSelection.isEmpty {
            let alert = UIAlertController(title: "No Selection", message: "Please select at least one assessment.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let nextVC = AssessmentList()
        nextVC.assessmentsToDisplay = Array(currentSelection).sorted()
        nextVC.patientID = self.patientID
        navigationController?.pushViewController(nextVC, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension AssessmentListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .white
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AssessmentCell", for: indexPath)
        let itemName = sections[indexPath.section].items[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = itemName

        // Check if selected via session manager
        let isSelected: Bool = {
            guard let pid = patientID else { return false }
            return AssessmentSessionManager.shared.getSelectedAssessments(for: pid).contains(itemName)
        }()

        if isSelected {
            content.image = UIImage(systemName: "checkmark.circle.fill")
            content.imageProperties.tintColor = .systemBlue
        } else {
            content.image = UIImage(systemName: "circle")
            content.imageProperties.tintColor = .systemGray3
        }

        cell.contentConfiguration = content
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let pid = patientID else { return }

        let itemName = sections[indexPath.section].items[indexPath.row]
        var currentSelection = AssessmentSessionManager.shared.getSelectedAssessments(for: pid)

        if currentSelection.contains(itemName) {
            currentSelection.remove(itemName)
        } else {
            currentSelection.insert(itemName)
        }

        AssessmentSessionManager.shared.updateSelection(for: pid, selection: currentSelection)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
