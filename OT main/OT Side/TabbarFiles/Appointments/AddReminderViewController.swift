import UIKit
import Supabase

protocol AddReminderDelegate: AnyObject {
    func didAddAppointment()
}

class AddReminderViewController: UIViewController {

    weak var delegate: AddReminderDelegate?
    
    // IDs for logic
    private var linkedPatientUUID: UUID?
    private var linkedParentUUID: UUID?
    
    // MARK: - UI Elements: Form
    
    private let inputContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        return v
    }()
    
    private let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Appointment Title"
        tf.font = .systemFont(ofSize: 17)
        return tf
    }()
    
    private let separator1: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        return v
    }()
    
    private let patientIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Patient ID (Required)"
        tf.font = .systemFont(ofSize: 17)
        tf.autocapitalizationType = .none
        tf.returnKeyType = .search
        return tf
    }()
    
    private let statusLabel: UILabel = {
        let l = UILabel()
        l.text = "Enter Patient ID to verify"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .systemGray
        l.numberOfLines = 0
        return l
    }()
    
    private let dateTimeContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        return v
    }()
    
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.text = "Date"
        l.font = .systemFont(ofSize: 17)
        return l
    }()
    
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.text = "Time"
        l.font = .systemFont(ofSize: 17)
        return l
    }()
    
    private let datePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        p.preferredDatePickerStyle = .compact
        return p
    }()
    
    private let timePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .time
        p.preferredDatePickerStyle = .compact
        return p
    }()
    
    private let separator2: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        return v
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        // 1. Native Title
        self.title = "New Appointment"
        
        // 2. Show Native Navigation Bar
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        setupNavBar()
        setupUI()
        
        // --- PREVENT BACK DATING (UI) ---
        // This prevents the user from scrolling to past dates
        datePicker.minimumDate = Date()
        
        patientIdField.delegate = self
        patientIdField.addTarget(self, action: #selector(didEndEditingID), for: .editingDidEnd)
    }
    
    // MARK: - Setup Native Nav Bar
    private func setupNavBar() {
        // Native Cancel Button
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
        
        // Native "Tick" (Checkmark) Button
        let tickButton = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .done, target: self, action: #selector(didTapSave))
        navigationItem.rightBarButtonItem = tickButton
    }
    
    // MARK: - Logic
    @objc func didEndEditingID() {
        guard let idText = patientIdField.text, !idText.isEmpty else { return }
        verifyPatient(id: idText)
    }
    
    func verifyPatient(id: String) {
        statusLabel.text = "Searching..."
        statusLabel.textColor = .systemBlue
        
        Task {
            do {
                struct PatientLookup: Decodable {
                    let id: UUID
                    let first_name: String
                    let parent_uid: UUID?
                }
                
                let result: PatientLookup = try await supabase
                    .from("patients")
                    .select("id, first_name, parent_uid")
                    .eq("patient_id_number", value: id.trimmingCharacters(in: .whitespaces))
                    .single()
                    .execute()
                    .value
                
                self.linkedPatientUUID = result.id
                self.linkedParentUUID = result.parent_uid
                
                await MainActor.run {
                    if result.parent_uid != nil {
                        self.statusLabel.text = "Linked to: \(result.first_name)"
                        self.statusLabel.textColor = .systemGreen
                    } else {
                        self.statusLabel.text = "Found \(result.first_name), but no Parent is linked yet."
                        self.statusLabel.textColor = .systemOrange
                    }
                }
            } catch {
                await MainActor.run {
                    self.linkedPatientUUID = nil
                    self.linkedParentUUID = nil
                    self.statusLabel.text = "Patient Not Found"
                    self.statusLabel.textColor = .systemRed
                }
            }
        }
    }
    
    @objc private func didTapSave() {
        guard let title = titleTextField.text, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "Please enter a title")
            return
        }
        guard let patientID = linkedPatientUUID else {
            showAlert(message: "Please enter a valid Patient ID first.")
            return
        }
        
        // 1. Construct the final date from Date Picker + Time Picker
        let date = datePicker.date
        let time = timePicker.date
        let calendar = Calendar.current
        let timeComp = calendar.dateComponents([.hour, .minute], from: time)
        let finalDate = calendar.date(bySettingHour: timeComp.hour ?? 0, minute: timeComp.minute ?? 0, second: 0, of: date) ?? date
        
        // 2. PREVENT BACK DATING (Logic Check)
        // Check if the exact time chosen is in the past
        if finalDate < Date() {
            showAlert(message: "Appointments cannot be scheduled in the past.")
            return
        }
        
        Task {
            do {
                let therapistID = try await supabase.auth.session.user.id
                let newAppt = Appointment(
                    id: nil, title: title, date: finalDate, status: "confirmed",
                    createdByRole: "therapist", patientId: patientID,
                    therapistId: therapistID, parentId: linkedParentUUID
                )
                try await supabase.from("appointments").insert(newAppt).execute()
                await MainActor.run {
                    self.delegate?.didAddAppointment()
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run { self.showAlert(message: "Save failed: \(error.localizedDescription)") }
            }
        }
    }
    
    @objc func didTapCancel() {
        dismiss(animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - UI Layout
    private func setupUI() {
        view.addSubview(inputContainer)
        view.addSubview(dateTimeContainer)
        view.addSubview(statusLabel)
        
        // Turn off auto-resizing masks
        [inputContainer, dateTimeContainer, statusLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Input Fields
        inputContainer.addSubview(titleTextField)
        inputContainer.addSubview(separator1)
        inputContainer.addSubview(patientIdField)
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        separator1.translatesAutoresizingMaskIntoConstraints = false
        patientIdField.translatesAutoresizingMaskIntoConstraints = false
        
        // Date Time Fields
        dateTimeContainer.addSubview(dateLabel)
        dateTimeContainer.addSubview(datePicker)
        dateTimeContainer.addSubview(separator2)
        dateTimeContainer.addSubview(timeLabel)
        dateTimeContainer.addSubview(timePicker)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        separator2.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Input Container (Pinned to Safe Area Top)
            inputContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            inputContainer.heightAnchor.constraint(equalToConstant: 100),
            
            titleTextField.topAnchor.constraint(equalTo: inputContainer.topAnchor),
            titleTextField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            titleTextField.heightAnchor.constraint(equalToConstant: 50),
            
            separator1.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            separator1.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            separator1.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor),
            separator1.heightAnchor.constraint(equalToConstant: 0.5),
            
            patientIdField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor),
            patientIdField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            patientIdField.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            patientIdField.heightAnchor.constraint(equalToConstant: 50),
            
            statusLabel.topAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Date Container
            dateTimeContainer.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            dateTimeContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dateTimeContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Date Row
            dateLabel.topAnchor.constraint(equalTo: dateTimeContainer.topAnchor, constant: 12),
            dateLabel.leadingAnchor.constraint(equalTo: dateTimeContainer.leadingAnchor, constant: 16),
            dateLabel.heightAnchor.constraint(equalToConstant: 34),
            
            datePicker.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            datePicker.trailingAnchor.constraint(equalTo: dateTimeContainer.trailingAnchor, constant: -16),
            
            separator2.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12),
            separator2.leadingAnchor.constraint(equalTo: dateTimeContainer.leadingAnchor, constant: 16),
            separator2.trailingAnchor.constraint(equalTo: dateTimeContainer.trailingAnchor),
            separator2.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Time Row
            timeLabel.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: 12),
            timeLabel.leadingAnchor.constraint(equalTo: dateTimeContainer.leadingAnchor, constant: 16),
            timeLabel.heightAnchor.constraint(equalToConstant: 34),
            timeLabel.bottomAnchor.constraint(equalTo: dateTimeContainer.bottomAnchor, constant: -12),
            
            timePicker.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            timePicker.trailingAnchor.constraint(equalTo: dateTimeContainer.trailingAnchor, constant: -16)
        ])
    }
}

extension AddReminderViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == patientIdField { verifyPatient(id: textField.text ?? "") }
        return true
    }
}
