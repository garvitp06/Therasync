import UIKit
import Supabase
import PhotosUI

struct OTProfileUpdatePayloads: Encodable {
    let first_name: String
    let last_name: String
    let contact_no: String
    let aiota_number: String
    let degree: String
    let experience: String
    var avatar_url: String? = nil
}

class UpdateProfileViewController: UIViewController, PHPickerViewControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Properties
    private var hasChangedPhoto = false
    // MARK: - Init
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    // MARK: - UI Components
    private let backgroundView: GradientView = {
        let v = GradientView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .interactive
        return sv
    }()
    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.contentMode = .scaleAspectFill
        iv.tintColor = .white.withAlphaComponent(0.8)
        iv.layer.cornerRadius = 50
        iv.layer.masksToBounds = true
        iv.layer.borderWidth = 3
        iv.layer.borderColor = UIColor.white.cgColor
        return iv
    }()
    private let changePhotoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Change Photo", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        return btn
    }()
    // MARK: - Text Fields (right-aligned values)
    private lazy var firstNameField   = makeField(placeholder: "First Name")
    private lazy var lastNameField    = makeField(placeholder: "Last Name")
    private lazy var aiotaField       = makeField(placeholder: "AIOTA Number", isNumber: true)
    private lazy var degreeField      = makeField(placeholder: "e.g. BOT")
    private lazy var experienceField  = makeField(placeholder: "Years")
    private lazy var contactField     = makeField(placeholder: "Contact Number", isNumber: true)
    // MARK: - Cards (built from label+field rows)
    private lazy var nameCard: UIView = {
        return createCard(rows: [
            ("First Name", firstNameField),
            ("Last Name",  lastNameField),
        ])
    }()
    private lazy var professionalCard: UIView = {
        return createCard(rows: [
            ("AIOTA Number", aiotaField),
            ("Degree",     degreeField),
            ("Experience", experienceField),
        ])
    }()
    private lazy var contactCard: UIView = {
        return createCard(rows: [
            ("Contact", contactField),
        ])
    }()
    private let cardsStackView: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.spacing = 20
        return s
    }()
    // MARK: - Nav Bar Items
    private lazy var saveBarButton = UIBarButtonItem(
        title: "Save",
        style: .done,
        target: self,
        action: #selector(handleSave)
    )
    private let navSpinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.color = .white
        s.hidesWhenStopped = true
        return s
    }()
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        navigationItem.largeTitleDisplayMode = .always
        applyWhiteNavBar()
        navigationItem.rightBarButtonItem = saveBarButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain, target: self, action: #selector(didTapBack)
        )
        setupUI()
        setupConstraints()
        setupActions()
        setupKeyboardHandling()
        setupTapToDismiss()
        fetchProfileData()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        applyWhiteNavBar()
    }

    private func applyWhiteNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance    = appearance
        navigationController?.navigationBar.tintColor = .white
    }
    deinit { NotificationCenter.default.removeObserver(self) }
    // MARK: - Nav Bar Saving State
    private func setNavBarSaving(_ saving: Bool) {
        if saving {
            navSpinner.startAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navSpinner)
        } else {
            navSpinner.stopAnimating()
            navigationItem.rightBarButtonItem = saveBarButton
        }
        navigationController?.interactivePopGestureRecognizer?.isEnabled = !saving
    }
    // MARK: - Database
    private func fetchProfileData() {
        guard let user = supabase.auth.currentUser else { return }
        setNavBarSaving(true)
        Task {
            do {
                let profile: OTProfileDetails = try await supabase
                    .from("profiles").select()
                    .eq("id", value: user.id)
                    .single().execute().value
                await MainActor.run {
                    self.firstNameField.text  = profile.first_name
                    self.lastNameField.text   = profile.last_name
                    self.contactField.text    = profile.contact_no
                    self.aiotaField.text      = profile.aiota_number
                    self.degreeField.text     = profile.degree
                    self.experienceField.text = profile.experience
                    self.setNavBarSaving(false)
                }
            } catch {
                print("Profile load error: \(error)")
                await MainActor.run { self.setNavBarSaving(false) }
            }
        }
    }
    @objc private func handleSave() {
        guard let user = supabase.auth.currentUser else { return }
        setNavBarSaving(true)
        Task {
            do {
                var finalImageURL: String? = nil
                if hasChangedPhoto,
                   let img = profileImageView.image,
                   let data = img.jpegData(compressionQuality: 0.5) {
                    let filePath = "ot_profiles/\(user.id.uuidString)_profile.jpg"
                    
                    // Supabase correctly requires contentType or it throws "schema validation error" popup
                    let fileOptions = FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: true)
                    
                    _ = try await supabase.storage
                        .from("patient-photos")
                        .upload(path: filePath, file: data, options: fileOptions)
                        
                    finalImageURL = try supabase.storage
                        .from("patient-photos")
                        .getPublicURL(path: filePath).absoluteString
                }
                let payload = OTProfileUpdatePayloads(
                    first_name:   firstNameField.text  ?? "",
                    last_name:    lastNameField.text   ?? "",
                    contact_no:   contactField.text    ?? "",
                    aiota_number: aiotaField.text      ?? "",
                    degree:       degreeField.text     ?? "",
                    experience:   experienceField.text ?? "",
                    avatar_url:   finalImageURL
                )
                try await supabase.from("profiles").update(payload)
                    .eq("id", value: user.id).execute()
                await MainActor.run {
                    self.setNavBarSaving(false)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    let alert = UIAlertController(
                        title: "Success",
                        message: "Your profile has been updated successfully.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                }
            } catch {
                print("Update Error: \(error)")
                await MainActor.run {
                    self.setNavBarSaving(false)
                    self.showAlert(message: "Failed to update profile: \(error.localizedDescription)")
                }
            }
        }
    }
    private func showAlert(message: String) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
    // MARK: - Setup UI
    private func setupUI() {
        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(profileImageView)
        contentView.addSubview(changePhotoButton)
        contentView.addSubview(cardsStackView)
        cardsStackView.addArrangedSubview(nameCard)
        cardsStackView.addArrangedSubview(professionalCard)
        cardsStackView.addArrangedSubview(contactCard)
    }
    private func setupActions() {
        changePhotoButton.addTarget(self, action: #selector(handleChangePhoto), for: .touchUpInside)
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleChangePhoto))
        )
    }
    @objc private func didTapBack() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    @objc private func handleChangePhoto() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - PHPickerViewControllerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                    self?.hasChangedPhoto = true
                }
            }
        }
    }
    // MARK: - Keyboard
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    private func setupTapToDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc private func dismissKeyboard() { view.endEditing(true) }
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let insets = UIEdgeInsets(top: 0, left: 0,
                                  bottom: frame.cgRectValue.height - view.safeAreaInsets.bottom + 20,
                                  right: 0)
        scrollView.contentInset          = insets
        scrollView.scrollIndicatorInsets  = insets
    }
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset          = .zero
        scrollView.scrollIndicatorInsets  = .zero
    }
    // MARK: - Constraints
    private func setupConstraints() {
        let cg = scrollView.contentLayoutGuide
        let fg = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: cg.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: cg.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: cg.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: cg.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: fg.widthAnchor),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            changePhotoButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            changePhotoButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cardsStackView.topAnchor.constraint(equalTo: changePhotoButton.bottomAnchor, constant: 28),
            cardsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
        ])
    }
    // MARK: - Factory: Text Field
    private func makeField(placeholder: String, isNumber: Bool = false) -> UITextField {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.tertiaryLabel]
        )
        tf.backgroundColor  = .clear
        tf.font             = .systemFont(ofSize: 16)
        tf.textColor        = .secondaryLabel
        tf.textAlignment    = .right
        if isNumber { tf.keyboardType = .phonePad }
        return tf
    }
    // MARK: - Factory: Card with labelled rows
    /// Creates a white rounded card containing rows of (left label + right text field)
    private func createCard(rows: [(String, UITextField)]) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 20
        card.layer.masksToBounds = true
        var previousBottom = card.topAnchor
        for (index, (labelText, field)) in rows.enumerated() {
            let row = makeRow(labelText: labelText, field: field)
            card.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: previousBottom),
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                row.heightAnchor.constraint(equalToConstant: 52),
            ])
            if index == rows.count - 1 {
                row.bottomAnchor.constraint(equalTo: card.bottomAnchor).isActive = true
            } else {
                let sep = UIView()
                sep.translatesAutoresizingMaskIntoConstraints = false
                sep.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
                card.addSubview(sep)
                NSLayoutConstraint.activate([
                    sep.topAnchor.constraint(equalTo: row.bottomAnchor),
                    sep.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
                    sep.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                    sep.heightAnchor.constraint(equalToConstant: 0.5),
                ])
            }
            previousBottom = row.bottomAnchor
        }
        return card
    }
    // MARK: - Factory: Single Row (label + field)
    private func makeRow(labelText: String, field: UITextField) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = labelText
        lbl.font = .systemFont(ofSize: 16, weight: .medium)
        lbl.textColor = .label
        lbl.setContentHuggingPriority(.required, for: .horizontal)
        lbl.setContentCompressionResistancePriority(.required, for: .horizontal)
        field.textAlignment = .right
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addSubview(lbl)
        row.addSubview(field)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            field.leadingAnchor.constraint(equalTo: lbl.trailingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -20),
            field.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])
        return row
    }
}
