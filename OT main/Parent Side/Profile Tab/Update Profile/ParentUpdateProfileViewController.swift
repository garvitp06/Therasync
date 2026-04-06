import UIKit
import Supabase
class ParentUpdateProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Data Input
    var patient: Patient?
    // MARK: - Init
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    // MARK: - UI Components
    private let backgroundView: ParentGradientView = {
        let v = ParentGradientView()
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
        iv.layer.borderColor = UIColor.systemBackground.cgColor
        return iv
    }()
    private let changePhotoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Change Photo", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        return btn
    }()
    // MARK: - Text Fields
    private lazy var nameField       = makeField(placeholder: "Name")
    private lazy var genderField     = makeField(placeholder: "Gender")
    private lazy var bloodGroupField = makeField(placeholder: "Blood Group")
    private lazy var phoneField      = makeField(placeholder: "Parent Contact", isNumber: true)
    // MARK: - Cards
    private lazy var nameCard: UIView = {
        return createCard(rows: [
            ("Name", nameField),
        ])
    }()
    private lazy var detailsCard: UIView = {
        return createCard(rows: [
            ("Gender",      genderField),
            ("Blood Group", bloodGroupField),
        ])
    }()
    private lazy var contactCard: UIView = {
        return createCard(rows: [
            ("Contact", phoneField),
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
        s.color = .darkGray
        s.hidesWhenStopped = true
        return s
    }()
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
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
        populateData()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        let isDark = UserDefaults.standard.bool(forKey: "Dark Mode")
        let color: UIColor = isDark ? .white : .black
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: color]
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = color
    }
    deinit { NotificationCenter.default.removeObserver(self) }
    // MARK: - Populate Data
    private func populateData() {
        guard let patient = patient else { return }
        nameField.text       = patient.fullName
        genderField.text     = patient.gender
        bloodGroupField.text = patient.bloodGroup
        phoneField.text      = patient.parentContact
    }
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
    // MARK: - Save
    @objc private func handleSave() {
        guard let patient = patient,
              let updatedName = nameField.text, !updatedName.isEmpty,
              let updatedGender = genderField.text, !updatedGender.isEmpty,
              let updatedBlood = bloodGroupField.text, !updatedBlood.isEmpty,
              let updatedPhone = phoneField.text, !updatedPhone.isEmpty else {
            return
        }
        let nameComponents = updatedName.components(separatedBy: " ")
        let firstName = nameComponents.first ?? ""
        let lastName = nameComponents.count > 1 ? nameComponents.last! : ""
        setNavBarSaving(true)
        Task {
            do {
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
                await MainActor.run {
                    self.setNavBarSaving(false)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    let alert = UIAlertController(title: "Success", message: "Profile updated successfully.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.setNavBarSaving(false)
                    let errorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
                    self.present(errorAlert, animated: true)
                }
            }
        }
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
        cardsStackView.addArrangedSubview(detailsCard)
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
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let img = info[.editedImage] as? UIImage { profileImageView.image = img }
        dismiss(animated: true)
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
        scrollView.contentInset         = insets
        scrollView.scrollIndicatorInsets = insets
    }
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset         = .zero
        scrollView.scrollIndicatorInsets = .zero
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
