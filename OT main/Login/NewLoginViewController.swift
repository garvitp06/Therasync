import UIKit
import Supabase

class NewLoginViewController: UIViewController {
    
    // MARK: - UI Constants
    private let componentHeight: CGFloat = 48
    private let componentCornerRadius: CGFloat = 24
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "TheraSync"
        label.font = .systemFont(ofSize: 40, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome"
        label.font = .systemFont(ofSize: 28, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "Email"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var emailContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = componentCornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "something@email.com"
        tf.font = .systemFont(ofSize: 15)
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.returnKeyType = .next
        return tf
    }()
    
    private let passwordLabel: UILabel = {
        let label = UILabel()
        label.text = "Password"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var passwordContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = componentCornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var passwordTextField: UITextField = {
        let tf = UITextField()
            tf.placeholder = "********"
            tf.font = .systemFont(ofSize: 15)
            tf.isSecureTextEntry = true
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.returnKeyType = .done
            tf.delegate = self

            tf.textContentType = .oneTimeCode
            tf.passwordRules = nil

        let eyeButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)

        eyeButton.setImage(UIImage(systemName: "eye.slash", withConfiguration: config), for: .normal)
        eyeButton.tintColor = .systemGray
        eyeButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)

        eyeButton.addTarget(self, action: #selector(handlePasswordVisibilityTap), for: .touchUpInside)

        tf.rightView = eyeButton
        tf.rightViewMode = .always

        return tf
    }()

    
    private let passwordVisibilityButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        btn.tintColor = .gray
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let forgotPasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Forgot Password ?", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.contentHorizontalAlignment = .right
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let checkboxButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "square"), for: .normal)
        btn.tintColor = .systemBlue
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let termsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let termsBaseLabel: UILabel = {
        let label = UILabel()
        label.text = "I agree to TheraSync's"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .black
        return label
    }()
    
    private let termsButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Terms & Conditions", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13)
        return btn
    }()
    
    private lazy var loginButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Login", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.layer.cornerRadius = componentCornerRadius
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let orLabel: UILabel = {
        let label = UILabel()
        label.text = "Or"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let leftLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let rightLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var appleButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "applelogo")
        config.imagePadding = 10
        config.baseForegroundColor = .black
        var container = AttributeContainer()
        container.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        config.attributedTitle = AttributedString("Sign in with Apple", attributes: container)
        let btn = UIButton(configuration: config)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = componentCornerRadius
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.black.cgColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private lazy var googleButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.imagePadding = 10
        config.baseForegroundColor = .black
        var container = AttributeContainer()
        container.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        config.attributedTitle = AttributedString("Sign in with Google", attributes: container)
        
        if let originalImage = UIImage(named: "Logo-google-icon-PNG") {
            let targetSize = CGSize(width: 18, height: 18)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let finalImage = renderer.image { _ in
                originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
            }
            config.image = finalImage.withRenderingMode(.alwaysOriginal)
        }
        
        let btn = UIButton(configuration: config)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = componentCornerRadius
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.black.cgColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let createAccountButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Create Account", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // --- NEW: Activity Indicator ---
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white // Visible against the gradient
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    // Logic State
    private var isAgreed = false
    
    // MARK: - Lifecycle
    override func loadView() {
        self.view = GradientView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHierarchy()
        setupConstraints()
        setupActions()
        setupDismissKeyboardGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup
    private func setupDismissKeyboardGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        // This allows buttons to still receive their touch events immediately
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupHierarchy() {
        [titleLabel, welcomeLabel, emailLabel, emailContainer, passwordLabel, passwordContainer,
         forgotPasswordButton, checkboxButton, termsStackView, loginButton, leftLine, orLabel,
         rightLine, appleButton, googleButton, createAccountButton,
         activityIndicator] // Added indicator
        .forEach { view.addSubview($0) }
        
        emailContainer.addSubview(emailTextField)
        passwordContainer.addSubview(passwordTextField)
//        passwordContainer.addSubview(passwordVisibilityButton)
        termsStackView.addArrangedSubview(termsBaseLabel)
        termsStackView.addArrangedSubview(termsButton)
    }
    
    private func setupConstraints() {
        let margin: CGFloat = 24
        let textPadding: CGFloat = 18
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            // Center the Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            
            welcomeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            
            emailLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 40),
            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            
            emailContainer.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8),
            emailContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            emailContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            emailContainer.heightAnchor.constraint(equalToConstant: componentHeight),
            
            emailTextField.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor, constant: textPadding),
            emailTextField.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor, constant: -textPadding),
            emailTextField.centerYAnchor.constraint(equalTo: emailContainer.centerYAnchor),
            
            passwordLabel.topAnchor.constraint(equalTo: emailContainer.bottomAnchor, constant: 20),
            passwordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            
            passwordContainer.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor, constant: 8),
            passwordContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            passwordContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            passwordContainer.heightAnchor.constraint(equalToConstant: componentHeight),
            
//            passwordVisibilityButton.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor, constant: -16),
//            passwordVisibilityButton.centerYAnchor.constraint(equalTo: passwordContainer.centerYAnchor),
//            passwordVisibilityButton.widthAnchor.constraint(equalToConstant: 24),
            
            passwordTextField.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor, constant: textPadding),
            passwordTextField.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor, constant: -18),
            passwordTextField.centerYAnchor.constraint(equalTo: passwordContainer.centerYAnchor),
            
            forgotPasswordButton.topAnchor.constraint(equalTo: passwordContainer.bottomAnchor, constant: 8),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            
            checkboxButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 10),
            checkboxButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            checkboxButton.widthAnchor.constraint(equalToConstant: 24),
            checkboxButton.heightAnchor.constraint(equalToConstant: 24),
            
            termsStackView.centerYAnchor.constraint(equalTo: checkboxButton.centerYAnchor),
            termsStackView.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 10),
            
            loginButton.topAnchor.constraint(equalTo: checkboxButton.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            loginButton.heightAnchor.constraint(equalToConstant: componentHeight),
            
            orLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
            orLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            leftLine.centerYAnchor.constraint(equalTo: orLabel.centerYAnchor),
            leftLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            leftLine.trailingAnchor.constraint(equalTo: orLabel.leadingAnchor, constant: -10),
            leftLine.heightAnchor.constraint(equalToConstant: 1),
            
            rightLine.centerYAnchor.constraint(equalTo: orLabel.centerYAnchor),
            rightLine.leadingAnchor.constraint(equalTo: orLabel.trailingAnchor, constant: 10),
            rightLine.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            rightLine.heightAnchor.constraint(equalToConstant: 1),
            
            appleButton.topAnchor.constraint(equalTo: orLabel.bottomAnchor, constant: 20),
            appleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            appleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            appleButton.heightAnchor.constraint(equalToConstant: componentHeight),
            
            googleButton.topAnchor.constraint(equalTo: appleButton.bottomAnchor, constant: 15),
            googleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            googleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            googleButton.heightAnchor.constraint(equalToConstant: componentHeight),
            
            createAccountButton.topAnchor.constraint(equalTo: googleButton.bottomAnchor, constant: 20),
            createAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createAccountButton.bottomAnchor.constraint(lessThanOrEqualTo: safeArea.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupActions() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        checkboxButton.addTarget(self, action: #selector(handleCheckboxTap), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(handleLoginTap), for: .touchUpInside)
        termsButton.addTarget(self, action: #selector(handleTermsTap), for: .touchUpInside)
        createAccountButton.addTarget(self, action: #selector(handleCreateAccountTap), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(handleForgotPasswordTap), for: .touchUpInside)
//        passwordVisibilityButton.addTarget(self, action: #selector(handlePasswordVisibilityTap), for: .touchUpInside)
    }
    
    // MARK: - Loading State Helper
    private func setLoading(_ loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false // Prevent double clicks
            loginButton.setTitle("", for: .normal) // Hide text for cleaner look
        } else {
            activityIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
            loginButton.setTitle("Login", for: .normal)
        }
    }
    
    // MARK: - Handlers
    @objc private func handleLoginTap() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter both email and password.")
            return
        }
        
        if !isAgreed {
            showAlert(message: "Please agree to the Terms & Conditions.")
            return
        }
        
        // 1. Start Loading
        setLoading(true)
        
        Task {
            do {
                try await AuthService.shared.login(email: email.lowercased(), password: password)
                let role = try await AuthService.shared.fetchUserRole()
                
                await MainActor.run {
                    if role == "1" {
                        // Therapist -> Main Tab
                        self.switchToRoot(MainTabBarController())
                        // Note: We do NOT stop loading here. The view is transitioning.
                    } else if role == "0" {
                        // Parent -> Check Linking logic
                        self.checkParentLinkingAndRoute()
                    } else {
                        // Logic Error: Stop loading
                        self.setLoading(false)
                        self.showAlert(message: "Role not found.")
                    }
                }
            } catch {
                await MainActor.run {
                    // Network/Auth Error: Stop loading
                    self.setLoading(false)
                    self.showAlert(message: "Login failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Route User Logic (Optional: Kept if you use it elsewhere, otherwise checkParentLinkingAndRoute covers it)
    func routeUser() {
        Task {
            do {
                let user = try await supabase.auth.session.user
                let fetched: [Patient] = try await supabase
                    .from("patients")
                    .select()
                    .eq("parent_uid", value: user.id)
                    .execute().value
                
                await MainActor.run {
                    if fetched.isEmpty {
                        self.view.window?.rootViewController = UINavigationController(rootViewController: ParentEmptyStateViewController())
                    } else {
                        self.view.window?.rootViewController = ParentTabBarViewController()
                    }
                }
            } catch { /* Handle error */ }
        }
    }
    
    private func checkParentLinkingAndRoute() {
        Task {
            do {
                let user = try await supabase.auth.session.user
                
                // 1. Fetch both linking fields from the profile
                let response = try await supabase
                    .from("profiles")
                    .select("linked_patient_id, linked_patient_id_2")
                    .eq("id", value: user.id)
                    .single()
                    .execute()
                
                let data = response.data
                let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                // Check both slots
                let linkedID1 = dict?["linked_patient_id"] as? String
                let linkedID2 = dict?["linked_patient_id_2"] as? String
                
                await MainActor.run {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first else {
                        self.setLoading(false)
                        return
                    }
                    
                    // Logic: If BOTH slots are nil or empty, show the link screen.
                    let hasNoLinkedChildren = (linkedID1 == nil || linkedID1?.isEmpty == true) &&
                    (linkedID2 == nil || linkedID2?.isEmpty == true)
                    
                    if hasNoLinkedChildren {
                        let emptyVC = ParentEmptyStateViewController()
                        window.rootViewController = UINavigationController(rootViewController: emptyVC)
                    } else {
                        // Set the initial active child to whichever slot is filled (prioritizing slot 1)
                        let activeID = (linkedID1 != nil && !linkedID1!.isEmpty) ? linkedID1 : linkedID2
                        UserDefaults.standard.set(activeID, forKey: "LastSelectedChildID")
                        
                        window.rootViewController = ParentTabBarViewController()
                    }
                    
                    UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil)
                    // Note: No need to stop loading here either, as root is replaced.
                }
            } catch {
                print("❌ Login Route Error: \(error)")
                await MainActor.run {
                    // Even on error, switch to safe empty state
                    self.switchToRoot(UINavigationController(rootViewController: ParentEmptyStateViewController()))
                }
            }
        }
    }
    
    private func switchToRoot(_ viewController: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        window.rootViewController = viewController
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil)
    }
    
    // MARK: - Actions
    @objc private func handlePasswordVisibilityTap() {
        passwordTextField.isSecureTextEntry.toggle()

        guard let btn = passwordTextField.rightView as? UIButton else { return }

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let symbol = passwordTextField.isSecureTextEntry ? "eye.slash" : "eye"

        btn.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
    }

    
    @objc private func handleCheckboxTap() {
        isAgreed.toggle()
        checkboxButton.setImage(UIImage(systemName: isAgreed ? "checkmark.square.fill" : "square"), for: .normal)
    }
    
    @objc private func handleCreateAccountTap() {
        navigationController?.pushViewController(register(), animated: true)
    }
    
    @objc private func handleTermsTap() {
        let termsVC = TermsViewController()
        termsVC.delegate = self
        self.present(termsVC, animated: true)
    }
    
    @objc private func handleForgotPasswordTap() {
        navigationController?.pushViewController(ForgotPasswordViewController(nibName: "ForgotPasswordViewController", bundle: nil), animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
// MARK: - UITextFieldDelegate
extension NewLoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder() // Move to password field
        } else {
            textField.resignFirstResponder() // Dismiss keyboard
            handleLoginTap() // Optional: Trigger login on 'Return'
        }
        return true
    }
}
extension NewLoginViewController: TermsViewControllerDelegate {
    func termsViewControllerDidAccept(_ controller: TermsViewController) {
        isAgreed = true
        checkboxButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
    }
}
