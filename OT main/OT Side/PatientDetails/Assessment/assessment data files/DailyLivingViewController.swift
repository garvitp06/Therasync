import UIKit
import Supabase
import Speech

final class DailyLivingViewController: UIViewController {

    var patientID: String?
    var subSection: String = "Feeding"

    private var existingRecordID: Int?

    // MARK: - Question Data per SubSection
    private var fields: [String] {
        switch subSection {
        case "Feeding":
            return [
                "Food repertoire: how many foods accepted? (less than 20 = concern)",
                "Textures accepted (puree, soft, crunchy, mixed)",
                "Temperature preferences",
                "Utensil use (spoon, fork, chopsticks?)",
                "Is mealtime a positive or stressful experience?",
                "Does the child eat with the family?",
                "Duration of mealtimes"
            ]
        case "Dressing":
            return [
                "Can the child identify front and back of clothing?",
                "Can the child pull on/off t-shirts, pants, socks, shoes?",
                "Can the child manage fasteners (velcro, buttons, zippers, snaps, laces)?",
                "Sequence of dressing — does the child know the order?",
                "Does the child resist certain clothing items? Why?"
            ]
        case "Bathing & Hygiene":
            return [
                "Tolerates bathing? Specific aversions (water on face, shampoo, soap)?",
                "Can the child wash their own body with prompting?",
                "Toothbrushing tolerance (texture of bristle, flavor, duration)",
                "Hair brushing/washing — reaction?",
                "Nail cutting — reaction?",
                "Face washing — reaction?"
            ]
        case "Toileting":
            return [
                "Currently toilet trained (day/night)?",
                "Can the child recognize urge to void/defecate?",
                "Can the child manage clothing for toileting independently?",
                "Any history of constipation or bowel issues?",
                "Does the child wipe adequately?",
                "Does the child flush without distress?",
                "Does the child use public toilets? Any barriers?"
            ]
        case "Sleep":
            return [
                "Sleep schedule (bedtime, wake time)",
                "Sleep onset — time taken to fall asleep",
                "Night wakings — frequency and duration",
                "Does the child co-sleep?",
                "Sleep hygiene routine (bath, book, dark room, white noise)?",
                "Use of melatonin or other sleep aids?",
                "Impact of poor sleep on daytime functioning"
            ]
        default:
            return []
        }
    }

    private lazy var values: [String] = Array(repeating: "", count: fields.count)

    // MARK: - UI
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
    override func loadView() { self.view = GradientView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = subSection
        setupNavBar()
        setupUI()
        fetchData()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKB))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc private func dismissKB() { view.endEditing(true) }

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

    // MARK: - Data
    private func fetchData() {
        guard let pid = patientID else { return }
        Task {
            do {
                struct R: Decodable { let id: Int; let assessment_data: [String: String] }
                let res = try await supabase.from("assessments").select("id, assessment_data")
                    .eq("patient_id", value: pid).eq("assessment_type", value: subSection)
                    .order("created_at", ascending: false).limit(1).single().execute()
                let decoded = try JSONDecoder().decode(R.self, from: res.data)
                self.existingRecordID = decoded.id
                await MainActor.run {
                    for (i, f) in self.fields.enumerated() {
                        if let v = decoded.assessment_data[f] { self.values[i] = v }
                    }
                    self.tableView.reloadData()
                }
            } catch { print("DailyLiving fetch: \(error)") }
        }
    }

    @objc private func save() {
        guard let pid = patientID else { return }
        doneButton.isEnabled = false; doneButton.setTitle("", for: .normal); buttonSpinner.startAnimating()

        var dbData: [String: AnyCodable] = [:]
        for (i, f) in fields.enumerated() { dbData[f] = AnyCodable(value: values[i]) }
        let log = AssessmentLog(patient_id: pid, assessment_type: subSection, assessment_data: dbData)

        Task {
            do {
                if let id = existingRecordID {
                    try await supabase.from("assessments").update(log).eq("id", value: id).execute()
                } else {
                    try await supabase.from("assessments").insert(log).execute()
                }
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("AssessmentDidComplete"), object: nil, userInfo: ["assessmentName": self.subSection])
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.doneButton.isEnabled = true; self.doneButton.setTitle("Done", for: .normal); self.buttonSpinner.stopAnimating()
                }
            }
        }
    }
}

extension DailyLivingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { fields.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VoiceTextInputCell.reuseID, for: indexPath) as! VoiceTextInputCell
        cell.configure(title: fields[indexPath.row], value: values[indexPath.row])
        cell.onTextChange = { [weak self] txt in self?.values[indexPath.row] = txt }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return UITableView.automaticDimension }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { return 85 }
}
