import UIKit
import Supabase

protocol AddReminderDelegate: AnyObject {
    func didAddAppointment()
}

class AddReminderViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

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
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .onDrag
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let mainStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 20
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    // MARK: - Input Containers
    private let inputContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 26
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Appointment Title"
        tf.font = .systemFont(ofSize: 17, weight: .medium)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let separator1: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let patientIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Search Patient Name or ID"
        tf.font = .systemFont(ofSize: 17)
        tf.autocapitalizationType = .none
        tf.returnKeyType = .done
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let suggestionTableView: UITableView = {
        let tv = UITableView()
        tv.rowHeight = 50
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.layer.cornerRadius = 16
        tv.isHidden = true
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray5.cgColor
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let statusLabel: UILabel = {
        let l = UILabel()
        l.text = "Select a patient from suggestions"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .systemGray
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // MARK: - Date & Time Container
    private let dateTimeContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 26
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.text = "Date"
        l.font = .systemFont(ofSize: 17)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let datePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        p.preferredDatePickerStyle = .compact
        p.minimumDate = Date()
        p.translatesAutoresizingMaskIntoConstraints = false
        return p
    }()
    
    private let separator2: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.text = "Time"
        l.font = .systemFont(ofSize: 17)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let timePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .time
        p.preferredDatePickerStyle = .compact
        p.translatesAutoresizingMaskIntoConstraints = false
        return p
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        setupNavBar()
        setupUI()
        setupListeners()
        fetchAllPatients()
    }
    
    private func setupNavBar() {
        self.title = "New Appointment"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )
        navigationItem.leftBarButtonItem?.tintColor = .systemGray
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "checkmark.circle.fill"),
            style: .done,
            target: self,
            action: #selector(didTapSave)
        )
        navigationItem.rightBarButtonItem?.tintColor = .systemBlue
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mainStack)
        
        // Assemble Input Container
        inputContainer.addSubview(titleTextField)
        inputContainer.addSubview(separator1)
        inputContainer.addSubview(patientIdField)
        
        // Assemble Date Time Container
        dateTimeContainer.addSubview(dateLabel)
        dateTimeContainer.addSubview(datePicker)
        dateTimeContainer.addSubview(separator2)
        dateTimeContainer.addSubview(timeLabel)
        dateTimeContainer.addSubview(timePicker)
        
        mainStack.addArrangedSubview(inputContainer)
        mainStack.addArrangedSubview(statusLabel)
        mainStack.addArrangedSubview(dateTimeContainer)
        
        // Add suggestion table on top of everything
        view.addSubview(suggestionTableView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Input Container Constraints
            inputContainer.heightAnchor.constraint(equalToConstant: 110),
            titleTextField.topAnchor.constraint(equalTo: inputContainer.topAnchor),
            titleTextField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 20),
            titleTextField.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -20),
            titleTextField.heightAnchor.constraint(equalToConstant: 55),
            
            separator1.topAnchor.constraint(equalTo: titleTextField.bottomAnchor),
            separator1.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 20),
            separator1.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor),
            separator1.heightAnchor.constraint(equalToConstant: 0.5),
            
            patientIdField.topAnchor.constraint(equalTo: separator1.bottomAnchor),
            patientIdField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 20),
            patientIdField.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -20),
            patientIdField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor),
            
            // Suggestion Table Constraints (Floating below patient ID field)
            suggestionTableView.topAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: 5),
            suggestionTableView.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            suggestionTableView.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),
            suggestionTableView.heightAnchor.constraint(equalToConstant: 200),
            
            // Date Time Container Constraints
            dateLabel.topAnchor.constraint(equalTo: dateTimeContainer.topAnchor, constant: 15),
            dateLabel.leadingAnchor.constraint(equalTo: dateTimeContainer.leadingAnchor, constant: 20),
            dateLabel.centerYAnchor.constraint(equalTo: datePicker.centerYAnchor),
            
            datePicker.trailingAnchor.constraint(equalTo: dateTimeContainer.trailingAnchor, constant: -20),
            
            separator2.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 15),
            separator2.leadingAnchor.constraint(equalTo: dateTimeContainer.leadingAnchor, constant: 20),
            separator2.trailingAnchor.constraint(equalTo: dateTimeContainer.trailingAnchor),
            separator2.heightAnchor.constraint(equalToConstant: 0.5),
            
            timeLabel.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: 15),
            timeLabel.leadingAnchor.constraint(equalTo: dateTimeContainer.leadingAnchor, constant: 20),
            timeLabel.centerYAnchor.constraint(equalTo: timePicker.centerYAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: dateTimeContainer.bottomAnchor, constant: -15),
            
            timePicker.trailingAnchor.constraint(equalTo: dateTimeContainer.trailingAnchor, constant: -20),
        ])
    }
    
    private func setupListeners() {
        patientIdField.delegate = self
        patientIdField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        titleTextField.delegate = self
        
        suggestionTableView.delegate = self
        suggestionTableView.dataSource = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
        suggestionTableView.isHidden = true
    }
    
    // MARK: - Logic
    private func fetchAllPatients() {
        Task {
            do {
                let user = try await supabase.auth.user()
                let therapistID = user.id
                
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
                print("⚠️ AddReminder: Failed to fetch patients: \(error)")
            }
        }
    }
    
    @objc private func textFieldDidChange(_ tf: UITextField) {
        let query = tf.text?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
        
        if query.isEmpty {
            linkedPatientUUID = nil
            linkedParentUUID = nil
            statusLabel.text = "Search Patient Name or ID"
            statusLabel.textColor = .systemGray
            filteredPatients = []
            suggestionTableView.isHidden = true
            return
        }
        
        filteredPatients = allPatients.filter {
            $0.fullName.lowercased().contains(query) ||
            $0.patient_id_number.lowercased().contains(query)
        }
        
        suggestionTableView.reloadData()
        suggestionTableView.isHidden = filteredPatients.isEmpty
        
        linkedPatientUUID = nil
        linkedParentUUID = nil
        statusLabel.text = filteredPatients.isEmpty ? "No patients found" : "Select a patient from the list"
        statusLabel.textColor = filteredPatients.isEmpty ? .systemRed : .systemOrange
    }
    
    @objc private func didTapSave() {
        guard let title = titleTextField.text?.trimmingCharacters(in: .whitespaces), !title.isEmpty else {
            showAlert(message: "Please enter an appointment title")
            return
        }
        guard let patientID = linkedPatientUUID else {
            showAlert(message: "Please select a patient from the suggestions.")
            return
        }
        
        let date = datePicker.date
        let time = timePicker.date
        let calendar = Calendar.current
        let timeComp = calendar.dateComponents([.hour, .minute], from: time)
        let finalDate = calendar.date(bySettingHour: timeComp.hour ?? 0, minute: timeComp.minute ?? 0, second: 0, of: date) ?? date
        
        if finalDate < Date() {
            showAlert(message: "Appointments cannot be scheduled in the past.")
            return
        }
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        view.isUserInteractionEnabled = false
        
        Task {
            do {
                let user = try await supabase.auth.user()
                let therapistID = user.id
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
                await MainActor.run {
                    self.view.isUserInteractionEnabled = true
                    self.setupNavBar() // Reset nav bar
                    self.showAlert(message: "Failed to save: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc func didTapCancel() {
        dismiss(animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Therasync", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - TableView (Suggestions)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredPatients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let patient = filteredPatients[indexPath.row]
        cell.textLabel?.text = "\(patient.fullName) (\(patient.patient_id_number))"
        cell.textLabel?.font = .systemFont(ofSize: 15)
        cell.imageView?.image = UIImage(systemName: "person.circle")
        cell.imageView?.tintColor = .systemBlue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = filteredPatients[indexPath.row]
        
        patientIdField.text = "\(selected.fullName) (\(selected.patient_id_number))"
        linkedPatientUUID = selected.id
        linkedParentUUID = selected.parent_uid
        
        if selected.parent_uid != nil {
            statusLabel.text = "Patient confirmed"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "Selected \(selected.fullName), but no parent is linked yet."
            statusLabel.textColor = .systemOrange
        }
        
        suggestionTableView.isHidden = true
        view.endEditing(true)
    }
    
    // MARK: - TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == patientIdField && !filteredPatients.isEmpty {
            // Auto-select first suggestion if any
            let selected = filteredPatients[0]
            patientIdField.text = "\(selected.fullName) (\(selected.patient_id_number))"
            linkedPatientUUID = selected.id
            linkedParentUUID = selected.parent_uid
            suggestionTableView.isHidden = true
        }
        return true
    }
}
