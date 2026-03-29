import UIKit
import Supabase

class ParentUpdateProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Data Input
    var patient: Patient? // Passed from Profile screen

    // MARK: - Init
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UI Components
    private let backgroundView = ParentGradientView()
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.keyboardDismissMode = .interactive
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 60
        iv.layer.masksToBounds = true
        iv.layer.borderWidth = 4
        iv.layer.borderColor = UIColor.white.cgColor
        iv.backgroundColor = .systemGray6
        return iv
    }()
    
    private let changePhotoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Change Photo", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        return btn
    }()

    // TextFields initialized empty to be filled by database data
    private lazy var nameField = createTextField(value: "", placeholder: "Name")
    private lazy var genderField = createTextField(value: "", placeholder: "Gender")
    private lazy var bloodGroupField = createTextField(value: "", placeholder: "Blood Group")
    private lazy var phoneField = createTextField(value: "", placeholder: "Parent Contact")

    private let formStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 15
        stack.distribution = .fillEqually
        return stack
    }()

    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Save Changes", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 25
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        populateData() // Fill fields from Database
    }
    
    private func populateData() {
        guard let patient = patient else { return }
        nameField.text = patient.fullName
        genderField.text = patient.gender
        bloodGroupField.text = patient.bloodGroup
        phoneField.text = patient.parentContact
        
        // Handle image loading from imageURL here if needed
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        setupNavBar()
    }

    private func setupNavBar() {
        self.title = "Edit Profile"
        navigationController?.navigationBar.prefersLargeTitles = false
        let isDark = UserDefaults.standard.bool(forKey: "Dark Mode")
        let color: UIColor = isDark ? .white : .black
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: color]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        let backBtn = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(didTapBack))
        backBtn.tintColor = color
        navigationItem.leftBarButtonItem = backBtn
    }

    private func setupUI() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(profileImageView)
        contentView.addSubview(changePhotoButton)
        contentView.addSubview(formStackView)
        contentView.addSubview(saveButton)
        [nameField, genderField, bloodGroupField, phoneField].forEach { formStackView.addArrangedSubview($0) }
    }

    private func setupConstraints() {
        let contentLayoutGuide = scrollView.contentLayoutGuide
        let frameLayoutGuide = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: frameLayoutGuide.heightAnchor),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 150),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            changePhotoButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            changePhotoButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            formStackView.topAnchor.constraint(equalTo: changePhotoButton.bottomAnchor, constant: 20),
            formStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            formStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.topAnchor.constraint(greaterThanOrEqualTo: formStackView.bottomAnchor, constant: 40),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    private func setupActions() {
        changePhotoButton.addTarget(self, action: #selector(handleChangePhoto), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
    }

    @objc private func didTapBack() { navigationController?.popViewController(animated: true) }

    @objc private func handleChangePhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    @objc private func handleSave() {
        guard let patient = patient,
              let updatedName = nameField.text, !updatedName.isEmpty,
              let updatedGender = genderField.text, !updatedGender.isEmpty,
              let updatedBlood = bloodGroupField.text, !updatedBlood.isEmpty,
              let updatedPhone = phoneField.text, !updatedPhone.isEmpty else {
            return
        }

        // Split full name back into first and last for database consistency
        let nameComponents = updatedName.components(separatedBy: " ")
        let firstName = nameComponents.first ?? ""
        let lastName = nameComponents.count > 1 ? nameComponents.last! : ""

        // Start loading state
        saveButton.isEnabled = false
        saveButton.setTitle("Updating...", for: .normal)

        Task {
            do {
                // Update Supabase using the patient's unique 5-digit ID
                try await supabase
                    .from("patients")
                    .update([
                        "first_name": firstName,
                        "last_name": lastName,
                        "gender": updatedGender,
                        "blood_group": updatedBlood,
                        "parent_contact": updatedPhone
                    ])
                    .eq("patient_id_number", value: patient.patientID)
                    .execute()

                DispatchQueue.main.async {
                    self.saveButton.isEnabled = true
                    self.saveButton.setTitle("Save Changes", for: .normal)
                    
                    let alert = UIAlertController(title: "Success", message: "Profile updated successfully.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        self.didTapBack()
                    }))
                    self.present(alert, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.saveButton.isEnabled = true
                    self.saveButton.setTitle("Save Changes", for: .normal)
                    
                    let errorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let img = info[.editedImage] as? UIImage { profileImageView.image = img }
        dismiss(animated: true)
    }

    private func createTextField(value: String, placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.text = value
        tf.placeholder = placeholder
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 25
        tf.textColor = .black
        tf.heightAnchor.constraint(equalToConstant: 55).isActive = true
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        return tf
    }
}
