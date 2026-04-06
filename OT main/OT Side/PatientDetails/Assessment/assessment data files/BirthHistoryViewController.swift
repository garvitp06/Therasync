import UIKit
import Supabase
import Speech

final class BirthHistoryViewController: UIViewController {
    
    // MARK: - Variables
    var patientID: String?
    private var existingRecordID: Int?
    
    // MARK: - Section Data from Phase 2
    private struct HistorySection {
        let title: String
        let fields: [String]
    }
    
    private let sections: [HistorySection] = [
        HistorySection(title: "Prenatal History", fields: [
            "Was the pregnancy planned?",
            "Any infections during pregnancy (TORCH)?",
            "Medications taken during pregnancy",
            "Alcohol, smoking, or drug exposure during pregnancy",
            "Gestational diabetes or hypertension",
            "Any fetal distress noted during scans?",
            "Number of prenatal check-ups",
            "Any abnormalities on ultrasound?",
            "Single or multiple pregnancy (twins, triplets)?",
            "Maternal age at delivery",
            "Paternal age at conception"
        ]),
        HistorySection(title: "Birth History", fields: [
            "Type of delivery (NVD / C-section / Assisted)",
            "If C-section — elective or emergency, reason?",
            "Gestation at birth (term 37–42 weeks / preterm / post-term)",
            "Birth weight (low birth weight < 2.5 kg?)",
            "APGAR score at 1 minute and 5 minutes",
            "Did the baby cry immediately at birth?",
            "Was resuscitation needed?",
            "Any jaundice (neonatal hyperbilirubinemia)?",
            "NICU admission — duration and reason?",
            "Any birth injuries?",
            "Was meconium present in the amniotic fluid?",
            "Cord complications (nuchal cord, cord prolapse)?",
            "Blood group incompatibility (ABO/Rh)?"
        ]),
        HistorySection(title: "Neonatal Period", fields: [
            "Was the baby able to feed (breast/bottle) soon after birth?",
            "Rooting reflex, sucking reflex present?",
            "Any seizures in the neonatal period?",
            "Temperature regulation problems?",
            "Hypoglycemia in the newborn?"
        ])
    ]
    
    // Flat values array indexed by (section, row) mapped to sequential index
    private lazy var values: [String] = {
        let total = sections.reduce(0) { $0 + $1.fields.count }
        return Array(repeating: "", count: total)
    }()
    
    private func flatIndex(section: Int, row: Int) -> Int {
        var idx = 0
        for s in 0..<section { idx += sections[s].fields.count }
        return idx + row
    }

    // MARK: - UI Components
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        return tv
    }()
    
    private let doneButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Done", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.backgroundColor = .systemBlue
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 25
        return b
    }()

    private let buttonSpinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.color = .white; s.hidesWhenStopped = true; s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Lifecycle
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Birth History"
        setupNavBar()
        setupUI()
        loadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAIUpdate), name: NSNotification.Name("AI_Assessment_Updated"), object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() { view.endEditing(true) }
    
    // MARK: - Data Management
    private func loadData() {
        guard let pid = patientID else { return }
        
        let session = AssessmentSessionManager.shared.getBirthHistory(for: pid)
        if session.didFetch {
            applyDictionary(session.data)
            tableView.reloadData()
        } else {
            fetchFromSupabase()
        }
    }
    
    @objc private func handleAIUpdate() {
        guard let pid = patientID else { return }
        
        // Call the specific getter for this screen
        // e.g., getBirthHistory, getSchoolComplaints, etc.
        let session = AssessmentSessionManager.shared.getBirthHistory(for: pid)
        
        if session.didFetch {
            applyDictionary(session.data) // Or applyDictionaryToValues, depending on the file
            tableView.reloadData()
        }
    }
    
    private func fetchFromSupabase() {
        guard let pid = patientID else { return }
        Task {
            do {
                struct HistoryData: Decodable {
                    let id: Int
                    let assessment_data: [String: String]
                }
                let response = try await supabase
                    .from("assessments")
                    .select("id, assessment_data")
                    .eq("patient_id", value: pid)
                    .eq("assessment_type", value: "Birth History")
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()
                
                let decoded = try JSONDecoder().decode([HistoryData].self, from: response.data)
                guard let first = decoded.first else {
                    await MainActor.run {
                        AssessmentSessionManager.shared.updateBirthHistory(for: pid, data: [:], didFetch: true)
                    }
                    return
                }
                self.existingRecordID = first.id
                
                await MainActor.run {
                    self.applyDictionary(first.assessment_data)
                    self.tableView.reloadData()
                    AssessmentSessionManager.shared.updateBirthHistory(for: pid, data: first.assessment_data, didFetch: true)
                }
            } catch {
                print("Birth History fetch: \(error)")
                await MainActor.run {
                    AssessmentSessionManager.shared.updateBirthHistory(for: pid, data: [:], didFetch: true)
                }
            }
        }
    }
    
    private func applyDictionary(_ data: [String: String]) {
        for (sIdx, section) in sections.enumerated() {
            for (rIdx, field) in section.fields.enumerated() {
                if let val = data[field] { values[flatIndex(section: sIdx, row: rIdx)] = val }
            }
        }
    }
    
    private func getCurrentDictionary() -> [String: String] {
        var dict: [String: String] = [:]
        for (sIdx, section) in sections.enumerated() {
            for (rIdx, field) in section.fields.enumerated() {
                dict[field] = values[flatIndex(section: sIdx, row: rIdx)]
            }
        }
        return dict
    }
    
    // MARK: - Actions
    @objc func save() {
        guard let pid = patientID else { return }
        doneButton.isEnabled = false; doneButton.setTitle("", for: .normal); buttonSpinner.startAnimating()
        
        let finalData = getCurrentDictionary()
        AssessmentSessionManager.shared.updateBirthHistory(for: pid, data: finalData, didFetch: true)
        
        var dbData: [String: AnyCodable] = [:]
        for (key, val) in finalData { dbData[key] = AnyCodable(value: val) }
        
        let log = AssessmentLog(patient_id: pid, assessment_type: "Birth History", assessment_data: dbData)
        
        Task {
            do {
                if let id = existingRecordID {
                    try await supabase.from("assessments").update(log).eq("id", value: id).execute()
                } else {
                    try await supabase.from("assessments").insert(log).execute()
                }
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("AssessmentDidComplete"), object: nil, userInfo: ["assessmentName": "Birth History"])
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                print(error)
                await MainActor.run {
                    doneButton.isEnabled = true; doneButton.setTitle("Done", for: .normal); buttonSpinner.stopAnimating()
                }
            }
        }
    }
    
    // MARK: - UI Setup
    private func setupNavBar() {
        navigationItem.largeTitleDisplayMode = .never
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(doneButton)
        doneButton.addSubview(buttonSpinner)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(VoiceTextInputCell.self, forCellReuseIdentifier: VoiceTextInputCell.reuseID)
        doneButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safe.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -10),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            doneButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 55),
            buttonSpinner.centerXAnchor.constraint(equalTo: doneButton.centerXAnchor),
            buttonSpinner.centerYAnchor.constraint(equalTo: doneButton.centerYAnchor)
        ])
    }
}

// MARK: - Table
extension BirthHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].fields.count }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { sections[section].title }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .white
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: VoiceTextInputCell.reuseID, for: indexPath) as! VoiceTextInputCell
            
            let field = sections[indexPath.section].fields[indexPath.row]
            let idx = flatIndex(section: indexPath.section, row: indexPath.row)
            
            cell.configure(title: field, value: values[idx])
            
            cell.onTextChange = { [weak self] txt in
                guard let self = self, let pid = self.patientID else { return }
                
                // 1. Update the local array
                self.values[idx] = txt
                
                // 2. LOCK THE FIELD for AI
                // Create a clean key using the first 15 characters of the field name
                let shortQuestion = String(field.prefix(15)).replacingOccurrences(of: " ", with: "")
                let lockKey = "BirthHistory_\(shortQuestion)"
                AssessmentSessionManager.shared.lockField(for: pid, key: lockKey)
                
                // 3. Save to Session Manager
                AssessmentSessionManager.shared.updateBirthHistory(for: pid, data: self.getCurrentDictionary(), didFetch: true)
            }
            
            return cell
        }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return UITableView.automaticDimension }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { return 85 }
}
