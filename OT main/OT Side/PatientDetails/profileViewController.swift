import UIKit
import PhotosUI
import Supabase

class ProfileViewController: UIViewController, PHPickerViewControllerDelegate {
    weak var updateDelegate: ProfileUpdateDelegate?
    // MARK: - Data Variables
    var patientData: Patient?
    
    var isEditingMode: Bool = false {
        didSet {
            updateUIForEditState()
        }
    }
    
    // MARK: - UI Elements
    
    let profileImageView: UIImageView = {
        let iv = UIImageView()
        // Using a configuration to make the default icon look better
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
        iv.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
        iv.tintColor = .systemGray4
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .white
        iv.clipsToBounds = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 3.0
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Patient Name"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // --- Form Fields ---
    lazy var firstNameField = ProfileViewController.createFormField(placeholder: "First Name")
    lazy var lastNameField = ProfileViewController.createFormField(placeholder: "Last Name")
    
    lazy var genderField = ProfileViewController.createFormField(placeholder: "Gender")
    lazy var bloodGroupField = ProfileViewController.createFormField(placeholder: "Blood Group")
    lazy var addressField = ProfileViewController.createFormField(placeholder: "Address")
    lazy var parentNameField = ProfileViewController.createFormField(placeholder: "Parent's Name")
    
    // This field will remain read-only
    lazy var parentContactField = ProfileViewController.createFormField(placeholder: "Parent Contact")
    
    lazy var referredByField = ProfileViewController.createFormField(placeholder: "Referred By")
    lazy var existingDiagnosisField = ProfileViewController.createFormField(placeholder: "Existing Diagnosis")
    lazy var existingMedicationField = ProfileViewController.createFormField(placeholder: "Existing Medication")
    
    // Date Picker setup
    let dobLabel: UILabel = {
        let label = UILabel()
        label.text = "DOB"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        return label
    }()
    
    let dobPicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.isUserInteractionEnabled = false // Read only by default
        return picker
    }()
    
    lazy var dobStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [dobLabel, dobPicker])
        stack.axis = .horizontal
        stack.distribution = .fillProportionally
        stack.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return stack
    }()
    
    // --- Cards ---
    lazy var nameCard: UIView = createCardView(with: [firstNameField, lastNameField])
    lazy var dobCard: UIView = createCardView(with: [dobStack, genderField])
    lazy var contactCard: UIView = createCardView(with: [bloodGroupField, addressField, parentNameField, parentContactField])
    lazy var medicalCard: UIView = createCardView(with: [referredByField, existingDiagnosisField, existingMedicationField])

    // MARK: - View Lifecycle
    
    override func loadView() {
        // This assumes GradientView exists in your project. If it crashes, change this to: self.view = UIView(); self.view.backgroundColor = .systemBlue
        self.view = GradientView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHierarchy()
        setupLayout()
        setupProfileTap()
        populateData()
        setupDismissKeyboardGesture()
        updateUIForEditState()
        
        let fields = [firstNameField, lastNameField, genderField, bloodGroupField, addressField, parentNameField, referredByField, existingDiagnosisField, existingMedicationField]
        fields.forEach { $0.delegate = self }
        existingMedicationField.returnKeyType = .done
    }
    private func setupDismissKeyboardGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        // This allows buttons and the photo picker to still receive their touch events
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarAppearance()
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ]
        
        // Let large titles inherit system sizing, just enforce white:
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        // This is the critical part to merge:
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only restore tab bar if leaving this profile back to the list
        if self.isMovingFromParent {
            self.tabBarController?.tabBar.isHidden = false
        }
    }
    // MARK: - Edit Mode Logic (UPDATED)
    
    func updateUIForEditState() {
        let editableFields: [UITextField] = [
            firstNameField, lastNameField, genderField, bloodGroupField,
            addressField, parentNameField, referredByField,
            existingDiagnosisField, existingMedicationField
        ]
        
        // Update field visuals based on mode
        for field in editableFields {
            field.isUserInteractionEnabled = isEditingMode
            
            field.backgroundColor = .clear
            field.borderStyle = .none
            
            if isEditingMode {
                field.textColor = .black
            } else {
                field.textColor = .systemGray
            }
        }
        
        // DOB Picker logic
        dobPicker.isUserInteractionEnabled = isEditingMode
        dobPicker.alpha = isEditingMode ? 1.0 : 0.6
        if let id = patientData?.patientID {
                    self.title = "Patient ID: \(id)"
                }
        // Parent Contact ALWAYS read-only
        parentContactField.isUserInteractionEnabled = false
        parentContactField.textColor = .systemGray
        
        profileImageView.isUserInteractionEnabled = isEditingMode
            
            if isEditingMode {
                let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveButtonTapped))
                doneButton.tintColor = .white
                navigationItem.rightBarButtonItem = doneButton
            } else {
                setupNavigationBarMenu()
            }
    }
    
    // MARK: - Photo Picker Logic (From your reference)
    private func setupNavigationBarAppearance() {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 18, weight: .bold)
            ]
            
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
            navigationController?.navigationBar.tintColor = .white
            
            self.tabBarController?.tabBar.isHidden = true
        }
    
    private func setupProfileTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapProfilePic))
        profileImageView.addGestureRecognizer(tap)
    }
    
    @objc private func didTapProfilePic() {
        // Only trigger if in edit mode (extra safety check)
        guard isEditingMode else { return }
        
        var config = PHPickerConfiguration()
        config.filter = .images // Only show images
        config.selectionLimit = 1 // Only allow 1 image
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // Delegate Method
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            DispatchQueue.main.async {
                if let selectedImage = image as? UIImage {
                    self?.profileImageView.image = selectedImage
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc func backTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func saveButtonTapped() {
            guard var updatedPatient = patientData else { return }
            
            // Start loading
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.color = .white
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
            spinner.startAnimating()
            
            // Map UI to struct
            updatedPatient.firstName = firstNameField.text ?? ""
            updatedPatient.lastName = lastNameField.text ?? ""
            updatedPatient.gender = genderField.text ?? ""
            updatedPatient.bloodGroup = bloodGroupField.text ?? ""
            updatedPatient.address = addressField.text ?? ""
            updatedPatient.parentName = parentNameField.text ?? ""
            updatedPatient.referredBy = referredByField.text ?? ""
            updatedPatient.diagnosis = existingDiagnosisField.text ?? ""
            updatedPatient.medication = existingMedicationField.text ?? ""
            updatedPatient.dateOfBirth = dobPicker.date
            
            Task {
                do {
                    // If a NEW image was picked, upload it first
                    if let newImg = self.profileImageView.image, newImg != patientData?.profileImage {
                        if let data = newImg.jpegData(compressionQuality: 0.5) {
                            let path = "profiles/\(UUID().uuidString).jpg"
                            try await supabase.storage.from("patient-photos").upload(path: path, file: data)
                            let publicURL = try supabase.storage.from("patient-photos").getPublicURL(path: path)
                            updatedPatient.imageURL = publicURL.absoluteString
                        }
                    }
                    
                    // Push database update
                    try await supabase.from("patients")
                        .update(updatedPatient)
                        .eq("patient_id_number", value: updatedPatient.patientID)
                        .execute()
                    
                    await MainActor.run {
                        self.patientData = updatedPatient
                        self.nameLabel.text = updatedPatient.fullName
                        self.isEditingMode = false
                        self.updateDelegate?.didUpdatePatient(updatedPatient)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                } catch {
                    await MainActor.run {
                        self.updateUIForEditState() // Restore the Done button
                        self.showAlert(message: "Failed to save: \(error.localizedDescription)")
                    }
                }
            }
        }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    // MARK: - Data Population
    
    func populateData() {
            guard let patient = patientData else { return }
            self.title = "Patient ID: \(patient.patientID)"
            navigationItem.largeTitleDisplayMode = .never
            nameLabel.text = patient.fullName
            
            // 1. Handle Profile Image Loading
            let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
            let defaultPlaceholder = UIImage(systemName: "person.circle.fill", withConfiguration: config)
            
            if let urlString = patient.imageURL {
                profileImageView.loadImage(from: urlString, placeholder: defaultPlaceholder)
                
                /* If using SDWebImage:
                profileImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.circle.fill"))
                */
            } else if let localImage = patient.profileImage {
                profileImageView.image = localImage
            } else {
                let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
                profileImageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
            }
            
            // Populate text fields
            firstNameField.text = patient.firstName
            lastNameField.text = patient.lastName
            if let dob = patient.dateOfBirth { dobPicker.date = dob }
            genderField.text = patient.gender
            bloodGroupField.text = patient.bloodGroup
            addressField.text = patient.address
            parentNameField.text = patient.parentName
            parentContactField.text = patient.parentContact
            referredByField.text = patient.referredBy
            existingDiagnosisField.text = patient.diagnosis
            existingMedicationField.text = patient.medication
        }
    
    // MARK: - Setup Functions
    
    func setupNavigationBarMenu() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
        
        // 1. Notes Action
        let notesAction = UIAction(title: "Notes", image: UIImage(systemName: "note.text")) { [weak self] _ in
            let noteVC = NotesViewController()
            noteVC.patientID = self?.patientData?.patientID
            noteVC.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(noteVC, animated: true)
        }
        
        // 2. Assessment Action
        let assessmentAction = UIAction(title: "Assessment", image: UIImage(systemName: "clipboard")) { [weak self] _ in
            let assessmentVC = AssessmentListViewController()
            assessmentVC.patientID = self?.patientData?.patientID
            assessmentVC.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(assessmentVC, animated: true)
        }
        
        // 3. Assignment Action
        let assignmentAction = UIAction(title: "Assignment", image: UIImage(systemName: "doc.text")) { [weak self] _ in
            let assignmentVC = AssignmentListViewController()
            assignmentVC.patientID = self?.patientData?.patientID
            assignmentVC.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(assignmentVC, animated: true)
        }
        
        // 4. UPDATED: Progress Action
        let progressAction = UIAction(title: "Progress", image: UIImage(systemName: "chart.bar")) { [weak self] _ in
            let progressVC = PatientProgressViewController()
            // Pass the patient object so the progress screen knows who to fetch reports for
            progressVC.patient = self?.patientData
            progressVC.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(progressVC, animated: true)
        }
        
        // 5. Edit Action
        let editAction = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { [weak self] _ in
            self?.isEditingMode = true
        }
        
        // 6. Delete Action
        let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.confirmDeletion()
        }
        
        // 7. Reset Link Action
        let resetLinkAction = UIAction(title: "Reset Parent Link", image: UIImage(systemName: "arrow.triangle.2.circlepath"), attributes: .destructive) { [weak self] _ in
                self?.resetParentLink()
            }
        
        // Combine into Menu
        let mainMenu = UIMenu(title: "", children: [notesAction, assessmentAction, assignmentAction, progressAction, editAction, resetLinkAction, deleteAction])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: mainMenu)
    }
    private func confirmDeletion() {
        let alert = UIAlertController(
            title: "Delete Patient",
            message: "Are you sure you want to permanently delete this patient record?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDelete()
        })
        
        present(alert, animated: true)
    }
    private func resetParentLink() {
            guard let patient = patientData else { return }
            
            Task {
                do {
                    // Clear parent_uid in patients table
                    try await supabase.from("patients")
                        .update(["parent_uid": String?.none])
                        .eq("patient_id_number", value: patient.patientID)
                        .execute()
                    
                    // If we know the old parent, clear their profile too
                    if let parentUID = patient.parentUID {
                        try await supabase.from("profiles")
                            .update(["linked_patient_id": String?.none])
                            .eq("id", value: parentUID)
                            .execute()
                    }
                    
                    await MainActor.run {
                        self.showAlert(message: "Parent link reset. A new parent can now use code \(patient.patientID).")
                        self.backTapped()
                    }
                } catch {
                    print("❌ Reset Link Error: \(error)")
                }
            }
        }
    private func performDelete() {
            guard let patient = patientData else { return }
            
            Task {
                do {
                    // 1. Delete the record from the database
                    try await supabase
                        .from("patients")
                        .delete()
                        .eq("patient_id_number", value: patient.patientID)
                        .execute()
                    
                    // 2. Clear profile link if a parent was attached
                    if let parentUID = patient.parentUID {
                        try await supabase
                            .from("profiles")
                            .update(["linked_patient_id": String?.none])
                            .eq("id", value: parentUID)
                            .execute()
                    }

                    await MainActor.run {
                        // 3. Navigate back to the list
                        self.navigationController?.popViewController(animated: true)
                    }
                } catch {
                    print("❌ Deletion Error: \(error)")
                }
            }
        }
    func setupHierarchy() {
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(nameCard)
        contentView.addSubview(dobCard)
        contentView.addSubview(contactCard)
        contentView.addSubview(medicalCard)
    }
    
    func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scrollView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            nameCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            nameCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            dobCard.topAnchor.constraint(equalTo: nameCard.bottomAnchor, constant: 16),
            dobCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dobCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            contactCard.topAnchor.constraint(equalTo: dobCard.bottomAnchor, constant: 16),
            contactCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contactCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            medicalCard.topAnchor.constraint(equalTo: contactCard.bottomAnchor, constant: 16),
            medicalCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            medicalCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            medicalCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // MARK: - Helpers
    
    static func createFormField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .systemGray
        textField.borderStyle = .none
        textField.isUserInteractionEnabled = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        textField.returnKeyType = .next
        return textField
    }
    
    func createCardView(with fields: [UIView]) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(stackView)
        
        for (index, field) in fields.enumerated() {
            stackView.addArrangedSubview(field)
            if index < fields.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stackView.addArrangedSubview(separator)
            }
        }
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        return card
    }
}

extension ProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case firstNameField: lastNameField.becomeFirstResponder()
        case lastNameField: genderField.becomeFirstResponder()
        case genderField: bloodGroupField.becomeFirstResponder()
        case bloodGroupField: addressField.becomeFirstResponder()
        case addressField: parentNameField.becomeFirstResponder()
        case parentNameField: referredByField.becomeFirstResponder()
        case referredByField: existingDiagnosisField.becomeFirstResponder()
        case existingDiagnosisField: existingMedicationField.becomeFirstResponder()
        default: textField.resignFirstResponder()
        }
        return true
    }
}
