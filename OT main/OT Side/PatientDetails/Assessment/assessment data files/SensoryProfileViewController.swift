import UIKit
import Supabase

class SensoryProfileViewController: UIViewController {

    var patientID: String?

    // MARK: - Data Model
    private struct SensorySection {
        let title: String
        let questions: [String]
    }

    private let sensoryData: [SensorySection] = [
        SensorySection(title: "Tactile (Touch)", questions: [
            "Resists light touch but tolerates deep pressure",
            "Avoids certain clothing textures (tags, seams, fabrics)",
            "Dislikes being touched by others",
            "Seeks out tactile stimulation (rubbing surfaces)",
            "Difficulty with grooming (haircuts, nails, face washing)",
            "Food texture aversions (refuses soft/lumpy/mixed)",
            "Walks barefoot or refuses to walk barefoot",
            "Reacts strongly to pain differently than expected"
        ]),
        SensorySection(title: "Proprioception", questions: [
            "Seeks heavy work (pushing, pulling, crashing)",
            "Hugs too tightly",
            "Chews on non-food items (pencils, clothing, hands)",
            "Poor awareness of force used (breaks toys)",
            "Leans against walls or people frequently",
            "Prefers tight clothing or weighted blankets"
        ]),
        SensorySection(title: "Vestibular (Movement & Balance)", questions: [
            "Seeks excessive movement (spinning, swinging, rocking)",
            "Becomes dizzy easily or not at all with spinning",
            "Fears heights or movement (car sickness, fear of swings)",
            "Poor balance (frequent falls)",
            "Rocks body when sitting",
            "Avoids playground equipment"
        ]),
        SensorySection(title: "Auditory (Sound)", questions: [
            "Covers ears in response to certain sounds",
            "Distress from specific sounds (vacuum, dryer, alarm)",
            "Seems not to hear when called but responds to other sounds",
            "Seeks loud sounds or makes loud noises",
            "Distracted by background noise"
        ]),
        SensorySection(title: "Visual", questions: [
            "Looks at objects from unusual angles",
            "Stares at lights or spinning objects",
            "Covers one eye or squints frequently",
            "Distracted by visual clutter",
            "Lines up objects rather than playing with them",
            "Difficulty with visual tracking"
        ]),
        SensorySection(title: "Olfactory (Smell)", questions: [
            "Smells food before eating it",
            "Smells people, objects, or environments excessively",
            "Reacts strongly to certain smells"
        ]),
        SensorySection(title: "Gustatory (Taste)", questions: [
            "Extremely limited food repertoire",
            "Refuses foods based on taste/texture/temperature",
            "Gags or vomits in response to certain foods",
            "Craves very spicy or very bland foods"
        ]),
        SensorySection(title: "Interoception (Internal Signals)", questions: [
            "Recognizes hunger or fullness",
            "Recognizes need to use toilet",
            "Recognizes pain appropriately",
            "Recognizes fatigue, fear, or anxiety"
        ]),
        SensorySection(title: "Behavioral Observations", questions: [
            "Engages in self-stimulatory behaviors (stimming)",
            "Has rigid routines; distressed when disrupted",
            "Has intense, narrow interests",
            "Aggressive behaviors (hitting, biting, kicking)",
            "Self-injurious behavior (head-banging, biting self)",
            "Difficulty with transitions between activities",
            "Demonstrates frustration tolerance",
            "Has meltdowns vs. shutdowns"
        ]),
        SensorySection(title: "Attention & Executive Function", questions: [
            "Attends to preferred activity for extended time",
            "Attends to non-preferred activity",
            "Shifts attention easily between tasks",
            "Follows multi-step instructions",
            "Plans and sequences tasks independently",
            "Initiates tasks without prompting",
            "Difficulty stopping an activity to move on"
        ])
    ]

    private let options = ["Yes", "Sometimes", "No"]

    // Store answers: [sectionIndex: [questionIndex: selectedOptionIndex]]
    private var answers: [Int: [Int: Int]] = [:]
    private var existingRecordID: Int?

    // Track which sections are expanded
    private var expandedSections: Set<Int> = [0] // First section open by default

    // MARK: - UI
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        return tv
    }()

    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Save", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.backgroundColor = .systemBlue
        b.layer.cornerRadius = 25
        b.layer.masksToBounds = true
        return b
    }()

    private let buttonSpinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.color = .white; s.hidesWhenStopped = true; s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // Progress label at top
    private let progressLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()

    // MARK: - Lifecycle
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAIUpdate), name: NSNotification.Name("AI_Assessment_Updated"), object: nil)
        title = "Sensory Profile"
        setupNavBar()
        setupUI()
        fetchExistingData()
        updateProgress()
    }

    // MARK: - Nav
    private func setupNavBar() {
        navigationItem.largeTitleDisplayMode = .never
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(progressLabel)
        view.addSubview(tableView)
        view.addSubview(saveButton)
        saveButton.addSubview(buttonSpinner)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SensoryQuestionCell.self, forCellReuseIdentifier: SensoryQuestionCell.reuseID)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            progressLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 4),
            progressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -10),

            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            saveButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 55),

            buttonSpinner.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor),
            buttonSpinner.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor)
        ])
    }

    private func updateProgress() {
        let total = sensoryData.reduce(0) { $0 + $1.questions.count }
        var answered = 0
        for (sIdx, section) in sensoryData.enumerated() {
            for qIdx in 0..<section.questions.count {
                if answers[sIdx]?[qIdx] != nil { answered += 1 }
            }
        }
        progressLabel.text = "\(answered) / \(total) questions answered"
    }

    @objc private func handleAIUpdate() {
        guard let pid = patientID else { return }
        let allAnswers = AssessmentSessionManager.shared.getTestAnswers(for: pid)
        
        // 1. Pull the nested dictionary for Sensory Profile
        if let saved = allAnswers["Sensory Profile"] as? [Int: [Int: Int]] {
            
            // 2. Overwrite local answers with the updated ones from AI
            self.answers = saved
            
            // 3. Update the progress label
            self.updateProgress()
            
            // 4. Reload the table view
            self.tableView.reloadData()
        }
    }

    // MARK: - Data
    private func fetchExistingData() {
        guard let pid = patientID else { return }
        Task {
            do {
                struct FetchResult: Decodable {
                    let id: Int
                    let assessment_data: [String: String]
                }
                let response = try await supabase
                    .from("assessments")
                    .select("id, assessment_data")
                    .eq("patient_id", value: pid)
                    .eq("assessment_type", value: "Sensory Profile")
                    .order("created_at", ascending: false)
                    .limit(1)
                    .single()
                    .execute()

                let decoded = try JSONDecoder().decode(FetchResult.self, from: response.data)
                self.existingRecordID = decoded.id
                await MainActor.run {
                    self.restoreAnswers(from: decoded.assessment_data)
                    self.tableView.reloadData()
                    self.updateProgress()
                }
            } catch {
                print("Sensory Profile fetch: \(error)")
            }
        }
    }

    private func restoreAnswers(from data: [String: String]) {
        for (sIdx, section) in sensoryData.enumerated() {
            for (qIdx, question) in section.questions.enumerated() {
                if let savedAnswer = data[question], let optionIdx = options.firstIndex(of: savedAnswer) {
                    if answers[sIdx] == nil { answers[sIdx] = [:] }
                    answers[sIdx]?[qIdx] = optionIdx
                }
            }
        }
    }

    private func buildResultDictionary() -> [String: AnyCodable] {
        var result: [String: AnyCodable] = [:]
        for (sIdx, section) in sensoryData.enumerated() {
            for (qIdx, question) in section.questions.enumerated() {
                if let optIdx = answers[sIdx]?[qIdx] {
                    result[question] = AnyCodable(value: options[optIdx])
                }
            }
        }
        return result
    }

    @objc private func saveTapped() {
        guard let pid = patientID else { return }
        saveButton.isEnabled = false
        saveButton.setTitle("", for: .normal)
        buttonSpinner.startAnimating()

        let resultData = buildResultDictionary()
        let log = AssessmentLog(patient_id: pid, assessment_type: "Sensory Profile", assessment_data: resultData)

        Task {
            do {
                if let id = existingRecordID {
                    try await supabase.from("assessments").update(log).eq("id", value: id).execute()
                } else {
                    try await supabase.from("assessments").insert(log).execute()
                }
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("AssessmentDidComplete"), object: nil, userInfo: ["assessmentName": "Sensory Profile"])
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                print("Save error: \(error)")
                await MainActor.run {
                    self.saveButton.isEnabled = true
                    self.saveButton.setTitle("Save", for: .normal)
                    self.buttonSpinner.stopAnimating()
                }
            }
        }
    }
}

// MARK: - Table
extension SensoryProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sensoryData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expandedSections.contains(section) ? sensoryData[section].questions.count : 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = SensorySectionHeader()
        let sectionData = sensoryData[section]
        let isExpanded = expandedSections.contains(section)

        // Count answered in this section
        let answeredCount = sectionData.questions.indices.filter { answers[section]?[$0] != nil }.count
        let totalCount = sectionData.questions.count

        header.configure(title: sectionData.title, answeredCount: answeredCount, totalCount: totalCount, isExpanded: isExpanded)
        header.tag = section
        header.onTap = { [weak self] in
            guard let self = self else { return }
            if self.expandedSections.contains(section) {
                self.expandedSections.remove(section)
            } else {
                self.expandedSections.insert(section)
            }
            tableView.reloadSections(IndexSet(integer: section), with: .automatic)
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 56
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SensoryQuestionCell.reuseID, for: indexPath) as! SensoryQuestionCell
        let question = sensoryData[indexPath.section].questions[indexPath.row]
        let selectedIdx = answers[indexPath.section]?[indexPath.row]

        cell.configure(question: question, options: options, selectedIndex: selectedIdx)
        
        cell.onOptionSelected = { [weak self] optionIndex in
            guard let self = self else { return }
            
            // Save the answer locally
            if self.answers[indexPath.section] == nil { self.answers[indexPath.section] = [:] }
            self.answers[indexPath.section]?[indexPath.row] = optionIndex
            
            if let pid = self.patientID {
                // Lock field for AI
                let sectionTitle = self.sensoryData[indexPath.section].title
                let shortQuestion = String(question.prefix(20)).replacingOccurrences(of: " ", with: "")
                let key = "SensoryProfile_\(sectionTitle)_\(shortQuestion)"
                
                AssessmentSessionManager.shared.lockField(for: pid, key: key)
                
                // Save to Session Manager so AI respects it
                AssessmentSessionManager.shared.updateTestAnswer(for: pid, key: "Sensory Profile", value: self.answers)
            }
            
            self.updateProgress()
            
            // Reload the section header to update count
            if let headerView = tableView.headerView(forSection: indexPath.section) as? SensorySectionHeader {
                let answeredCount = self.sensoryData[indexPath.section].questions.indices.filter { self.answers[indexPath.section]?[$0] != nil }.count
                headerView.updateCount(answeredCount, total: self.sensoryData[indexPath.section].questions.count)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

// MARK: - Collapsible Section Header
class SensorySectionHeader: UITableViewHeaderFooterView {
    var onTap: (() -> Void)?

    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 14
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.layer.shadowRadius = 5
        return v
    }()

    private let chevronImage: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .systemGray2
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        return l
    }()

    private let countBadge: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        l.textColor = .white
        l.textAlignment = .center
        l.backgroundColor = .systemBlue
        l.layer.cornerRadius = 10
        l.layer.masksToBounds = true
        return l
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.addSubview(cardView)
        cardView.addSubview(chevronImage)
        cardView.addSubview(titleLabel)
        cardView.addSubview(countBadge)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            chevronImage.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            chevronImage.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronImage.widthAnchor.constraint(equalToConstant: 12),
            chevronImage.heightAnchor.constraint(equalToConstant: 12),

            titleLabel.leadingAnchor.constraint(equalTo: chevronImage.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: countBadge.leadingAnchor, constant: -8),

            countBadge.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            countBadge.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            countBadge.heightAnchor.constraint(equalToConstant: 20),
            countBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 38)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        cardView.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, answeredCount: Int, totalCount: Int, isExpanded: Bool) {
        titleLabel.text = title
        countBadge.text = " \(answeredCount)/\(totalCount) "
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevronImage.image = UIImage(systemName: isExpanded ? "chevron.down" : "chevron.right", withConfiguration: config)

        // Color the badge based on completion
        if answeredCount == totalCount && totalCount > 0 {
            countBadge.backgroundColor = .systemGreen
        } else if answeredCount > 0 {
            countBadge.backgroundColor = .systemOrange
        } else {
            countBadge.backgroundColor = .systemGray3
        }
    }

    func updateCount(_ answered: Int, total: Int) {
        countBadge.text = " \(answered)/\(total) "
        if answered == total && total > 0 {
            countBadge.backgroundColor = .systemGreen
        } else if answered > 0 {
            countBadge.backgroundColor = .systemOrange
        } else {
            countBadge.backgroundColor = .systemGray3
        }
    }

    @objc private func tapped() {
        onTap?()
    }
}

// MARK: - Sensory Question Cell with Segmented Control
class SensoryQuestionCell: UITableViewCell {
    static let reuseID = "SensoryQuestionCell"
    var onOptionSelected: ((Int) -> Void)?

    private let questionLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .label
        l.numberOfLines = 0
        return l
    }()

    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl()
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(questionLabel)
        contentView.addSubview(segmentedControl)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            questionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            questionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentedControl.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 12),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentedControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(question: String, options: [String], selectedIndex: Int?) {
        questionLabel.text = question

        segmentedControl.removeAllSegments()
        for (i, opt) in options.enumerated() {
            segmentedControl.insertSegment(withTitle: opt, at: i, animated: false)
        }
        if let idx = selectedIndex {
            segmentedControl.selectedSegmentIndex = idx
        } else {
            segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        }
    }

    @objc private func segmentChanged() {
        onOptionSelected?(segmentedControl.selectedSegmentIndex)
    }
}
