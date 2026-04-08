import UIKit
import Supabase

class NewLoginViewController: UIViewController {

    // MARK: - State
    private var isAgreed = false

    // MARK: - UI

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "waveform.path.ecg.rectangle.fill")
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "TheraSync"
        l.font = .systemFont(ofSize: 34, weight: .bold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Sign in to your account"
        l.font = .systemFont(ofSize: 16)
        l.textColor = .systemGray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Email
    private let emailContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 26
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let emailIconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "envelope"))
        iv.tintColor = .systemGray3
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email address"
        tf.font = .systemFont(ofSize: 16)
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .next
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    // Password
    private let passwordContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 26
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let passwordIconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "lock"))
        iv.tintColor = .systemGray3
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.font = .systemFont(ofSize: 16)
        tf.isSecureTextEntry = true
        tf.textContentType = .password
        tf.passwordRules = nil
        tf.returnKeyType = .done
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    private let eyeButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        btn.setImage(UIImage(systemName: "eye.slash", withConfiguration: config), for: .normal)
        btn.tintColor = .systemGray3
        // IMPORTANT: Must use frame-based sizing — rightView is NOT managed by Auto Layout
        btn.frame = CGRect(x: 0, y: 0, width: 44, height: 52)
        return btn
    }()

    private let forgotPasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Forgot Password?", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.contentHorizontalAlignment = .right
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // Terms
    private let checkboxButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "square"), for: .normal)
        btn.tintColor = .systemBlue
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    private let termsBaseLabel: UILabel = {
        let l = UILabel()
        l.text = "I agree to TheraSync's"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .systemGray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let termsButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Terms & Conditions", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let loginButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Sign In", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.layer.cornerRadius = 26
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let createAccountButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        let attr = NSMutableAttributedString(
            string: "Don't have an account?  ",
            attributes: [.foregroundColor: UIColor.systemGray,
                         .font: UIFont.systemFont(ofSize: 14)]
        )
        attr.append(NSAttributedString(
            string: "Create one",
            attributes: [.foregroundColor: UIColor.systemBlue,
                         .font: UIFont.boldSystemFont(ofSize: 14)]
        ))
        btn.setAttributedTitle(attr, for: .normal)
        return btn
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.color = .systemBlue
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupHierarchy()
        setupConstraints()
        setupActions()

        // Add eye button as right view of password field
        passwordTextField.rightView = eyeButton
        passwordTextField.rightViewMode = .always

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup
    private func setupHierarchy() {
        [titleLabel, subtitleLabel,
         emailContainer, passwordContainer,
         forgotPasswordButton,
         checkboxButton, termsBaseLabel, termsButton,
         loginButton,
         createAccountButton,
         activityIndicator].forEach { view.addSubview($0) }

        emailContainer.addSubview(emailIconView)
        emailContainer.addSubview(emailTextField)
        passwordContainer.addSubview(passwordIconView)
        passwordContainer.addSubview(passwordTextField)
    }



    private func setupConstraints() {
        let m: CGFloat = 28
        let safe = view.safeAreaLayoutGuide
        
        // Use readableContentGuide for horizontal constraints on iPad to avoid over-stretching
        let horizontalGuide = view.readableContentGuide

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 86),
            titleLabel.leadingAnchor.constraint(equalTo: horizontalGuide.leadingAnchor, constant: m),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: horizontalGuide.leadingAnchor, constant: m),

            // Email
            emailContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            emailContainer.leadingAnchor.constraint(equalTo: horizontalGuide.leadingAnchor, constant: m),
            emailContainer.trailingAnchor.constraint(equalTo: horizontalGuide.trailingAnchor, constant: -m),
            emailContainer.heightAnchor.constraint(equalToConstant: 52),

            emailIconView.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor, constant: 14),
            emailIconView.centerYAnchor.constraint(equalTo: emailContainer.centerYAnchor),
            emailIconView.widthAnchor.constraint(equalToConstant: 18),
            emailIconView.heightAnchor.constraint(equalToConstant: 18),

            emailTextField.leadingAnchor.constraint(equalTo: emailIconView.trailingAnchor, constant: 10),
            emailTextField.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor, constant: -14),
            emailTextField.topAnchor.constraint(equalTo: emailContainer.topAnchor),
            emailTextField.bottomAnchor.constraint(equalTo: emailContainer.bottomAnchor),

            // Password
            passwordContainer.topAnchor.constraint(equalTo: emailContainer.bottomAnchor, constant: 14),
            passwordContainer.leadingAnchor.constraint(equalTo: horizontalGuide.leadingAnchor, constant: m),
            passwordContainer.trailingAnchor.constraint(equalTo: horizontalGuide.trailingAnchor, constant: -m),
            passwordContainer.heightAnchor.constraint(equalToConstant: 52),

            passwordIconView.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor, constant: 14),
            passwordIconView.centerYAnchor.constraint(equalTo: passwordContainer.centerYAnchor),
            passwordIconView.widthAnchor.constraint(equalToConstant: 18),
            passwordIconView.heightAnchor.constraint(equalToConstant: 18),

            passwordTextField.leadingAnchor.constraint(equalTo: passwordIconView.trailingAnchor, constant: 10),
            passwordTextField.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor, constant: -4),
            passwordTextField.topAnchor.constraint(equalTo: passwordContainer.topAnchor),
            passwordTextField.bottomAnchor.constraint(equalTo: passwordContainer.bottomAnchor),

            // Forgot
            forgotPasswordButton.topAnchor.constraint(equalTo: passwordContainer.bottomAnchor, constant: 8),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: horizontalGuide.trailingAnchor, constant: -m),

            // Terms
            checkboxButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 12),
            checkboxButton.leadingAnchor.constraint(equalTo: horizontalGuide.leadingAnchor, constant: m),
            checkboxButton.widthAnchor.constraint(equalToConstant: 24),
            checkboxButton.heightAnchor.constraint(equalToConstant: 24),

            termsBaseLabel.centerYAnchor.constraint(equalTo: checkboxButton.centerYAnchor),
            termsBaseLabel.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 6),

            termsButton.centerYAnchor.constraint(equalTo: checkboxButton.centerYAnchor),
            termsButton.leadingAnchor.constraint(equalTo: termsBaseLabel.trailingAnchor, constant: 2),

            // Login
            loginButton.topAnchor.constraint(equalTo: checkboxButton.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(equalTo: horizontalGuide.leadingAnchor, constant: m),
            loginButton.trailingAnchor.constraint(equalTo: horizontalGuide.trailingAnchor, constant: -m),
            loginButton.heightAnchor.constraint(equalToConstant: 52),

            // Create account
            createAccountButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 32),
            createAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createAccountButton.bottomAnchor.constraint(lessThanOrEqualTo: safe.bottomAnchor, constant: -24),

            // Spinner
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func setupActions() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        eyeButton.addTarget(self, action: #selector(handlePasswordVisibilityTap), for: .touchUpInside)
        checkboxButton.addTarget(self, action: #selector(handleCheckboxTap), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(handleLoginTap), for: .touchUpInside)
        termsButton.addTarget(self, action: #selector(handleTermsTap), for: .touchUpInside)
        createAccountButton.addTarget(self, action: #selector(handleCreateAccountTap), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(handleForgotPasswordTap), for: .touchUpInside)
    }

    // MARK: - Loading
    private func setLoading(_ loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false
            loginButton.setTitle("", for: .normal)
        } else {
            activityIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
            loginButton.setTitle("Sign In", for: .normal)
        }
    }

    // MARK: - Actions
    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func handlePasswordVisibilityTap() {
        passwordTextField.isSecureTextEntry.toggle()
        let symbol = passwordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        eyeButton.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
    }

    @objc private func handleCheckboxTap() {
        isAgreed.toggle()
        checkboxButton.setImage(UIImage(systemName: isAgreed ? "checkmark.square.fill" : "square"), for: .normal)
    }

    @objc private func handleLoginTap() {
        view.endEditing(true)
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter both email and password.")
            return
        }
        guard isAgreed else {
            showAlert(message: "Please agree to the Terms & Conditions.")
            return
        }
        
        setLoading(true)
        
        Task { [weak self] in // <-- Weak capture prevents retain cycles
            do {
                try await AuthService.shared.login(email: email.lowercased(), password: password)
                let role = try await AuthService.shared.fetchUserRole()
                
                await MainActor.run {
                    guard let self = self else { return } // <-- Ensure VC is alive
                    if role == "1" {
                        self.switchToRoot(MainTabBarController())
                    } else if role == "0" {
                        self.checkParentLinkingAndRoute()
                    } else {
                        self.setLoading(false)
                        self.showAlert(message: "Role not found.")
                    }
                }
            } catch {
                await MainActor.run {
                    self?.setLoading(false)
                    self?.showAlert(message: "Login failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func routeUser() {
        Task {
            do {
                let user = try await supabase.auth.session.user
                let fetched: [Patient] = try await supabase
                    .from("patients").select()
                    .eq("parent_uid", value: user.id).execute().value
                await MainActor.run {
                    self.view.window?.rootViewController = fetched.isEmpty
                        ? UINavigationController(rootViewController: ParentEmptyStateViewController())
                        : ParentTabBarViewController()
                }
            } catch {}
        }
    }

    private func checkParentLinkingAndRoute() {
        Task { [weak self] in
            do {
                // 1. Fetch the currently authenticated user
                let user = try await supabase.auth.session.user
                
                // 2. Fetch the specific profile fields for this user
                let response = try await supabase.from("profiles")
                    .select("linked_patient_id, linked_patient_id_2")
                    .eq("id", value: user.id)
                    .single()
                    .execute()
                
                // 3. Parse the JSON response safely
                let dict = try JSONSerialization.jsonObject(with: response.data) as? [String: Any]
                let id1 = dict?["linked_patient_id"] as? String
                let id2 = dict?["linked_patient_id_2"] as? String

                // 4. Route on the Main Thread
                await MainActor.run {
                    guard let self = self else { return }
                    
                    let hasNone = (id1 == nil || id1!.isEmpty) && (id2 == nil || id2!.isEmpty)
                    
                    if hasNone {
                        // No children linked, route to empty state
                        let emptyStateNav = UINavigationController(rootViewController: ParentEmptyStateViewController())
                        self.switchToRoot(emptyStateNav)
                    } else {
                        // At least one child linked, save default and route to dashboard
                        let defaultId = (id1 != nil && !id1!.isEmpty) ? id1 : id2
                        UserDefaults.standard.set(defaultId, forKey: "LastSelectedChildID")
                        
                        self.switchToRoot(ParentTabBarViewController())
                    }
                }
            } catch {
                // 5. Fallback: If network fails or profile is missing, default to empty state safely
                await MainActor.run {
                    guard let self = self else { return }
                    let emptyStateNav = UINavigationController(rootViewController: ParentEmptyStateViewController())
                    self.switchToRoot(emptyStateNav)
                }
            }
        }
    }

    private func switchToRoot(_ vc: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.windowLevel == .normal }) else { return }
        // Set rootViewController directly — never wrap this in UIView.transition animation block
        window.rootViewController = vc
        window.makeKeyAndVisible()
    }

    @objc private func handleCreateAccountTap() {
        navigationController?.pushViewController(register(), animated: true)
    }
    @objc private func handleTermsTap() {
        let vc = TermsViewController()
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
    @objc private func handleForgotPasswordTap() {
        navigationController?.pushViewController(ForgotPasswordViewController(), animated: true)
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
        if textField == emailTextField { passwordTextField.becomeFirstResponder() }
        else { textField.resignFirstResponder(); handleLoginTap() }
        return true
    }
}

// MARK: - TermsViewControllerDelegate
extension NewLoginViewController: TermsViewControllerDelegate {
    func termsViewControllerDidAccept(_ controller: TermsViewController) {
        isAgreed = true
        checkboxButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
    }
}
