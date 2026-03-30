import UIKit
import Supabase

final class BirthHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Variables
    var patientID: String?
    private var existingRecordID: Int? // Fixed: Variable restored
    
    private var values: [String] = ["", "", "", "", ""]
    private let fields = ["Gestational Age", "Delivery", "Birth Weight", "Birth Order", "Complications"]

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

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        return tv
    }()
    
    private let doneButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Done", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 25
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
        title = "Birth History"
        setupNavBar()
        setupUI()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        loadData()
    }
    
    @objc func dismissKeyboard() { view.endEditing(true) }
    
    // MARK: - Data Management
    private func loadData() {
        guard let pid = patientID else { return }
        
        // FIX: Using Session Manager getter
        let session = AssessmentSessionManager.shared.getBirthHistory(for: pid)
        
        if session.didFetch {
            applyDictionaryToValues(session.data)
            tableView.reloadData()
        } else {
            fetchFromSupabase()
        }
    }
    
    private func fetchFromSupabase() {
        guard let pid = patientID else { return }
        Task {
            do {
                let response = try await supabase
                    .from("assessments")
                    .select("id, assessment_data")
                    .eq("patient_id", value: pid)
                    .eq("assessment_type", value: "Birth History")
                    .order("created_at", ascending: false)
                    .limit(1)
                    .single()
                    .execute()
                
                // Helper to decode just what we need
                struct HistoryData: Decodable {
                    let id: Int
                    let assessment_data: [String: String]
                }
                
                let decoded = try JSONDecoder().decode(HistoryData.self, from: response.data)
                self.existingRecordID = decoded.id // Fixed: Save ID for update
                let fetchedMap = decoded.assessment_data
                
                await MainActor.run {
                    self.applyDictionaryToValues(fetchedMap)
                    self.tableView.reloadData()
                    // FIX: Using Session Manager setter
                    AssessmentSessionManager.shared.updateBirthHistory(for: pid, data: fetchedMap, didFetch: true)
                }
            } catch {
                print("Fetch error: \(error)")
                await MainActor.run {
                    AssessmentSessionManager.shared.updateBirthHistory(for: pid, data: [:], didFetch: true)
                }
            }
        }
    }
    
    private func applyDictionaryToValues(_ data: [String: String]) {
        for (index, field) in fields.enumerated() {
            if let val = data[field] { values[index] = val }
        }
    }
    
    private func getCurrentDictionary() -> [String: String] {
        var dict: [String: String] = [:]
        for (index, field) in fields.enumerated() {
            dict[field] = values[index]
        }
        return dict
    }
    
    // MARK: - Actions
    @objc func save() {
        guard let pid = patientID else { return }
        doneButton.isEnabled = false; doneButton.setTitle("Saving...", for: .normal)
        
        let finalData = getCurrentDictionary()
        AssessmentSessionManager.shared.updateBirthHistory(for: pid, data: finalData, didFetch: true)
        
        // FIX: Use AnyCodable
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
                await MainActor.run { navigationController?.popViewController(animated: true) }
            } catch {
                print(error)
                await MainActor.run { doneButton.isEnabled = true; doneButton.setTitle("Done", for: .normal) }
            }
        }
    }
    
    @objc func backTapped() { navigationController?.popViewController(animated: true) }
    
    // MARK: - UI Setup & Table (Standard)
    private func setupNavBar() {
        let appearance = UINavigationBarAppearance(); appearance.configureWithTransparentBackground(); appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance; navigationController?.navigationBar.tintColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
    }
    
    private func setupUI() {
        view.addSubview(cardView); cardView.addSubview(tableView); view.addSubview(doneButton)
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(BirthHistoryCell.self, forCellReuseIdentifier: "BirthHistoryCell")
        doneButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let safe = view.safeAreaLayoutGuide
        let tableHeight = CGFloat(fields.count * 85) + 20
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cardView.heightAnchor.constraint(equalToConstant: tableHeight),
            tableView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            doneButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { fields.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BirthHistoryCell", for: indexPath) as! BirthHistoryCell
        cell.configure(title: fields[indexPath.row], value: values[indexPath.row])
        cell.onTextChange = { [weak self] txt in
            guard let self = self else { return }
            self.values[indexPath.row] = txt
            if let pid = self.patientID {
                AssessmentSessionManager.shared.updateBirthHistory(for: pid, data: self.getCurrentDictionary(), didFetch: true)
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 85 }
}

// MARK: - Cell
class BirthHistoryCell: UITableViewCell {
    var onTextChange: ((String) -> Void)?
    private let titleLabel: UILabel = { let l = UILabel(); l.translatesAutoresizingMaskIntoConstraints = false; l.font = .systemFont(ofSize: 14); l.textColor = .gray; return l }()
    private let fieldContainer: UIView = { let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; v.backgroundColor = .secondarySystemBackground; v.layer.cornerRadius = 8; return v }()
    private let textField: UITextField = { let tf = UITextField(); tf.translatesAutoresizingMaskIntoConstraints = false; tf.font = .systemFont(ofSize: 16); tf.textColor = .black; return tf }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier); selectionStyle = .none; backgroundColor = .clear
        contentView.addSubview(titleLabel); contentView.addSubview(fieldContainer); fieldContainer.addSubview(textField)
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5), titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20), titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            fieldContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5), fieldContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20), fieldContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20), fieldContainer.heightAnchor.constraint(equalToConstant: 45),
            textField.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 10), textField.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -10), textField.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor), textField.heightAnchor.constraint(equalTo: fieldContainer.heightAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(title: String, value: String) { titleLabel.text = title; textField.text = value }
    @objc private func textChanged() { onTextChange?(textField.text ?? "") }
}
