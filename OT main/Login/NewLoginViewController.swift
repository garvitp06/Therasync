//
//  NewLoginViewController.swift
//  NewLogin
//
//  Created by Alishri Poddar on 21/11/25.
//
import UIKit

class NewLoginViewController: UIViewController {

    // MARK: - UI Components
    
    // Header
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
    
    // Inputs
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "Email"
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 25
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "something@email.com"
        tf.font = .systemFont(ofSize: 14)
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let passwordLabel: UILabel = {
        let label = UILabel()
        label.text = "Password"
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let passwordContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 25
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "********"
        tf.font = .systemFont(ofSize: 14)
        tf.isSecureTextEntry = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    // Actions
    private let forgotPasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Forgot Password?", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.contentHorizontalAlignment = .right
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let checkboxButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "square"), for: .normal)
        btn.tintColor = .black
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // Terms Section
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
    
    private let loginButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Login", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.layer.cornerRadius = 25
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // Divider
    private let orLabel: UILabel = {
        let label = UILabel()
        label.text = "Or"
        label.font = .systemFont(ofSize: 17)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let leftLine: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let rightLine: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Social Buttons
    
    private let appleButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Sign in with Apple"
        config.image = UIImage(systemName: "applelogo")
        config.imagePadding = 10
        config.baseForegroundColor = .black
        
        var container = AttributeContainer()
        container.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        config.attributedTitle = AttributedString("Sign in with Apple", attributes: container)
        
        let btn = UIButton(configuration: config)
        btn.layer.cornerRadius = 25
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.black.cgColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // Google Button - UPDATED with White Background Removal
    private let googleButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Sign in with Google"
        config.imagePadding = 10
        config.baseForegroundColor = .black
        
        var container = AttributeContainer()
        container.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        config.attributedTitle = AttributedString("Sign in with Google", attributes: container)
        
        // --- LOGIC TO REMOVE WHITE BOX ---
        if let originalImage = UIImage(named: "Logo-google-icon-PNG") {
            
            // 1. Remove white background from the image programmatically
            let transparentImage = originalImage.removeWhiteBackground() ?? originalImage
            
            // 2. Resize to standard icon size
            let targetSize = CGSize(width: 20, height: 20)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let finalImage = renderer.image { _ in
                transparentImage.draw( in: CGRect(origin: .zero, size: targetSize))
            }
            
            config.image = finalImage.withRenderingMode(.alwaysOriginal)
        } else {
            print("❌ DEBUG: Google Logo NOT Found in Assets")
        }
        
        let btn = UIButton(configuration: config)
        btn.layer.cornerRadius = 25
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

    // Logic State
    private var isAgreed = false
    
    // MARK: - Lifecycle
    
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("NewLoginViewController Loaded Successfully")
        setupHierarchy()
        setupConstraints()
        setupActions()
    }
    
    // MARK: - Setup
    
    private func setupHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(welcomeLabel)
        
        view.addSubview(emailLabel)
        view.addSubview(emailContainer)
        emailContainer.addSubview(emailTextField)
        
        view.addSubview(passwordLabel)
        view.addSubview(passwordContainer)
        passwordContainer.addSubview(passwordTextField)
        
        view.addSubview(forgotPasswordButton)
        
        view.addSubview(checkboxButton)
        view.addSubview(termsStackView)
        termsStackView.addArrangedSubview(termsBaseLabel)
        termsStackView.addArrangedSubview(termsButton)
        
        view.addSubview(loginButton)
        
        view.addSubview(leftLine)
        view.addSubview(orLabel)
        view.addSubview(rightLine)
        
        view.addSubview(appleButton)
        view.addSubview(googleButton)
        view.addSubview(createAccountButton)
    }
    
    private func setupConstraints() {
        let margin: CGFloat = 30
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            // Header
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            
            welcomeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            
            // Email
            emailLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 40),
            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            emailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            
            emailContainer.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8),
            emailContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            emailContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            emailContainer.heightAnchor.constraint(equalToConstant: 50),
            
            emailTextField.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor, constant: 15),
            emailTextField.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor, constant: -15),
            emailTextField.topAnchor.constraint(equalTo: emailContainer.topAnchor),
            emailTextField.bottomAnchor.constraint(equalTo: emailContainer.bottomAnchor),
            
            // Password
            passwordLabel.topAnchor.constraint(equalTo: emailContainer.bottomAnchor, constant: 20),
            passwordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            passwordLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            
            passwordContainer.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor, constant: 8),
            passwordContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            passwordContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            passwordContainer.heightAnchor.constraint(equalToConstant: 50),
            
            passwordTextField.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor, constant: 15),
            passwordTextField.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor, constant: -15),
            passwordTextField.topAnchor.constraint(equalTo: passwordContainer.topAnchor),
            passwordTextField.bottomAnchor.constraint(equalTo: passwordContainer.bottomAnchor),
            
            // Forgot Password
            forgotPasswordButton.topAnchor.constraint(equalTo: passwordContainer.bottomAnchor, constant: 8),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            forgotPasswordButton.widthAnchor.constraint(equalToConstant: 130),
            
            // Terms Checkbox
            checkboxButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 10),
            checkboxButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            checkboxButton.widthAnchor.constraint(equalToConstant: 24),
            checkboxButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Terms Stack View
            termsStackView.centerYAnchor.constraint(equalTo: checkboxButton.centerYAnchor),
            termsStackView.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 10),
            termsStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -margin),
            
            // Login Button
            loginButton.topAnchor.constraint(equalTo: checkboxButton.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Divider
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
            
            // Social Buttons
            appleButton.topAnchor.constraint(equalTo: orLabel.bottomAnchor, constant: 20),
            appleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            appleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            appleButton.heightAnchor.constraint(equalToConstant: 50),
            
            googleButton.topAnchor.constraint(equalTo: appleButton.bottomAnchor, constant: 15),
            googleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            googleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            googleButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Create Account
            createAccountButton.topAnchor.constraint(equalTo: googleButton.bottomAnchor, constant: 20),
            createAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createAccountButton.bottomAnchor.constraint(lessThanOrEqualTo: safeArea.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupActions() {
        checkboxButton.addTarget(self, action: #selector(handleCheckboxTap), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(handleLoginTap), for: .touchUpInside)
        termsButton.addTarget(self, action: #selector(handleTermsTap), for: .touchUpInside)
        createAccountButton.addTarget(self, action: #selector(handleCreateAccountTap), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(handleForgotPasswordTap), for: .touchUpInside)
    }
    
    // MARK: - Logic Handlers
    
    @objc private func handleCheckboxTap() {
        isAgreed.toggle()
        let imageName = isAgreed ? "checkmark.square.fill" : "square"
        checkboxButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    @objc private func handleCreateAccountTap() {
            print("Create Account Tapped")
            
            // 1. Instantiate the View Controller from the XIB
            // Make sure your class is named 'register' and the file is 'register.xib'
            let registerVC = register(nibName: "register", bundle: nil)
            
            // 2. Navigate
            if let nav = navigationController {
                // If you are inside a Navigation Controller, push it (slide animation)
                nav.pushViewController(registerVC, animated: true)
            } else {
                // Otherwise, present it modally (pop up from bottom)
                // Optional: Set to .fullScreen if you want it to cover the whole screen
                registerVC.modalPresentationStyle = .fullScreen
                self.present(registerVC, animated: true, completion: nil)
            }
        }
    @objc private func handleForgotPasswordTap() {
        print("Forgot Password Tapped")
        
        // 1. Instantiate the View Controller from the XIB
        // Ensure the file name matches exactly: "ForgotPasswordViewController"
        let forgotVC = ForgotPasswordViewController(nibName: "ForgotPasswordViewController", bundle: nil)
        
        // 2. Push to the screen
        if let nav = navigationController {
            nav.pushViewController(forgotVC, animated: true)
        } else {
            // Fallback if not in a nav controller (though you should be)
            self.present(forgotVC, animated: true, completion: nil)
        }
    }
    @objc private func handleTermsTap() {
            print("Terms & Conditions Tapped")
            
            // 1. Instantiate the TermsViewController
            let termsVC = TermsViewController()
            
            // 2. Set the presentation style
            // .fullScreen covers the whole screen (looks like a push)
            // .pageSheet slides up from bottom (standard iOS modal)
            termsVC.modalPresentationStyle = .fullScreen
            
            // 3. (Optional) Set delegate if you want the "Accept" checkmark
            // in TermsVC to auto-check the box on the Login screen.
            termsVC.delegate = self
            
            // 4. Present the screen
            self.present(termsVC, animated: true, completion: nil)
        }
    
    @objc private func handleLoginTap() {
        // 1. Basic Empty Check
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter both email and password.")
            return
        }
        
        // 2. Email Format Validation
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        if !emailPred.evaluate(with: email) {
            showAlert(message: "Invalid Email Format. Please enter a valid email address.")
            return
        }
        
        // 3. Password Length Validation
        if password.count < 6 {
            showAlert(message: "Invalid Password. Password must be at least 6 characters long.")
            return
        }
        
        // 4. Terms Agreement Check
        if !isAgreed {
            showAlert(message: "Please agree to the Terms & Conditions.")
            return
        }

        // 5. Routing Logic
//        let lowercasedEmail = email.lowercased()
//        
//        if lowercasedEmail == "something@gmail.com" || lowercasedEmail.contains("therapist") || lowercasedEmail.contains("ot@") {
//            print("Navigating to Occupational Therapist Dashboard")
//            navigateToOTSide()
//        } else {
//            print("Navigating to Parent Dashboard")
//            navigateToParentSide()
//        }
        navigateToMainApp()
    }
    
    // MARK: - Navigation Helper Functions
    private func navigateToMainApp() {
            // 1. Create the Main Tab Bar Controller
            // This assumes you have the MainTabBarController.swift file we created earlier
            let mainTabBar = MainTabBarController()
            
            // 2. Access the Window
            guard let window = self.view.window else { return }
            
            // 3. Swap the Root View Controller
            window.rootViewController = mainTabBar
            
            // 4. Add a smooth animation (Cross Dissolve)
            UIView.transition(with: window,
                              duration: 0.5,
                              options: .transitionCrossDissolve,
                              animations: nil,
                              completion: nil)
        }
    private func navigateToOTSide() {
        let vc = OccupationalTherapistViewController()
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }
    
    private func navigateToParentSide() {
        let vc = ParentViewController()
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "TheraSync", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Helper Extension to Remove White Background
extension UIImage {
    func removeWhiteBackground() -> UIImage? {
        guard let rawImage = self.cgImage else { return nil }
        
        // Define range of colors to mask (High lightness values = White)
        // Range is [MinRed, MaxRed, MinGreen, MaxGreen, MinBlue, MaxBlue]
        // We use 200-255 to catch pure white and near-white compression artifacts
        let colorMasking: [CGFloat] = [200, 255, 200, 255, 200, 255]
        
        UIGraphicsBeginImageContext(self.size)
        guard let maskedImage = rawImage.copy(maskingColorComponents: colorMasking) else { return nil }
        
        // Convert back to UIImage
        let image = UIImage(cgImage: maskedImage)
        UIGraphicsEndImageContext()
        
        return image
    }
}

// MARK: - Dummy Destination Screens

class OccupationalTherapistViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let label = UILabel()
        label.text = "Occupational Therapist Side"
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

class ParentViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let label = UILabel()
        label.text = "Parent Side"
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .systemOrange
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
// MARK: - TermsViewControllerDelegate
extension NewLoginViewController: TermsViewControllerDelegate {
    func termsViewControllerDidAccept(_ controller: TermsViewController) {
        // 1. Update the logic state
        isAgreed = true
        
        // 2. Update the UI icon to filled
        checkboxButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
        
        print("User accepted terms via Terms Screen")
    }
}
