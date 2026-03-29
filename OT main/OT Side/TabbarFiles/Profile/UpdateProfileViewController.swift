import UIKit
import Supabase


struct OTProfileUpdatePayloads: Encodable {
    let first_name: String
    let last_name: String
    let contact_no: String
    let nbcot_number: String
    let degree: String
    let experience: String
    var avatar_url: String? = nil // Optional so it's omitted if nil
}

class UpdateProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Properties
    // We add this to track if the user actually picked a new photo
    private var hasChangedPhoto = false

    // MARK: - Init
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Components
    private let backgroundView: GradientView = {
        let view = GradientView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .interactive
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
        iv.tintColor = .white.withAlphaComponent(0.8)
        iv.layer.cornerRadius = 60
        iv.layer.masksToBounds = true
        iv.layer.borderWidth = 4
        iv.layer.borderColor = UIColor.white.cgColor
        return iv
    }()
    
    private let changePhotoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Change Photo", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        btn.setTitleColor(.black, for: .normal)
        return btn
    }()

    // Inputs
    private lazy var firstNameField = createTextField(value: "", placeholder: "First Name")
    private lazy var lastNameField = createTextField(value: "", placeholder: "Last Name")
    private lazy var nbcotField = createTextField(value: "", placeholder: "NBCOT Number", isNumber: true)
    private lazy var degreeField = createTextField(value: "", placeholder: "Degree (e.g. MSOT)")
    private lazy var experienceField = createTextField(value: "", placeholder: "Experience (e.g. 5 years)")
    private lazy var contactField = createTextField(value: "", placeholder: "Contact Number", isNumber: true)

    // Cards
    private lazy var nameCard: UIView = {
        return createCardContainer(with: [firstNameField, lastNameField])
    }()
    
    private lazy var professionalCard: UIView = {
        return createCardContainer(with: [nbcotField, degreeField, experienceField])
    }()
    
    private lazy var contactCard: UIView = {
        return createCardContainer(with: [contactField])
    }()
    
    private let cardsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.distribution = .fill
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
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.2
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 4
        return btn
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        
        // Setup Keyboard Handling
        setupKeyboardHandling()
        setupTapToDismiss()
        
        fetchProfileData() // Load data
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .black
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Database Logic
    private func fetchProfileData() {
        guard let user = supabase.auth.currentUser else { return }
        
        saveButton.setTitle("", for: .normal)
        activityIndicator.startAnimating()
        
        Task {
            do {
                let profile: OTProfileDetails = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: user.id)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    self.firstNameField.text = profile.first_name
                    self.lastNameField.text = profile.last_name
                    self.contactField.text = profile.contact_no
                    self.nbcotField.text = profile.nbcot_number
                    self.degreeField.text = profile.degree
                    self.experienceField.text = profile.experience
                    
                    self.activityIndicator.stopAnimating()
                    self.saveButton.setTitle("Save Changes", for: .normal)
                }
            } catch {
                print("Error loading profile: \(error)")
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.saveButton.setTitle("Save Changes", for: .normal)
                }
            }
        }
    }
    
    @objc private func handleSave() {
            guard let user = supabase.auth.currentUser else { return }
            
            saveButton.isEnabled = false
            saveButton.setTitle("", for: .normal)
            activityIndicator.startAnimating()
            
            Task {
                do {
                    var finalImageURL: String? = nil
                    
                    // 1. Only upload to storage if the photo was actually changed
                    if hasChangedPhoto, let imageToUpload = profileImageView.image,
                       let data = imageToUpload.jpegData(compressionQuality: 0.5) {
                        
                        let fileName = "\(user.id.uuidString)_profile.jpg"
                        let filePath = "ot_profiles/\(fileName)"
                        
                        // Upload to "patient-photos" bucket
                        _ = try await supabase.storage
                            .from("patient-photos")
                            .upload(path: filePath, file: data, options: .init(upsert: true))
                        
                        // Get public URL
                        let publicURL = try supabase.storage
                            .from("patient-photos")
                            .getPublicURL(path: filePath)
                        
                        finalImageURL = publicURL.absoluteString
                    }
                    
                    // 2. Prepare Payload
                    let updateData = OTProfileUpdatePayloads(
                        first_name: firstNameField.text ?? "",
                        last_name: lastNameField.text ?? "",
                        contact_no: contactField.text ?? "",
                        nbcot_number: nbcotField.text ?? "",
                        degree: degreeField.text ?? "",
                        experience: experienceField.text ?? "",
                        avatar_url: finalImageURL
                    )
                    
                    // 3. Execute Update
                    try await supabase
                        .from("profiles")
                        .update(updateData)
                        .eq("id", value: user.id)
                        .execute()
                    
                    // 4. Success UI & Popup
                    await MainActor.run {
                        self.activityIndicator.stopAnimating()
                        self.saveButton.setTitle("Saved!", for: .normal)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        
                        // Create and show the success popup
                        let alert = UIAlertController(title: "Success", message: "Your profile has been updated successfully.", preferredStyle: .alert)
                        
                        // Add an "OK" button that pops the view controller when tapped
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                            self.navigationController?.popViewController(animated: true)
                        }))
                        
                        self.present(alert, animated: true)
                    }
                } catch {
                    print("Update Error: \(error)")
                    await MainActor.run {
                        self.saveButton.isEnabled = true
                        self.saveButton.setTitle("Save Changes", for: .normal)
                        self.activityIndicator.stopAnimating()
                        self.showAlert(message: "Failed to update profile: \(error.localizedDescription)")
                    }
                }
            }
        }

    // MARK: - Helpers
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Setup UI
    private func setupUI() {
        title = "Edit Profile"
        
        // Back Button Logic
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(didTapBack))

        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)
        
        view.addSubview(scrollView)
        view.addSubview(saveButton)
        saveButton.addSubview(activityIndicator)
        
        scrollView.addSubview(contentView)
        contentView.addSubview(profileImageView)
        contentView.addSubview(changePhotoButton)
        contentView.addSubview(cardsStackView)
        
        cardsStackView.addArrangedSubview(nameCard)
        cardsStackView.addArrangedSubview(professionalCard)
        cardsStackView.addArrangedSubview(contactCard)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        changePhotoButton.addTarget(self, action: #selector(handleChangePhoto), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleChangePhoto))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGesture)
    }

    // Improved Back Button Logic
    @objc private func didTapBack() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func handleChangePhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let img = info[.originalImage] as? UIImage {
            profileImageView.image = img
            hasChangedPhoto = true // Trigger the boolean so handleSave knows to upload it
        }
        dismiss(animated: true)
    }

    // MARK: - Keyboard Handling
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupTapToDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardHeight = keyboardFrame.cgRectValue.height
        let bottomSafeArea = view.safeAreaInsets.bottom
        
        // Add extra padding so the button isn't covered
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight - bottomSafeArea + 80, right: 0)
        
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    // MARK: - Constraints
    private func setupConstraints() {
        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Save Button (Fixed at bottom)
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 55),
            
            // ScrollView (Takes up remaining space)
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -20),
            
            contentView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: frameGuide.widthAnchor),
            
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            changePhotoButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            changePhotoButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            cardsStackView.topAnchor.constraint(equalTo: changePhotoButton.bottomAnchor, constant: 30),
            cardsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Component Helpers
    private func createTextField(value: String, placeholder: String, isNumber: Bool = false) -> UITextField {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.text = value
        tf.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor.systemGray3])
        tf.backgroundColor = .clear
        tf.textColor = .black
        tf.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        if isNumber { tf.keyboardType = .phonePad }
        tf.heightAnchor.constraint(equalToConstant: 55).isActive = true
        return tf
    }
    
    private func createCardContainer(with fields: [UITextField]) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 25
        container.layer.masksToBounds = true
        
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 0
        stack.distribution = .fill
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)
        ])
        
        for (index, field) in fields.enumerated() {
            stack.addArrangedSubview(field)
            if index < fields.count - 1 {
                let sep = UIView()
                sep.backgroundColor = UIColor.systemGray5
                sep.translatesAutoresizingMaskIntoConstraints = false
                sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stack.addArrangedSubview(sep)
            }
        }
        return container
    }
}

