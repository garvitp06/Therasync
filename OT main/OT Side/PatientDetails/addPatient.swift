import UIKit
import PhotosUI
import Supabase

protocol addPatientDelegate: AnyObject {
    func didAddPatient(_ patient: Patient)
}

class addPatient: UIViewController {

    // MARK: - Properties
    weak var delegate: addPatientDelegate?
    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    private let validBloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    private let genderPickerView = UIPickerView()
    private var selectedImage: UIImage?

    // MARK: - UI Components
    private let customNavBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Patient"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = .black
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 20
        btn.translatesAutoresizingMaskIntoConstraints = false
        // Shadow for the button
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.1
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        return btn
    }()

    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "checkmark"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 20
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // FIXED: Perfectly circular profile image
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = .systemGray4
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 60 // Half of 120
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = .white
        return iv
    }()

    // TextFields
    private let firstNameTextField = addPatient.makeTransparentField(placeholder: "First Name")
    private let lastNameTextField = addPatient.makeTransparentField(placeholder: "Last Name")
    private let genderTextField = addPatient.makeTransparentField(placeholder: "Gender")
    private let bloodGroupTextField = addPatient.makeTransparentField(placeholder: "Blood Group")
    private let addressTextField = addPatient.makeTransparentField(placeholder: "Address")
    private let parentNameTextField = addPatient.makeTransparentField(placeholder: "Parent's Name")
    private let parentContactTextField = addPatient.makeTransparentField(placeholder: "Parent Contact", keyboard: .numberPad)
    private let referredByTextField = addPatient.makeTransparentField(placeholder: "Referred By")
    private let existingDiagnosisTextField = addPatient.makeTransparentField(placeholder: "Existing Diagnosis")
    private let existingMedicationTextField = addPatient.makeTransparentField(placeholder: "Existing Medication")

    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .compact
        return dp
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        setupGenderPicker()
        setupKeyboardObservers()
        datePicker.maximumDate = Date()
        
        let fields: [UITextField] = [
                firstNameTextField, lastNameTextField, genderTextField,
                bloodGroupTextField, addressTextField, parentNameTextField,
                parentContactTextField, referredByTextField, existingDiagnosisTextField,
                existingMedicationTextField
            ]
            
            fields.forEach { tf in
                tf.delegate = self
                tf.returnKeyType = .next
            }
            
            // The last field should show "Done"
            existingMedicationTextField.returnKeyType = .done
            
            // Tap to dismiss keyboard
            let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
    }
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case firstNameTextField:
            lastNameTextField.becomeFirstResponder()
        case lastNameTextField:
            // Skip DOB (Picker) and Gender (Picker) to go to Blood Group
            // or you can set them as first responders if they are text fields
            bloodGroupTextField.becomeFirstResponder()
        case bloodGroupTextField:
            addressTextField.becomeFirstResponder()
        case addressTextField:
            parentNameTextField.becomeFirstResponder()
        case parentNameTextField:
            parentContactTextField.becomeFirstResponder()
        case parentContactTextField:
            referredByTextField.becomeFirstResponder()
        case referredByTextField:
            existingDiagnosisTextField.becomeFirstResponder()
        case existingDiagnosisTextField:
            existingMedicationTextField.becomeFirstResponder()
        case existingMedicationTextField:
            textField.resignFirstResponder()
            didTapSave() // Auto-trigger save on "Done"
        default:
            textField.resignFirstResponder()
        }
        return true
    }
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0)
        
        view.addSubview(customNavBar)
        customNavBar.addSubview(closeButton)
        customNavBar.addSubview(titleLabel)
        customNavBar.addSubview(saveButton)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Cards layout
        let nameCard = addPatient.makeCard(fields: [firstNameTextField, lastNameTextField])
        
        let dobLabel = UILabel()
        dobLabel.text = "DOB"
        dobLabel.font = .systemFont(ofSize: 16, weight: .medium)
        let dobRow = UIStackView(arrangedSubviews: [dobLabel, datePicker])
        dobRow.distribution = .equalSpacing
        let dobCard = addPatient.makeCard(fields: [dobRow])
        
        let genderCard = addPatient.makeCard(fields: [genderTextField])
        let infoCard = addPatient.makeCard(fields: [bloodGroupTextField, addressTextField, parentNameTextField, parentContactTextField])
        let medicalCard = addPatient.makeCard(fields: [referredByTextField, existingDiagnosisTextField, existingMedicationTextField])

        let mainStack = UIStackView(arrangedSubviews: [profileImageView, nameCard, dobCard, genderCard, infoCard, medicalCard])
        mainStack.axis = .vertical
        mainStack.alignment = .center // Ensures the profile pic doesn't stretch
        mainStack.spacing = 15
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)
        
        saveButton.addSubview(saveSpinner)
        NSLayoutConstraint.activate([
            saveSpinner.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor),
            saveSpinner.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor)
        ])
        NSLayoutConstraint.activate([
            // Custom Nav Bar
            customNavBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavBar.heightAnchor.constraint(equalToConstant: 60),

            closeButton.leadingAnchor.constraint(equalTo: customNavBar.leadingAnchor, constant: 20),
            closeButton.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerXAnchor.constraint(equalTo: customNavBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor),

            saveButton.trailingAnchor.constraint(equalTo: customNavBar.trailingAnchor, constant: -20),
            saveButton.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 40),
            saveButton.heightAnchor.constraint(equalToConstant: 40),

            // ScrollView
            scrollView.topAnchor.constraint(equalTo: customNavBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // FIXED: Image Constraints (Explicitly 120x120)
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            
            // Cards need to be full width
            nameCard.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            nameCard.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),
            dobCard.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            dobCard.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),
            genderCard.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            genderCard.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),
            infoCard.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            infoCard.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),
            medicalCard.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            medicalCard.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPhoto)))
    }
    private let saveSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white // White to match the button text/icon
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    // MARK: - Handlers
    @objc func didTapSave() {
        // 1. Validate Fields
        guard let fName = validateField(firstNameTextField, fieldName: "First Name"),
              let lName = validateField(lastNameTextField, fieldName: "Last Name"),
              let gender = validateField(genderTextField, fieldName: "Gender"),
              let blood = validateField(bloodGroupTextField, fieldName: "Blood Group")?.uppercased(),
              let addr = validateField(addressTextField, fieldName: "Address"),
              let pName = validateField(parentNameTextField, fieldName: "Parent's Name"),
              let pContact = validateField(parentContactTextField, fieldName: "Parent Contact"),
              let ref = validateField(referredByTextField, fieldName: "Referred By"),
              let diag = validateField(existingDiagnosisTextField, fieldName: "Diagnosis"),
              let med = validateField(existingMedicationTextField, fieldName: "Medication")
        else { return }

        // basic validation
        if !validBloodGroups.contains(blood) {
            showAlert(title: "Invalid Input", message: "Invalid Blood Group")
            return
        }
        
        // 2. Start Loading State
        setLoading(true)

        let randomID = String(format: "%05d", Int.random(in: 10000...99999))
        
        Task {
            do {
                var finalImageURL: String? = nil
                
                // --- STEP A: UPLOAD TO STORAGE ---
                if let img = selectedImage, let data = img.jpegData(compressionQuality: 0.5) {
                    let fileName = "\(UUID().uuidString).jpg"
                    let filePath = "profiles/\(fileName)"
                    
                    // Upload to 'patient-photos' bucket
                    try await supabase.storage
                        .from("patient-photos")
                        .upload(path: filePath, file: data, options: .init(contentType: "image/jpeg"))
                    
                    // Get Public URL
                    let publicURL = try supabase.storage
                        .from("patient-photos")
                        .getPublicURL(path: filePath)
                    
                    finalImageURL = publicURL.absoluteString
                }

                // --- STEP B: SAVE TO DATABASE ---
                let patient = Patient(
                    firstName: fName,
                    lastName: lName,
                    gender: gender,
                    dateOfBirth: datePicker.date,
                    bloodGroup: blood,
                    address: addr,
                    parentName: pName,
                    parentContact: pContact,
                    referredBy: ref,
                    diagnosis: diag,
                    medication: med,
                    profileImage: nil, // Note: We don't store binary in DB
                    imageURL: finalImageURL,
                    parentID: nil,
                    patientID: randomID
                )
                
                try await supabase.from("patients").insert(patient).execute()
                
                await MainActor.run {
                    self.setLoading(false)
                    self.delegate?.didAddPatient(patient)
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showAlert(title: "Upload Failed", message: error.localizedDescription)
                    print("❌ Supabase Error: \(error)")
                }
            }
        }
    }
    // Helper to toggle button state
    private func setLoading(_ isLoading: Bool) {
        if isLoading {
            saveSpinner.startAnimating()
            saveButton.setImage(nil, for: .normal) // Hide checkmark
            saveButton.isEnabled = false // Prevent double tap
        } else {
            saveSpinner.stopAnimating()
            saveButton.setImage(UIImage(systemName: "checkmark"), for: .normal) // Show checkmark
            saveButton.isEnabled = true
        }
    }

    @objc private func pickerDoneTapped() {
        if genderTextField.text?.isEmpty ?? true {
            genderTextField.text = genderOptions[genderPickerView.selectedRow(inComponent: 0)]
        }
        view.endEditing(true)
    }

    private func validateField(_ tf: UITextField, fieldName: String) -> String? {
        guard let text = tf.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Missing Info", message: "Enter \(fieldName)")
            return nil
        }
        return text
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func didTapPhoto() {
        var config = PHPickerConfiguration(); config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func didTapClose() { dismiss(animated: true) }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbChange), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func kbChange(n: NSNotification) {
        if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: frame.cgRectValue.height, right: 0)
        }
    }
    @objc private func kbHide() { scrollView.contentInset = .zero }
}

// MARK: - Delegates
extension addPatient: PHPickerViewControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        results.first?.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] img, _ in
            DispatchQueue.main.async { if let i = img as? UIImage { self?.profileImageView.image = i; self?.selectedImage = i } }
        }
    }

    func setupGenderPicker() {
        genderTextField.inputView = genderPickerView
        genderPickerView.delegate = self
        genderPickerView.dataSource = self
        let tool = UIToolbar(); tool.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(pickerDoneTapped))
        tool.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), done], animated: false)
        genderTextField.inputAccessoryView = tool
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { genderOptions.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { genderOptions[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) { genderTextField.text = genderOptions[row] }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool { return textField != genderTextField }
}

// MARK: - Static Styling Helpers
extension addPatient {
    static func makeTransparentField(placeholder: String, keyboard: UIKeyboardType = .default) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.keyboardType = keyboard
        tf.backgroundColor = .clear
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 45).isActive = true
        return tf
    }

    static func makeCard(fields: [UIView]) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 22
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView(arrangedSubviews: [])
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        for (index, field) in fields.enumerated() {
            stack.addArrangedSubview(field)
            if index < fields.count - 1 {
                let line = UIView()
                line.backgroundColor = UIColor.systemGray5
                line.translatesAutoresizingMaskIntoConstraints = false
                line.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stack.addArrangedSubview(line)
            }
        }
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8)
        ])
        return card
    }
}
