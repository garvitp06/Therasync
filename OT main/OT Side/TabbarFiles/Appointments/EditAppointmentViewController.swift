import UIKit
import Supabase

protocol EditAppointmentDelegate: AnyObject {
    func didUpdateAppointment()
}

class EditAppointmentViewController: UIViewController {

    weak var delegate: EditAppointmentDelegate?
    
    /// The appointment being edited — set before presenting
    var appointment: Appointment!
    
    // IDs for logic
    private var linkedPatientUUID: UUID?
    private var linkedParentUUID: UUID?
    
    // MARK: - UI Elements
    
    private let inputContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 26
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
        l.text = ""
        l.font = .systemFont(ofSize: 13)
        l.textColor = .systemGray
        l.numberOfLines = 0
        return l
    }()
    
    private let dateTimeContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 26
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
    
    // MARK: - Action Buttons
    
    private let rescheduleButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Reschedule Appointment", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .systemBlue
        b.layer.cornerRadius = 26
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let saveEditsButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save Changes", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(.systemBlue, for: .normal)
        b.backgroundColor = .systemBackground
        b.layer.cornerRadius = 26
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.systemBlue.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // MARK: - State
    private var isRescheduling = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        self.title = "Edit Appointment"
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        setupNavBar()
        setupUI()
        populateFields()
        setDateTimeEnabled(false)
        
        // Prevent picking past dates in UI
        datePicker.minimumDate = Date()
        
        patientIdField.delegate = self
        patientIdField.addTarget(self, action: #selector(didEndEditingID), for: .editingDidEnd)
    }
    
    // MARK: - Nav Bar
    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didTapCancel)
        )
    }
    
    // MARK: - Populate with existing data
    private func populateFields() {
        titleTextField.text = appointment.title
        
        linkedPatientUUID = appointment.patientId
        linkedParentUUID = appointment.parentId
        
        // Set pickers to appointment date/time
        datePicker.date = appointment.date
        timePicker.date = appointment.date
        
        // Set the patient ID field display
        if let patient = appointment.patient {
            patientIdField.text = patient.patientID
            
            // Only show warning if no parent is linked
            if linkedParentUUID == nil {
                statusLabel.text = "Patient \(patient.firstName) has no Parent linked yet."
                statusLabel.textColor = .systemOrange
            } else {
                // Parent is linked - no message needed
                statusLabel.text = ""
                statusLabel.textColor = .systemGray
            }
        }
    }
    
    // MARK: - Date/Time Toggle
    private func setDateTimeEnabled(_ enabled: Bool) {
        datePicker.isEnabled = enabled
        timePicker.isEnabled = enabled
        datePicker.alpha = enabled ? 1.0 : 0.5
        timePicker.alpha = enabled ? 1.0 : 0.5
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
                        // Parent is linked - no message needed
                        self.statusLabel.text = ""
                        self.statusLabel.textColor = .systemGray
                    } else {
                        // No parent linked - show warning
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
    
    // MARK: - Actions
    
    @objc private func didTapReschedule() {
        if !isRescheduling {
            // First tap — enable date/time pickers
            isRescheduling = true
            setDateTimeEnabled(true)
            
            rescheduleButton.setTitle("Confirm Reschedule", for: .normal)
            rescheduleButton.backgroundColor = .systemOrange
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } else {
            // Second tap — save the new date
            saveAppointment(isReschedule: true)
        }
    }
    
    @objc private func didTapSaveEdits() {
        saveAppointment(isReschedule: false)
    }
    
    private func saveAppointment(isReschedule: Bool) {
        guard let title = titleTextField.text, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "Please enter a title")
            return
        }
        guard let patientID = linkedPatientUUID else {
            showAlert(message: "Please enter a valid Patient ID first.")
            return
        }
        guard let appointmentId = appointment.id else {
            showAlert(message: "Invalid appointment.")
            return
        }
        
        // Construct final date
        let date = datePicker.date
        let time = timePicker.date
        let calendar = Calendar.current
        let timeComp = calendar.dateComponents([.hour, .minute], from: time)
        let finalDate = calendar.date(bySettingHour: timeComp.hour ?? 0,
                                       minute: timeComp.minute ?? 0,
                                       second: 0, of: date) ?? date
        
        // Prevent back-dating if rescheduling
        if isReschedule && finalDate < Date() {
            showAlert(message: "Appointments cannot be rescheduled to the past.")
            return
        }
        
        Task {
            do {
                if isReschedule {
                    // Reschedule: update title, patient, date, and status
                    struct ReschedulePayload: Encodable {
                        let title: String
                        let patient_id: UUID
                        let parent_id: UUID?
                        let date: Date
                        let status: String
                    }
                    
                    let payload = ReschedulePayload(
                        title: title,
                        patient_id: patientID,
                        parent_id: linkedParentUUID,
                        date: finalDate,
                        status: "rescheduled"
                    )
                    
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    
                    try await supabase.from("appointments")
                        .update(payload)
                        .eq("id", value: appointmentId)
                        .execute()
                } else {
                    // Edit only: update title and patient
                    struct EditPayload: Encodable {
                        let title: String
                        let patient_id: UUID
                        let parent_id: UUID?
                    }
                    
                    let payload = EditPayload(
                        title: title,
                        patient_id: patientID,
                        parent_id: linkedParentUUID
                    )
                    
                    try await supabase.from("appointments")
                        .update(payload)
                        .eq("id", value: appointmentId)
                        .execute()
                }
                
                await MainActor.run {
                    self.delegate?.didUpdateAppointment()
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.showAlert(message: "Update failed: \(error.localizedDescription)")
                }
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
        view.addSubview(rescheduleButton)
        view.addSubview(saveEditsButton)
        
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
        
        rescheduleButton.addTarget(self, action: #selector(didTapReschedule), for: .touchUpInside)
        saveEditsButton.addTarget(self, action: #selector(didTapSaveEdits), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Input Container
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
            
            dateLabel.topAnchor.constraint(equalTo: dateTimeContainer.topAnchor, constant: 12),
            dateLabel.leadingAnchor.constraint(equalTo: dateTimeContainer.leadingAnchor, constant: 16),
            dateLabel.heightAnchor.constraint(equalToConstant: 34),
            
            datePicker.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            datePicker.trailingAnchor.constraint(equalTo: dateTimeContainer.trailingAnchor, constant: -16),
            
            separator2.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12),
            separator2.leadingAnchor.constraint(equalTo: dateTimeContainer.leadingAnchor, constant: 16),
            separator2.trailingAnchor.constraint(equalTo: dateTimeContainer.trailingAnchor),
            separator2.heightAnchor.constraint(equalToConstant: 0.5),
            
            timeLabel.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: 12),
            timeLabel.leadingAnchor.constraint(equalTo: dateTimeContainer.leadingAnchor, constant: 16),
            timeLabel.heightAnchor.constraint(equalToConstant: 34),
            timeLabel.bottomAnchor.constraint(equalTo: dateTimeContainer.bottomAnchor, constant: -12),
            
            timePicker.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            timePicker.trailingAnchor.constraint(equalTo: dateTimeContainer.trailingAnchor, constant: -16),
            
            // Action Buttons
            rescheduleButton.topAnchor.constraint(equalTo: dateTimeContainer.bottomAnchor, constant: 30),
            rescheduleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            rescheduleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            rescheduleButton.heightAnchor.constraint(equalToConstant: 50),
            
            saveEditsButton.topAnchor.constraint(equalTo: rescheduleButton.bottomAnchor, constant: 12),
            saveEditsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveEditsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveEditsButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
}

extension EditAppointmentViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == patientIdField { verifyPatient(id: textField.text ?? "") }
        return true
    }
}
