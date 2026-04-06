import UIKit
import Supabase

// MARK: - Data Models
struct MedicalCondition {
    let name: String
    var isActive: Bool
}

class MedicalHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Variables
    var patientID: String?
    private var existingRecordID: Int? // Fixed: Variable restored
    
    var conditions: [MedicalCondition] = [
        // Phase 4: Diagnoses
        MedicalCondition(name: "Autism Spectrum Disorder (ASD)", isActive: false),
        MedicalCondition(name: "Intellectual Disability (ID)", isActive: false),
        MedicalCondition(name: "ADHD — Combined, Inattentive, or Hyperactive-Impulsive", isActive: false),
        MedicalCondition(name: "Developmental Coordination Disorder (DCD)", isActive: false),
        MedicalCondition(name: "Epilepsy / Seizure Disorder", isActive: false),
        MedicalCondition(name: "Anxiety Disorders", isActive: false),
        MedicalCondition(name: "Sensory Processing Disorder (SPD)", isActive: false),
        MedicalCondition(name: "Gastrointestinal Issues (constipation, GERD, food allergies)", isActive: false),
        MedicalCondition(name: "Sleep Disorders (insomnia, night waking, sleep apnea)", isActive: false),
        MedicalCondition(name: "Genetic Conditions (Down Syndrome, Fragile X, Rett)", isActive: false),
        MedicalCondition(name: "Hearing Impairment", isActive: false),
        MedicalCondition(name: "Visual Impairment / Cortical Visual Impairment", isActive: false),
        MedicalCondition(name: "Speech / Language Delay", isActive: false),
        MedicalCondition(name: "Motor Coordination / Dyspraxia", isActive: false),
        MedicalCondition(name: "Asthma", isActive: false),
        MedicalCondition(name: "Diabetes", isActive: false),
        MedicalCondition(name: "Heart Disease", isActive: false),
        MedicalCondition(name: "Dental Tre  atment History", isActive: false)
    ]
    var otherConditionText: String = ""

    // MARK: - UI Components
    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 24
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 0, height: 5)
        v.layer.shadowRadius = 10
        return v
    }()
    private let buttonSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.separatorStyle = .singleLine
        tv.separatorColor = .systemGray5
        tv.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tv.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
            tv.tableFooterView = UIView(frame: .zero)
        tv.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 30, right: 0)
        return tv
    }()
    
    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Done", for: .normal)
        b.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 25
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.layer.shadowColor = UIColor.blue.withAlphaComponent(0.3).cgColor
        b.layer.shadowOffset = CGSize(width: 0, height: 4)
        b.layer.shadowOpacity = 0.3
        b.layer.shadowRadius = 5
        return b
    }()

    // MARK: - Lifecycle
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Medical History"
        setupNavBar()
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAIUpdate), name: NSNotification.Name("AI_Assessment_Updated"), object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        guard let pid = patientID else { return }
        
        // FIX: Use getter method instead of direct property access
        let sessionData = AssessmentSessionManager.shared.getMedicalHistory(for: pid)
        if sessionData.didFetch {
            restoreFromSession()
        } else {
            fetchExistingData()
        }
    }
    @objc private func handleAIUpdate() {
        restoreFromSession() // You already wrote this helper method!
    }
    @objc func dismissKeyboard() { view.endEditing(true) }
    
    // MARK: - Data Management
    
    private func restoreFromSession() {
        guard let pid = patientID else { return }
        // FIX: Use getter method
        let sessionData = AssessmentSessionManager.shared.getMedicalHistory(for: pid)
        
        for (i, cond) in conditions.enumerated() {
            conditions[i].isActive = sessionData.conditions.contains(cond.name)
        }
        otherConditionText = sessionData.notes
        tableView.reloadData()
    }
    
    private func fetchExistingData() {
        guard let pid = patientID else { return }
        
        Task {
            do {
                let response: [AssessmentLogResponse] = try await supabase
                    .from("assessments")
                    .select("id, assessment_data")
                    .eq("patient_id", value: pid)
                    .eq("assessment_type", value: "Medical History")
                    .execute()
                    .value
                
                await MainActor.run {
                    // Update session to avoid re-fetching
                    AssessmentSessionManager.shared.updateMedicalHistory(for: pid, conditions: [], notes: "", didFetch: true)
                }
                
                if let record = response.first {
                    self.existingRecordID = record.id // Fixed: usage of restored variable
                    
                    if let data = record.assessment_data.value as? [String: Any] {
                        await MainActor.run {
                            if let savedConditions = data["conditions"] as? [String] {
                                for (index, condition) in self.conditions.enumerated() {
                                    if savedConditions.contains(condition.name) {
                                        self.conditions[index].isActive = true
                                    }
                                }
                            }
                            if let notes = data["notes"] as? String {
                                self.otherConditionText = notes
                            }
                            self.updateSession()
                            self.tableView.reloadData()
                        }
                    }
                }
            } catch {
                print("Fetch Error: \(error)")
            }
        }
    }
    
    private func updateSession() {
        guard let pid = patientID else { return }
        let activeNames = Set(conditions.filter { $0.isActive }.map { $0.name })
        // FIX: Use update method
        AssessmentSessionManager.shared.updateMedicalHistory(for: pid, conditions: activeNames, notes: otherConditionText, didFetch: true)
    }
    
    @objc private func saveData() {
        guard let pid = patientID else { return }
        
        // 1. Show Loading State
        setSaving(true)
        
        updateSession()
        
        let activeList = conditions.filter { $0.isActive }.map { $0.name }
        let results: [String: AnyCodable] = [
            "conditions": AnyCodable(value: activeList),
            "notes": AnyCodable(value: otherConditionText)
        ]
        
        let log = AssessmentLog(patient_id: pid, assessment_type: "Medical History", assessment_data: results)
        
        Task {
            do {
                if let id = existingRecordID {
                    try await supabase.from("assessments").update(log).eq("id", value: id).execute()
                } else {
                    try await supabase.from("assessments").insert(log).execute()
                }
                
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("AssessmentDidComplete"), object: nil, userInfo: ["assessmentName": "Medical History"])
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                print("Save Error: \(error)")
                await MainActor.run {
                    // 2. Hide Loading State on Error
                    setSaving(false)
                    let alert = UIAlertController(title: "Error", message: "Failed to save data. Please try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }
    // MARK: - Loading State Helper
    private func setSaving(_ isSaving: Bool) {
        if isSaving {
            saveButton.isEnabled = false
            saveButton.setTitle("", for: .normal)
            buttonSpinner.startAnimating()
        } else {
            saveButton.isEnabled = true
            saveButton.setTitle("Done", for: .normal)
            buttonSpinner.stopAnimating()
        }
    }

    
    
    // MARK: - UI Setup
    private func setupNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
    }
    @objc func backTapped() { navigationController?.popViewController(animated: true) }
    
    private func setupUI() {
        view.addSubview(cardView); cardView.addSubview(tableView); view.addSubview(saveButton)
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(MedicalConditionCell.self, forCellReuseIdentifier: "MedicalConditionCell")
        tableView.register(OtherConditionCell.self, forCellReuseIdentifier: "OtherConditionCell")
        saveButton.addTarget(self, action: #selector(saveData), for: .touchUpInside)
        saveButton.addSubview(buttonSpinner)
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -20),
            tableView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            buttonSpinner.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor),
            buttonSpinner.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            saveButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return section == 0 ? conditions.count : 1 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            if indexPath.section == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MedicalConditionCell", for: indexPath) as! MedicalConditionCell
                cell.configure(with: conditions[indexPath.row])
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "OtherConditionCell", for: indexPath) as! OtherConditionCell
                cell.setText(otherConditionText)
                
                cell.onTextChange = { [weak self] text in
                    guard let self = self, let pid = self.patientID else { return }
                    
                    // 1. Update text
                    self.otherConditionText = text
                    
                    // 2. Lock the field for AI
                    AssessmentSessionManager.shared.lockField(for: pid, key: "MedicalHistory_OtherNotes")
                    
                    // 3. Save to session
                    self.updateSession()
                }
                return cell
            }
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if indexPath.section == 0 {
                // 1. Lock the field for AI
                if let pid = patientID {
                    // Strip spaces for a clean key
                    let cleanName = conditions[indexPath.row].name.replacingOccurrences(of: " ", with: "")
                    let key = "MedicalHistory_\(cleanName)"
                    AssessmentSessionManager.shared.lockField(for: pid, key: key)
                }
                
                // 2. Toggle and save
                conditions[indexPath.row].isActive.toggle()
                updateSession()
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return indexPath.section == 0 ? 55 : 80 }
}

// MARK: - Cells (Fixed: Restored these classes)
class MedicalConditionCell: UITableViewCell {
    private let label = UILabel()
    private let icon = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .darkGray; label.translatesAutoresizingMaskIntoConstraints = false
        icon.translatesAutoresizingMaskIntoConstraints = false; icon.contentMode = .scaleAspectFit
        contentView.addSubview(label); contentView.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24), icon.heightAnchor.constraint(equalToConstant: 24),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: icon.leadingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(with item: MedicalCondition) {
        label.text = item.name
        if item.isActive {
            icon.image = UIImage(systemName: "checkmark.circle.fill"); icon.tintColor = UIColor(red: 0, green: 0.48, blue: 1, alpha: 1); label.textColor = .black
        } else {
            icon.image = UIImage(systemName: "circle"); icon.tintColor = .systemGray3; label.textColor = .darkGray
        }
    }
}

class OtherConditionCell: UITableViewCell, UITextFieldDelegate {
    var onTextChange: ((String) -> Void)?
    private let titleLabel = UILabel()
    private let textField = UITextField()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear
        titleLabel.text = "Other:"; titleLabel.font = .systemFont(ofSize: 16, weight: .bold); titleLabel.textColor = .black; titleLabel.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Enter condition..."; textField.font = .systemFont(ofSize: 16); textField.borderStyle = .none; textField.translatesAutoresizingMaskIntoConstraints = false; textField.delegate = self
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        contentView.addSubview(titleLabel); contentView.addSubview(textField)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            titleLabel.widthAnchor.constraint(equalToConstant: 60),
            textField.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 10),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textField.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func setText(_ text: String) { textField.text = text }
    @objc private func textChanged() { onTextChange?(textField.text ?? "") }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { textField.resignFirstResponder(); return true }
}
