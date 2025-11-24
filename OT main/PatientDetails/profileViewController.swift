import UIKit

class ProfileViewController: UIViewController {
    
    // MARK: - Data Variables
    var patientData: Patient?
    
    // MARK: - UI Elements
    
    let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.circle.fill") // Placeholder
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
    // We use 'lazy var' and the static helper function you created
    
    lazy var firstNameField = ProfileViewController.createFormField(placeholder: "First Name")
    lazy var lastNameField = ProfileViewController.createFormField(placeholder: "Last Name")
    
    lazy var genderField = ProfileViewController.createFormField(placeholder: "Gender")
    lazy var bloodGroupField = ProfileViewController.createFormField(placeholder: "Blood Group")
    lazy var addressField = ProfileViewController.createFormField(placeholder: "Address")
    lazy var parentNameField = ProfileViewController.createFormField(placeholder: "Parent's Name")
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
        picker.isUserInteractionEnabled = false // Read only for profile
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
    // Must be lazy var so they can access the fields above
    lazy var nameCard: UIView = createCardView(with: [firstNameField, lastNameField])
    lazy var dobCard: UIView = createCardView(with: [dobStack, genderField])
    lazy var contactCard: UIView = createCardView(with: [bloodGroupField, addressField, parentNameField, parentContactField])
    lazy var medicalCard: UIView = createCardView(with: [referredByField, existingDiagnosisField, existingMedicationField])

    // MARK: - View Lifecycle
    
    override func loadView() {
        // Keep your gradient background
        self.view = GradientView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHierarchy()
        setupLayout()
        setupNavigationBar() // Your specific nav bar code
        
        // Populate data immediately
        populateData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Data Population
    
    func populateData() {
        guard let patient = patientData else { return }
        
        // 1. Header
        nameLabel.text = patient.fullName
        
        // 2. Fields
        firstNameField.text = patient.firstName
        lastNameField.text = patient.lastName
        
        dobPicker.date = patient.dateOfBirth
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
    
    // --- YOUR CUSTOM NAV BAR CODE ---
    func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
        
        // Create Actions for the Menu
        let notesAction = UIAction(title: "Notes", image: nil) { [weak self] _ in
            let noteVC = noteDetail()
            noteVC.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(noteVC, animated: true)
        }
        let assessmentAction = UIAction(title: "Assessment", image: nil) { [weak self] _ in
            let assessmentVC = AssessmentListViewController()
            assessmentVC.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(assessmentVC, animated: true)
        }
        let assignmentAction = UIAction(title: "Assignment", image: nil) { [weak self] _ in
            let assignmentVC = AssignmentListViewController()
            assignmentVC.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(assignmentVC, animated: true)
        }
        let progressAction = UIAction(title: "Progress", image: nil) { _ in print("Progress selected") }
        let editAction = UIAction(title: "Edit", image: nil) { _ in print("Edit selected") }
        
        // Create the Menu
        let mainMenu = UIMenu(title: "", children: [notesAction, assessmentAction, assignmentAction, progressAction, editAction])
        
        // Create More Button and assign the menu
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: mainMenu)
    }
    
    @objc func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helpers
    
    static func createFormField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .black // Ensure text is black
        textField.borderStyle = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
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
