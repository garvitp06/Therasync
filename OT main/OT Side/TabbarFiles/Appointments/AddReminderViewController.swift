import UIKit
import Supabase

protocol AddReminderDelegate: AnyObject {
    func didAddAppointment()
}

class AddReminderViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    weak var delegate: AddReminderDelegate?
    
    // IDs for logic
    private var linkedPatientUUID: UUID?
    private var linkedParentUUID: UUID?
    
    // MARK: - Patient Lookup Model
    struct PatientLookup: Decodable {
        let id: UUID
        let first_name: String
        let last_name: String?
        let patient_id_number: String
        let parent_uid: UUID?
        
        var fullName: String {
            if let ln = last_name { return "\(first_name) \(ln)" }
            return first_name
        }
    }
    
    private var allPatients: [PatientLookup] = []
    private var filteredPatients: [PatientLookup] = []
    
    // MARK: - UI Elements
    private let formTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.keyboardDismissMode = .interactive
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "container")
        return tv
    }()
    
    // Form Cells (Static)
    private let titleCell = UITableViewCell()
    private let patientCell = UITableViewCell()
    private let dateCell = UITableViewCell()
    private let timeCell = UITableViewCell()
    
    // Cell Contents
    private let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Appointment Title"
        tf.font = .systemFont(ofSize: 17)
        return tf
    }()
    
    private let patientIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Patient Name or ID (Required)"
        tf.font = .systemFont(ofSize: 17)
        tf.autocapitalizationType = .none
        tf.returnKeyType = .done
        return tf
    }()
    
    private let suggestionTableView: UITableView = {
        let tv = UITableView()
        tv.rowHeight = 44
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()
    
    private let statusLabel: UILabel = {
        let l = UILabel()
        l.text = "Search Patient Name or ID"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .systemGray
        l.numberOfLines = 0
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
        datePicker.minimumDate = Date()
        
        patientIdField.delegate = self
        patientIdField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        titleTextField.delegate = self
        
        suggestionTableView.delegate = self
        suggestionTableView.dataSource = self
        
        fetchAllPatients()
    }
    
    // MARK: - Setup Native Nav Bar
    private func setupNavBar() {
        // Native Cancel Button
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
        
        // Native "Save" / "Done" Button
        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSave))
        navigationItem.rightBarButtonItem = saveButton
    }
    
    // MARK: - UI Layout
    private func setupUI() {
        // Configure standard cells
        titleCell.selectionStyle = .none
        titleCell.contentView.addSubview(titleTextField)
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleTextField.leadingAnchor.constraint(equalTo: titleCell.contentView.layoutMarginsGuide.leadingAnchor),
            titleTextField.trailingAnchor.constraint(equalTo: titleCell.contentView.layoutMarginsGuide.trailingAnchor),
            titleTextField.topAnchor.constraint(equalTo: titleCell.contentView.topAnchor),
            titleTextField.bottomAnchor.constraint(equalTo: titleCell.contentView.bottomAnchor),
            titleTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        patientCell.selectionStyle = .none
        patientCell.contentView.addSubview(patientIdField)
        patientIdField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            patientIdField.leadingAnchor.constraint(equalTo: patientCell.contentView.layoutMarginsGuide.leadingAnchor),
            patientIdField.trailingAnchor.constraint(equalTo: patientCell.contentView.layoutMarginsGuide.trailingAnchor),
            patientIdField.topAnchor.constraint(equalTo: patientCell.contentView.topAnchor),
            patientIdField.bottomAnchor.constraint(equalTo: patientCell.contentView.bottomAnchor),
            patientIdField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        dateCell.textLabel?.text = "Date"
        dateCell.selectionStyle = .none
        dateCell.accessoryView = datePicker
        
        timeCell.textLabel?.text = "Time"
        timeCell.selectionStyle = .none
        timeCell.accessoryView = timePicker
        
        // Setup Form Table
        formTableView.delegate = self
        formTableView.dataSource = self
        view.addSubview(formTableView)
        formTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            formTableView.topAnchor.constraint(equalTo: view.topAnchor),
            formTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            formTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            formTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Logic
    private func fetchAllPatients() {
        Task {
            do {
                let therapistID = try await supabase.auth.session.user.id
                
                let results: [PatientLookup] = try await supabase
                    .from("patients")
                    .select("id, first_name, last_name, patient_id_number, parent_uid")
                    .eq("ot_id", value: therapistID)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.allPatients = results
                }
            } catch {
                print("Failed to fetch patients: \(error)")
            }
        }
    }
    
    @objc private func textFieldDidChange(_ tf: UITextField) {
        let query = tf.text?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
        
        let wasEmpty = filteredPatients.isEmpty
        
        if query.isEmpty {
            linkedPatientUUID = nil
            linkedParentUUID = nil
            statusLabel.text = "Search Patient Name or ID"
            statusLabel.textColor = .systemGray
            
            filteredPatients = []
            suggestionTableView.reloadData()
            
            if !wasEmpty {
                formTableView.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .fade)
            }
            return
        }
        
        // Disable currently linked patient if they type something else
        linkedPatientUUID = nil
        linkedParentUUID = nil
        statusLabel.text = "Select a patient from the list"
        statusLabel.textColor = .systemOrange
        
        filteredPatients = allPatients.filter {
            $0.fullName.lowercased().contains(query) ||
            $0.patient_id_number.lowercased().contains(query)
        }
        
        let isEmpty = filteredPatients.isEmpty
        suggestionTableView.reloadData()
        
        if wasEmpty && !isEmpty {
            formTableView.insertRows(at: [IndexPath(row: 2, section: 0)], with: .fade)
        } else if !wasEmpty && isEmpty {
            formTableView.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .fade)
        }
        
        // Force header/footer update to refresh status text layout
        formTableView.beginUpdates()
        formTableView.endUpdates()
    }
    
    @objc private func didTapSave() {
        guard let title = titleTextField.text?.trimmingCharacters(in: .whitespaces), !title.isEmpty else {
            showAlert(message: "Please enter a title")
            return
        }
        guard let patientID = linkedPatientUUID else {
            showAlert(message: "Please select a valid Patient from the suggestions.")
            return
        }
        
        // 1. Construct the final date from Date Picker + Time Picker
        let date = datePicker.date
        let time = timePicker.date
        let calendar = Calendar.current
        let timeComp = calendar.dateComponents([.hour, .minute], from: time)
        let finalDate = calendar.date(bySettingHour: timeComp.hour ?? 0, minute: timeComp.minute ?? 0, second: 0, of: date) ?? date
        
        // 2. PREVENT BACK DATING (Logic Check)
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
    
    // MARK: - Form TableView Logic
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == suggestionTableView { return 1 }
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == suggestionTableView {
            return filteredPatients.count
        }
        
        if section == 0 {
            return filteredPatients.isEmpty ? 2 : 3
        }
        return 2 // Date & Time rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == suggestionTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let patient = filteredPatients[indexPath.row]
            cell.textLabel?.text = "\(patient.fullName) (\(patient.patient_id_number))"
            cell.textLabel?.font = .systemFont(ofSize: 15)
            return cell
        }
        
        if indexPath.section == 0 {
            if indexPath.row == 0 { return titleCell }
            if indexPath.row == 1 { return patientCell }
            
            // Row 2 is the suggestion container
            let cell = tableView.dequeueReusableCell(withIdentifier: "container", for: indexPath)
            cell.selectionStyle = .none
            if suggestionTableView.superview != cell.contentView {
                cell.contentView.addSubview(suggestionTableView)
                suggestionTableView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    suggestionTableView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                    suggestionTableView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                    suggestionTableView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                    suggestionTableView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
                ])
            }
            return cell
        } else {
            if indexPath.row == 0 { return dateCell }
            if indexPath.row == 1 { return timeCell }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == formTableView && indexPath.section == 0 && indexPath.row == 2 {
            return 150
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == suggestionTableView {
            tableView.deselectRow(at: indexPath, animated: true)
            let selected = filteredPatients[indexPath.row]
            
            patientIdField.text = "\(selected.fullName) (\(selected.patient_id_number))"
            linkedPatientUUID = selected.id
            linkedParentUUID = selected.parent_uid
            view.endEditing(true)
            
            if selected.parent_uid != nil {
                statusLabel.text = "Linked to: \(selected.fullName)"
                statusLabel.textColor = .systemGreen
            } else {
                statusLabel.text = "Selected \(selected.fullName), but no Parent is linked yet."
                statusLabel.textColor = .systemOrange
            }
            
            // clear filtered patients to hide TV
            let wasEmpty = filteredPatients.isEmpty
            filteredPatients.removeAll()
            suggestionTableView.reloadData()
            if !wasEmpty {
                formTableView.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .fade)
            }
            
            // Reload footer texts
            formTableView.beginUpdates()
            formTableView.endUpdates()
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == formTableView {
            return section == 0 ? "Details" : "Date & Time"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if tableView == formTableView && section == 0 {
            let container = UIView()
            container.addSubview(statusLabel)
            statusLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                statusLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                statusLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
                statusLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
            ])
            return container
        }
        return nil
    }
    
    // Auto-resizing for footer
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if tableView == formTableView && section == 0 {
            return UITableView.automaticDimension
        }
        return 0
    }
    
    // MARK: - Text Field Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField == patientIdField {
            if !filteredPatients.isEmpty {
                let selected = filteredPatients[0]
                patientIdField.text = "\(selected.fullName) (\(selected.patient_id_number))"
                linkedPatientUUID = selected.id
                linkedParentUUID = selected.parent_uid
                
                if selected.parent_uid != nil {
                    statusLabel.text = "Linked to: \(selected.fullName)"
                    statusLabel.textColor = .systemGreen
                } else {
                    statusLabel.text = "Selected \(selected.fullName), but no Parent is linked yet."
                    statusLabel.textColor = .systemOrange
                }
                
                let wasEmpty = filteredPatients.isEmpty
                filteredPatients.removeAll()
                suggestionTableView.reloadData()
                if !wasEmpty {
                    formTableView.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .fade)
                }
                
                formTableView.beginUpdates()
                formTableView.endUpdates()
            }
        }
        return true
    }
}
