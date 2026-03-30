//
//  register.swift
//  OT main
//
//  Created by Garvit Pareek on 14/11/2025.
//
import UIKit
// NOTE: We do NOT import Supabase here anymore, ensuring no "AnyJSON" errors.
class register: UIViewController {
    
    // MARK: - Outlets & Properties
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var gradientBG: segGradientView!
    
    let blueTopColor = UIColor(red: 0.0, green: 122/255, blue: 1.0, alpha: 1.0)
    let whiteColor = UIColor.systemGray5
    let yellowTopColor = UIColor(red: 255/255, green: 166/255, blue: 0/255, alpha: 1.0)
    
    // MARK: - UI Elements
    
    lazy var firstNameField = createUnderlinedTextField(placeholder: "First Name")
    lazy var lastNameField = createUnderlinedTextField(placeholder: "Last Name")
    lazy var contactNoField = createUnderlinedTextField(placeholder: "Contact No.")
    
    lazy var nbcotField = createUnderlinedTextField(placeholder: "AIOTA Number")
    lazy var degreeField = createUnderlinedTextField(placeholder: "Relevant Degree")
    lazy var experienceField = createUnderlinedTextField(placeholder: "Years of Experience")
    
    lazy var emailField: UITextField = {
        let tf = createUnderlinedTextField(placeholder: "Email ID")
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none // Prevents first letter capital
        tf.autocorrectionType = .no
        return tf
    }()
    
    lazy var passwordField: UITextField = {
        let textField = createUnderlinedTextField(placeholder: "New Password")
        textField.isSecureTextEntry = true
        return textField
    }()
    
    lazy var verifyPasswordField: UITextField = {
        let tf = createUnderlinedTextField(placeholder: "Verify Password")
        tf.isSecureTextEntry = true
        
        // Add Eye Button
        let eyeButton = UIButton(type: .system)
        eyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        eyeButton.tintColor = .gray
        eyeButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        eyeButton.addTarget(self, action: #selector(toggleVerifyPasswordVisibility), for: .touchUpInside)
        
        tf.rightView = eyeButton
        tf.rightViewMode = .always
        return tf
    }()
    
    lazy var separatorA = createSeparatorLine()
    lazy var separatorB = createSeparatorLine()
    
    // MARK: - Labels & Button
    
    private func createSectionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor(white: 0.4, alpha: 1.0)
        return label
    }
    
    lazy var basicDetailsLabel: UILabel = createSectionLabel(text: "Basic Details")
    lazy var professionalDetailsLabel: UILabel = createSectionLabel(text: "Professional Details")
    lazy var emailLabel: UILabel = createSectionLabel(text: "Email & Password")
    
    lazy var registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Register", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1.0)
        button.layer.cornerRadius = 28
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return button
    }()
    
    // MARK: - Stack Views & Cards
    
    lazy var basicDetailsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            firstNameField,
            separatorA,
            lastNameField,
            separatorB,
            contactNoField
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    lazy var basicDetailsCard: UIView = {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 35
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }()
    
    lazy var professionalDetailsCard: UIView = {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 35
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }()
    
    lazy var emailCard: UIView = {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 35
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }()
    
    lazy var professionalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            nbcotField,
            createSeparatorLine(),
            degreeField,
            createSeparatorLine(),
            experienceField
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    lazy var emailStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            emailField,
            createSeparatorLine(),
            passwordField,
            createSeparatorLine(),
            verifyPasswordField
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    lazy var mainStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            basicDetailsLabel, basicDetailsCard,
            professionalDetailsLabel, professionalDetailsCard,
            emailLabel, emailCard,
            registerButton
        ])
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()
    
    // MARK: - Scroll View Properties for Keyboard Handling
    // We declare these properties here so we can access them in setupLayout and keyboard methods
    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        // Dismiss keyboard interactively when dragging down
        sv.keyboardDismissMode = .interactive
        return sv
    }()
    
    lazy var contentView: UIView = {
        let cv = UIView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    // MARK: - Lifecycle & Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateBackground(animated: false)
        
        self.title = "Create Account"
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(didTapCustomBack)
        )
        navigationItem.leftBarButtonItem = backButton
        
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        
        // Add subviews to cards
        basicDetailsCard.addSubview(basicDetailsStack)
        professionalDetailsCard.addSubview(professionalStack)
        emailCard.addSubview(emailStack)
        
        // Setup Constraints for inner stack views
        NSLayoutConstraint.activate([
            basicDetailsStack.topAnchor.constraint(equalTo: basicDetailsCard.topAnchor, constant: 20),
            basicDetailsStack.bottomAnchor.constraint(equalTo: basicDetailsCard.bottomAnchor, constant: -20),
            basicDetailsStack.leadingAnchor.constraint(equalTo: basicDetailsCard.leadingAnchor, constant: 20),
            basicDetailsStack.trailingAnchor.constraint(equalTo: basicDetailsCard.trailingAnchor, constant: -20),
            
            professionalStack.topAnchor.constraint(equalTo: professionalDetailsCard.topAnchor, constant: 20),
            professionalStack.bottomAnchor.constraint(equalTo: professionalDetailsCard.bottomAnchor, constant: -20),
            professionalStack.leadingAnchor.constraint(equalTo: professionalDetailsCard.leadingAnchor, constant: 20),
            professionalStack.trailingAnchor.constraint(equalTo: professionalDetailsCard.trailingAnchor, constant: -20),
            
            emailStack.topAnchor.constraint(equalTo: emailCard.topAnchor, constant: 20),
            emailStack.bottomAnchor.constraint(equalTo: emailCard.bottomAnchor, constant: -20),
            emailStack.leadingAnchor.constraint(equalTo: emailCard.leadingAnchor, constant: 20),
            emailStack.trailingAnchor.constraint(equalTo: emailCard.trailingAnchor, constant: -20)
        ])
        
        setupSegmentedControl()
        setupLayout()
        setupCustomSpacing()
        updateFormFields()
        
        // --- ADD KEYBOARD HANDLING ---
        setupKeyboardHandling()
        setupTapToDismiss()
        let fields = [firstNameField, lastNameField, contactNoField,
                          nbcotField, degreeField, experienceField,
                          emailField, passwordField, verifyPasswordField]
            
            fields.forEach { $0.delegate = self }
            
            // Set return key types
            firstNameField.returnKeyType = .next
            lastNameField.returnKeyType = .next
            contactNoField.returnKeyType = .next
            nbcotField.returnKeyType = .next
            degreeField.returnKeyType = .next
            experienceField.returnKeyType = .next
            emailField.returnKeyType = .next
            passwordField.returnKeyType = .next
            verifyPasswordField.returnKeyType = .done
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        updateBackground(animated: false)
    }
    
    // Remove observer when leaving
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Registration Logic
    
    @objc func registerTapped() {
        // 1. Basic Extraction
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let password = passwordField.text ?? ""
        let verify = verifyPasswordField.text ?? ""
        
        // 2. Profile Extraction & Role Logic
        let isTherapist = segmentedControl.selectedSegmentIndex == 0
        let role = isTherapist ? "1" : "0"
        
        let firstName = firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let contactNo = contactNoField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // 3. Validation
        if email.isEmpty || password.isEmpty || verify.isEmpty || firstName.isEmpty || lastName.isEmpty || contactNo.isEmpty {
            showAlert(message: "Please fill in all required fields.")
            return
        }
        
        if password != verify {
            showAlert(message: "Passwords do not match.")
            return
        }
        
        if password.count < 6 {
            showAlert(message: "Password must be at least 6 characters.")
            return
        }
        
        // 4. Create Standard Dictionary
        var userDetails: [String: String] = [
            "role": role,
            "first_name": firstName,
            "last_name": lastName,
            "contact_no": contactNo,
            "aiota_number": "",
            "degree": "",
            "experience": ""
        ]
        
        // 5. Fill Specific Data & Validate
        if isTherapist {
            let nbcot = nbcotField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let degree = degreeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let experience = experienceField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            if nbcot.isEmpty || degree.isEmpty || experience.isEmpty {
                showAlert(message: "Please fill in all professional details.")
                return
            }
            
            userDetails["aiota_number"] = nbcot
            userDetails["degree"] = degree
            userDetails["experience"] = experience
        }
        
        // 6. Call Service
        registerButton.isEnabled = false
        
        Task {
            do {
                try await AuthService.shared.register(
                    email: email,
                    password: password,
                    userFields: userDetails
                )
                
                await MainActor.run {
                    self.registerButton.isEnabled = true
                    
                    // ---> NAVIGATE TO VERIFY SCREEN INSTEAD OF POPPING <---
                    let verifyVC = VerifyAccountViewController()
                    verifyVC.email = email
                    self.navigationController?.pushViewController(verifyVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.registerButton.isEnabled = true
                    if error.localizedDescription.contains("duplicate key") {
                        self.showAlert(message: "This account (Email/Phone) already exists.")
                    } else {
                        self.showAlert(message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    @objc private func toggleVerifyPasswordVisibility(_ sender: UIButton) {
        verifyPasswordField.isSecureTextEntry.toggle()
        let imageName = verifyPasswordField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    func updateFormFields() {
        let isTherapist = segmentedControl.selectedSegmentIndex == 0
        
        UIView.animate(withDuration: 0.3) {
            // 1. Show/Hide Professional Details
            self.professionalDetailsCard.isHidden = !isTherapist
            self.professionalDetailsLabel.isHidden = !isTherapist
            
            // 2. Update placeholders
            self.firstNameField.placeholder = isTherapist ? "First Name" : "Parent First Name"
            self.lastNameField.placeholder = isTherapist ? "Last Name" : "Parent Last Name"
            
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Helper Methods
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        updateBackground(animated: true)
        updateFormFields()
    }
    
    @objc func didTapCustomBack() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func createUnderlinedTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        textField.leftViewMode = .always
        textField.returnKeyType = .next
        return textField
    }
    
    func createSeparatorLine() -> UIView {
        let underlineView = UIView()
        underlineView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        underlineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return underlineView
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Registration", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        segmentedControl.layer.cornerRadius = segmentedControl.bounds.height / 2
        segmentedControl.layer.masksToBounds = true
    }
    
    func updateBackground(animated: Bool) {
        let newTopColor: UIColor = (segmentedControl.selectedSegmentIndex == 0) ? blueTopColor : yellowTopColor
        let titleColor: UIColor = (segmentedControl.selectedSegmentIndex == 0) ? .white : .black
        
        if animated {
            UIView.transition(with: gradientBG, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.gradientBG.topColor = newTopColor
                self.gradientBG.bottomColor = self.whiteColor
                self.updateNavBarAppearance(titleColor: titleColor)
            })
        } else {
            gradientBG.topColor = newTopColor
            gradientBG.bottomColor = whiteColor
            updateNavBarAppearance(titleColor: titleColor)
        }
    }
    
    func updateNavBarAppearance(titleColor: UIColor) {
        guard let navBar = self.navigationController?.navigationBar else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.tintColor = titleColor
    }
    
    func setupSegmentedControl() {
        _ = segmentedControl.backgroundColor ?? UIColor.systemBlue
        let whiteColor = UIColor.white
        let blackColor = UIColor.black
        segmentedControl.setTitleTextAttributes([.foregroundColor: blackColor], for: .normal)
        segmentedControl.setTitleTextAttributes([.foregroundColor: blackColor], for: .selected)
        segmentedControl.layer.borderColor = whiteColor.cgColor
        segmentedControl.layer.borderWidth = 2.0
    }
    
    func setupCustomSpacing() {
        mainStackView.setCustomSpacing(12, after: basicDetailsLabel)
        mainStackView.setCustomSpacing(12, after: professionalDetailsLabel)
        mainStackView.setCustomSpacing(12, after: emailLabel)
        mainStackView.setCustomSpacing(24, after: basicDetailsCard)
        mainStackView.setCustomSpacing(24, after: professionalDetailsCard)
        mainStackView.setCustomSpacing(40, after: emailCard)
    }
    
    func setupLayout() {
        // We add scrollView to the view
        view.addSubview(scrollView)
        // We add contentView to scrollView
        scrollView.addSubview(contentView)
        // We add mainStackView to contentView
        contentView.addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Keyboard Handling & Dismissal
    
    private func setupKeyboardHandling() {
        // Listen for keyboard appearances and disappearances
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupTapToDismiss() {
        // Allows tapping anywhere on the background to dismiss the keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // Important so buttons still work
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardHeight = keyboardFrame.cgRectValue.height
        let bottomSafeArea = view.safeAreaInsets.bottom
        
        // Add padding to the bottom of the scrollView equal to keyboard height
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight - bottomSafeArea + 20, right: 0)
        
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        // Reset padding when keyboard disappears
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
}
// MARK: - UITextFieldDelegate
extension register: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let isTherapist = segmentedControl.selectedSegmentIndex == 0
        
        switch textField {
        case firstNameField:
            lastNameField.becomeFirstResponder()
        case lastNameField:
            contactNoField.becomeFirstResponder()
        case contactNoField:
            if isTherapist {
                nbcotField.becomeFirstResponder()
            } else {
                emailField.becomeFirstResponder()
            }
        case nbcotField:
            degreeField.becomeFirstResponder()
        case degreeField:
            experienceField.becomeFirstResponder()
        case experienceField:
            emailField.becomeFirstResponder()
        case emailField:
            passwordField.becomeFirstResponder()
        case passwordField:
            verifyPasswordField.becomeFirstResponder()
        case verifyPasswordField:
            textField.resignFirstResponder()
            registerTapped() // Auto-trigger registration when "Done" is pressed
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}
