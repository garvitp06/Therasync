import UIKit
import Supabase
import Speech

final class DevelopmentalHistoryViewController: UIViewController {

    var patientID: String?
    var subSection: String = "Language & Communication"

    private var existingRecordID: Int?

    // MARK: - Question Data per SubSection
    private var fields: [String] {
        switch subSection {
        case "Language & Communication":
            return [
                "Cooing (~2 months)",
                "Babbling (consonant-vowel sounds, ~6 months)",
                "\"Mama/Dada\" non-specifically (~8–9 months)",
                "First meaningful single word (expected by 12 months)",
                "Two-word phrases (~18–24 months)",
                "Three-word sentences (~24–30 months)",
                "Has the child lost speech or skills they had previously?",
                "Is speech used functionally or echolalia (immediate/delayed)?",
                "Does the child use gestures (pointing, waving)?",
                "Does the child respond to their name when called?",
                "Does the child initiate conversation?"
            ]
        case "Social Milestones":
            return [
                "Social smile (~6 weeks)",
                "Stranger anxiety (~6–8 months)",
                "Joint attention — pointing to share interest (~9–14 months)",
                "Imitation of actions and sounds",
                "Play stage (parallel / associative / cooperative)",
                "Eye contact — spontaneous or absent?",
                "Does the child show affection to caregivers?",
                "Separation anxiety — typical or extreme?"
            ]
        case "Self-Care Milestones":
            return [
                "Feeding self with fingers (~12 months)",
                "Spoon use (~18 months)",
                "Fork use (~24 months)",
                "Drinking from open cup (~12–18 months)",
                "Toilet training — age started, current status (daytime/nighttime)",
                "Dressing: undressing before dressing; sequence of clothing",
                "Bathing: tolerance, independent steps",
                "Toothbrushing: tolerance, technique"
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
            } catch { print("DevHistory fetch: \(error)") }
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

extension DevelopmentalHistoryViewController: UITableViewDataSource, UITableViewDelegate {
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

// MARK: - Voice-Enabled Text Input Cell (Shared)
class VoiceTextInputCell: UITableViewCell {
    static let reuseID = "VoiceTextInputCell"
    var onTextChange: ((String) -> Void)?

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isRecording = false

    private let titleLabel: UILabel = {
        let l = UILabel(); l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14); l.textColor = .secondaryLabel; l.numberOfLines = 0
        return l
    }()

    private let fieldContainer: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemGroupedBackground; v.layer.cornerRadius = 10
        return v
    }()

    private let textField: UITextField = {
        let tf = UITextField(); tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = .systemFont(ofSize: 16); tf.borderStyle = .none
        tf.placeholder = "Type or tap mic to speak..."
        return tf
    }()

    private let micButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        b.setImage(UIImage(systemName: "mic.fill", withConfiguration: config), for: .normal)
        b.tintColor = .systemBlue
        return b
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
        contentView.addSubview(titleLabel)
        contentView.addSubview(fieldContainer)
        fieldContainer.addSubview(textField)
        fieldContainer.addSubview(micButton)
        textField.addTarget(self, action: #selector(changed), for: .editingChanged)
        micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            fieldContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            fieldContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fieldContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            fieldContainer.heightAnchor.constraint(equalToConstant: 44),
            fieldContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            textField.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
            micButton.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -8),
            micButton.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 32),
            micButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopRecording()
    }

    func configure(title: String, value: String) { titleLabel.text = title; textField.text = value }
    @objc private func changed() { onTextChange?(textField.text ?? "") }

    // MARK: - Speech Recognition
    @objc private func micTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    self?.showPermissionNeeded()
                    return
                }
                self?.beginAudioRecording()
            }
        }
    }

    private func beginAudioRecording() {
        // Guard against double-start
        guard !isRecording else { return }

        // Cancel any existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Always remove existing tap first to prevent crash
        let inputNode = audioEngine.inputNode
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        inputNode.removeTap(onBus: 0)

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return
        }

        // Validate format — simulator returns 0 channels which crashes
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("Invalid audio format — microphone not available (simulator?)")
            showPermissionNeeded()
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest, let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else { return }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.textField.text = result.bestTranscription.formattedString
                    self?.onTextChange?(result.bestTranscription.formattedString)
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.async {
                    self?.stopRecording()
                }
            }
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            micButton.tintColor = .systemRed
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            micButton.setImage(UIImage(systemName: "stop.circle.fill", withConfiguration: config), for: .normal)
        } catch {
            print("Audio engine start error: \(error)")
            inputNode.removeTap(onBus: 0)
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        micButton.tintColor = .systemBlue
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        micButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: config), for: .normal)
    }

    private func showPermissionNeeded() {
        // Visual feedback: shake the mic button
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [-4, 4, -3, 3, 0]
        anim.duration = 0.3
        micButton.layer.add(anim, forKey: "shake")
    }
}

// Keep old TextInputCell as alias for backward compat
typealias TextInputCell = VoiceTextInputCell
