import UIKit
import Supabase

/// Displays a comparison of assessment answers across sessions,
/// showing improvement, regression, or unchanged status per question.
final class AssessmentProgressViewController: UIViewController {

    // MARK: - Input
    var patient: Patient?

    // MARK: - Data Model
    fileprivate struct ProgressSection {
        let assessmentType: String
        let items: [ProgressItem]
        let summaryText: String
        var isExpanded: Bool = false
    }

    fileprivate struct ProgressItem {
        let question: String
        let previousAnswer: String
        let currentAnswer: String
        let status: ChangeStatus
    }

    fileprivate enum ChangeStatus {
        case improved
        case regressed
        case unchanged
        case updated   // For text-based: value changed but we can't judge direction

        var color: UIColor {
            switch self {
            case .improved:  return .systemGreen
            case .regressed: return .systemRed
            case .unchanged: return .systemGray
            case .updated:   return .systemOrange
            }
        }

        var icon: String {
            switch self {
            case .improved:  return "arrow.up.circle.fill"
            case .regressed: return "arrow.down.circle.fill"
            case .unchanged: return "equal.circle.fill"
            case .updated:   return "pencil.circle.fill"
            }
        }

        var label: String {
            switch self {
            case .improved:  return "Improved"
            case .regressed: return "Regressed"
            case .unchanged: return "Unchanged"
            case .updated:   return "Updated"
            }
        }
    }

    private var sections: [ProgressSection] = []

    // Assessment types that use radio-based Questions with ordinal options
    private let radioBasedTypes: Set<String> = [
        "Gross Motor Skills", "Fine Motor Skills", "Cognitive Skills", "ADOS"
    ]

    // MARK: - UI
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        return tv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "At least two assessment sessions are needed\nto show progress."
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.numberOfLines = 0
        l.textAlignment = .center
        l.textColor = .white.withAlphaComponent(0.85)
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.color = .white
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Lifecycle
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Assessment Progress"
        setupNavBar()
        setupUI()
        fetchAndCompare()
    }

    private func setupNavBar() {
        navigationItem.largeTitleDisplayMode = .never
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(spinner)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProgressHeaderCell.self, forCellReuseIdentifier: ProgressHeaderCell.reuseID)
        tableView.register(ProgressItemCell.self, forCellReuseIdentifier: ProgressItemCell.reuseID)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safe.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Fetch & Compare
    private func fetchAndCompare() {
        guard let pID = patient?.patientID else { return }

        spinner.startAnimating()
        tableView.isHidden = true

        Task {
            do {
                // Fetch all assessments using the existing AssessmentLogResponse model
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let records: [AssessmentLogResponse] = try await supabase
                    .from("assessments")
                    .select("id, assessment_type, assessment_data, created_at")
                    .eq("patient_id", value: pID)
                    .order("created_at", ascending: true)
                    .execute()
                    .value

                // Convert each record's assessment_data to [String: String] for comparison
                struct FlatAssessment {
                    let id: Int
                    let assessment_type: String
                    let data: [String: String]
                }

                let flatRecords: [FlatAssessment] = records.map { record in
                    var flat: [String: String] = [:]
                    if let dict = record.assessment_data.value as? [String: Any] {
                        for (key, val) in dict {
                            flat[key] = "\(val)"
                        }
                    }
                    return FlatAssessment(id: record.id, assessment_type: record.assessment_type, data: flat)
                }

                // Group by assessment_type
                var grouped: [String: [FlatAssessment]] = [:]
                for r in flatRecords {
                    grouped[r.assessment_type, default: []].append(r)
                }

                // Build comparison sections for types with ≥ 2 records
                var builtSections: [ProgressSection] = []

                for (type, assessments) in grouped.sorted(by: { $0.key < $1.key }) {
                    guard assessments.count >= 2 else { continue }

                    let previous = assessments[assessments.count - 2]
                    let current = assessments[assessments.count - 1]

                    let isRadioBased = radioBasedTypes.contains(type)
                    var items: [ProgressItem] = []

                    // Merge all keys from both assessments
                    let allKeys = Set(previous.data.keys).union(current.data.keys)
                    let sortedKeys = allKeys.sorted()

                    for key in sortedKeys {
                        let prevAnswer = previous.data[key] ?? "—"
                        let currAnswer = current.data[key] ?? "—"

                        let status: ChangeStatus
                        if prevAnswer == currAnswer {
                            status = .unchanged
                        } else if isRadioBased {
                            status = evaluateRadioChange(question: key, previous: prevAnswer, current: currAnswer, type: type)
                        } else {
                            status = .updated
                        }

                        items.append(ProgressItem(
                            question: key,
                            previousAnswer: prevAnswer,
                            currentAnswer: currAnswer,
                            status: status
                        ))
                    }

                    // Build summary
                    let improved = items.filter { $0.status == .improved }.count
                    let regressed = items.filter { $0.status == .regressed }.count
                    let unchanged = items.filter { $0.status == .unchanged }.count
                    let updated = items.filter { $0.status == .updated }.count

                    var summaryParts: [String] = []
                    if improved > 0 { summaryParts.append("\(improved) Improved") }
                    if regressed > 0 { summaryParts.append("\(regressed) Regressed") }
                    if unchanged > 0 { summaryParts.append("\(unchanged) Unchanged") }
                    if updated > 0 { summaryParts.append("\(updated) Updated") }
                    let summary = summaryParts.joined(separator: "  ·  ")

                    builtSections.append(ProgressSection(
                        assessmentType: type,
                        items: items,
                        summaryText: summary
                    ))
                }

                await MainActor.run {
                    self.spinner.stopAnimating()
                    self.sections = builtSections

                    if builtSections.isEmpty {
                        self.emptyLabel.isHidden = false
                        self.tableView.isHidden = true
                    } else {
                        self.emptyLabel.isHidden = true
                        self.tableView.isHidden = false
                        self.tableView.reloadData()
                    }
                }
            } catch {
                print("AssessmentProgress fetch error: \(error)")
                await MainActor.run {
                    self.spinner.stopAnimating()
                    self.emptyLabel.text = "Failed to load progress data."
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }

    // MARK: - Radio Change Evaluation
    /// For radio-based assessments, determines if the answer change is improvement or regression.
    /// Options lists are typically ordered: best → worst (e.g. "On time", "Delayed", "Not achieved", "Unsure")
    /// Lower index = better outcome for most questions.
    private func evaluateRadioChange(question: String, previous: String, current: String, type: String) -> ChangeStatus {
        // Get the original options list for this question to determine order
        let options = getOptionsForQuestion(question: question, type: type)

        guard let prevIdx = options.firstIndex(of: previous),
              let currIdx = options.firstIndex(of: current) else {
            // If we can't find the options, treat as "updated"
            return .updated
        }

        // Lower index = better (e.g. "On time" = 0, "Not achieved" = 2)
        if currIdx < prevIdx {
            return .improved
        } else {
            return .regressed
        }
    }

    /// Returns the original options list for a given question + assessment type.
    private func getOptionsForQuestion(question: String, type: String) -> [String] {
        switch type {
        case "Gross Motor Skills":
            let vc = GrossMotorSkillsViewController()
            if let q = vc.questions.first(where: { "Q\($0.id)" == question }) {
                return q.options
            }
        case "Fine Motor Skills":
            let vc = FineMotorSkillsViewController()
            if let q = vc.questions.first(where: { "Q\($0.id)" == question }) {
                return q.options
            }
        case "Cognitive Skills":
            let vc = CognitiveSkillsViewController()
            if let q = vc.questions.first(where: { "Q\($0.id)" == question }) {
                return q.options
            }
        case "ADOS":
            // ADOS uses ADOSData — return default 4-option scale
            return ["None", "Mild", "Moderate", "Severe"]
        default:
            break
        }
        return []
    }
}

// MARK: - Table DataSource & Delegate
extension AssessmentProgressViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].isExpanded ? sections[section].items.count + 1 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: ProgressHeaderCell.reuseID, for: indexPath) as! ProgressHeaderCell
            cell.configure(with: sections[indexPath.section])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: ProgressItemCell.reuseID, for: indexPath) as! ProgressItemCell
            let item = sections[indexPath.section].items[indexPath.row - 1]
            cell.configure(with: item)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            sections[indexPath.section].isExpanded.toggle()
            
            let itemCount = sections[indexPath.section].items.count
            var paths: [IndexPath] = []
            if itemCount > 0 {
                for i in 1...itemCount {
                    paths.append(IndexPath(row: i, section: indexPath.section))
                }
            }
            
            tableView.beginUpdates()
            if sections[indexPath.section].isExpanded {
                tableView.insertRows(at: paths, with: .fade)
            } else {
                tableView.deleteRows(at: paths, with: .fade)
            }
            // Update the chevron icon state instantly
            if let cell = tableView.cellForRow(at: indexPath) as? ProgressHeaderCell {
                cell.configure(with: sections[indexPath.section])
            }
            tableView.endUpdates()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8 // Tighten the gap above the container
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8 // Tighten the gap below the container
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

// MARK: - Custom Cells
private class ProgressHeaderCell: UITableViewCell {
    static let reuseID = "ProgressHeaderCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let summaryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let chevron: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        setupCell()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupCell() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(summaryLabel)
        contentView.addSubview(chevron)

        NSLayoutConstraint.activate([
            chevron.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevron.widthAnchor.constraint(equalToConstant: 16),
            chevron.heightAnchor.constraint(equalToConstant: 16),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -12),

            summaryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            summaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            summaryLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -12),
            summaryLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),
        ])
    }

    func configure(with section: AssessmentProgressViewController.ProgressSection) {
        titleLabel.text = section.assessmentType
        
        if section.summaryText.isEmpty {
            summaryLabel.isHidden = true
        } else {
            summaryLabel.isHidden = false
            summaryLabel.text = section.summaryText
        }
        
        let iconName = section.isExpanded ? "chevron.down" : "chevron.right"
        chevron.image = UIImage(systemName: iconName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
    }
}

private class ProgressItemCell: UITableViewCell {
    static let reuseID = "ProgressItemCell"

    private let questionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let badgeView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dividerView: UIView = {
        let v = UIView()
        v.backgroundColor = .separator.withAlphaComponent(0.3)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let previousTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "PREVIOUS"
        l.font = .systemFont(ofSize: 11, weight: .bold)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let previousLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let currentTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "LATEST"
        l.font = .systemFont(ofSize: 11, weight: .bold)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let currentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .label
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupCell()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupCell() {
        contentView.addSubview(questionLabel)
        contentView.addSubview(badgeView)
        badgeView.addSubview(statusLabel)
        
        contentView.addSubview(dividerView)
        
        contentView.addSubview(previousTitleLabel)
        contentView.addSubview(previousLabel)
        
        contentView.addSubview(currentTitleLabel)
        contentView.addSubview(currentLabel)

        // Prevent badge from compressing by setting a high hugging priority
        badgeView.setContentHuggingPriority(.required, for: .horizontal)
        badgeView.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            questionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            questionLabel.trailingAnchor.constraint(lessThanOrEqualTo: badgeView.leadingAnchor, constant: -12),
            
            badgeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            badgeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            statusLabel.topAnchor.constraint(equalTo: badgeView.topAnchor, constant: 4),
            statusLabel.bottomAnchor.constraint(equalTo: badgeView.bottomAnchor, constant: -4),
            statusLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -8),
            
            dividerView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 12),
            dividerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dividerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            
            previousTitleLabel.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 12),
            previousTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            previousTitleLabel.widthAnchor.constraint(equalToConstant: 70),
            
            previousLabel.topAnchor.constraint(equalTo: previousTitleLabel.topAnchor),
            previousLabel.leadingAnchor.constraint(equalTo: previousTitleLabel.trailingAnchor, constant: 8),
            previousLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            currentTitleLabel.topAnchor.constraint(equalTo: previousLabel.bottomAnchor, constant: 12),
            currentTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            currentTitleLabel.widthAnchor.constraint(equalToConstant: 70),
            
            currentLabel.topAnchor.constraint(equalTo: currentTitleLabel.topAnchor),
            currentLabel.leadingAnchor.constraint(equalTo: currentTitleLabel.trailingAnchor, constant: 8),
            currentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            currentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    func configure(with item: AssessmentProgressViewController.ProgressItem) {
        questionLabel.text = item.question
        
        previousLabel.text = item.previousAnswer.isEmpty ? "—" : item.previousAnswer
        currentLabel.text = item.currentAnswer.isEmpty ? "—" : item.currentAnswer
        
        statusLabel.text = item.status.label.uppercased()
        badgeView.backgroundColor = item.status.color.withAlphaComponent(0.15)
        statusLabel.textColor = item.status.color
    }
}
