// ForgotPasswordViewController.swift
// Unified 3-step native iOS forgot-password flow
import UIKit

// MARK: - OTPTextField (backspace detection)
final class OTPTextField: UITextField {
    var onDeleteBackward: (() -> Void)?
    override func deleteBackward() {
        onDeleteBackward?()
        super.deleteBackward()
    }
}

final class ForgotPasswordViewController: UIViewController {

    // MARK: - Step Model
    private enum Step: Int, CaseIterable {
        case email = 0, otp, newPassword
        var title: String {
            switch self {
            case .email:       return "Enter Email"
            case .otp:         return "Verify OTP"
            case .newPassword: return "New Password"
            }
        }
    }

    private var currentStep: Step = .email
    private var email: String = ""

    // MARK: - Shared UI
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.trackTintColor = UIColor.white.withAlphaComponent(0.25)
        pv.progressTintColor = .white
        pv.setProgress(0.33, animated: false)
        return pv
    }()

    private let stepLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = .systemFont(ofSize: 13, weight: .medium)
        lbl.textColor = UIColor.white.withAlphaComponent(0.8)
        lbl.text = "Step 1 of 3"
        return lbl
    }()

    // MARK: - Step 1: Email
    private lazy var emailContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let emailHeaderLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "Enter your registered email address and we'll send you a verification code."
        lbl.font = .systemFont(ofSize: 15)
        lbl.textColor = .white
        lbl.numberOfLines = 0
        return lbl
    }()

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        tf.layer.cornerRadius = 26
        tf.font = .systemFont(ofSize: 16)
        tf.textColor = .white
        tf.tintColor = .white
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.attributedPlaceholder = NSAttributedString(
            string: "email@example.com",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        )
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        tf.leftView = pad
        tf.leftViewMode = .always
        let padR = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        tf.rightView = padR
        tf.rightViewMode = .always
        return tf
    }()

    private lazy var sendOTPButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Send OTP"
        config.background.cornerRadius = 26
        config.baseBackgroundColor = .white
        config.baseForegroundColor = UIColor(red: 0.11, green: 0.45, blue: 0.98, alpha: 1)
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleSendOTP), for: .touchUpInside)
        return btn
    }()

    // MARK: - Step 2: OTP
    private lazy var otpContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let otpHeaderLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "We've sent a 6-digit code to your email. Enter it below."
        lbl.font = .systemFont(ofSize: 15)
        lbl.textColor = .white
        lbl.numberOfLines = 0
        return lbl
    }()

    private let otpStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var otpFields: [OTPTextField] = []

    private lazy var verifyButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Verify"
        config.background.cornerRadius = 26
        config.baseBackgroundColor = .white
        config.baseForegroundColor = UIColor(red: 0.11, green: 0.45, blue: 0.98, alpha: 1)
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isEnabled = false
        btn.alpha = 0.55
        btn.addTarget(self, action: #selector(handleVerifyOTP), for: .touchUpInside)
        return btn
    }()

    // MARK: - Step 3: New Password
    private lazy var passwordContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let passwordHeaderLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "Create a new password for your account."
        lbl.font = .systemFont(ofSize: 15)
        lbl.textColor = .white
        lbl.numberOfLines = 0
        return lbl
    }()

    private lazy var newPasswordField: UITextField = makePasswordField(placeholder: "New password")
    private lazy var confirmPasswordField: UITextField = makePasswordField(placeholder: "Confirm password")

    private lazy var resetButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Reset Password"
        config.background.cornerRadius = 26
        config.baseBackgroundColor = .white
        config.baseForegroundColor = UIColor(red: 0.11, green: 0.45, blue: 0.98, alpha: 1)
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isEnabled = false
        btn.alpha = 0.55
        btn.addTarget(self, action: #selector(handleResetPassword), for: .touchUpInside)
        return btn
    }()

    // MARK: - Activity
    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.translatesAutoresizingMaskIntoConstraints = false
        s.color = .white
        s.hidesWhenStopped = true
        return s
    }()

    // MARK: - Lifecycle

    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationAppearance()
        title = "Forgot Password"
        navigationItem.backButtonDisplayMode = .minimal

        setupLayout()
        setupOTPFields()

        emailField.delegate = self
        newPasswordField.addTarget(self, action: #selector(passwordFieldsChanged), for: .editingChanged)
        confirmPasswordField.addTarget(self, action: #selector(passwordFieldsChanged), for: .editingChanged)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationAppearance()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Nav Bar
    private func configureNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barStyle = .black
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(progressView)
        view.addSubview(stepLabel)
        view.addSubview(emailContainer)
        view.addSubview(otpContainer)
        view.addSubview(passwordContainer)
        view.addSubview(spinner)

        let safe = view.safeAreaLayoutGuide

        // Progress bar
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            stepLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            stepLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        // — Step 1: Email —
        emailContainer.addSubview(emailHeaderLabel)
        emailContainer.addSubview(emailField)
        emailContainer.addSubview(sendOTPButton)

        NSLayoutConstraint.activate([
            emailContainer.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 32),
            emailContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emailContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            emailHeaderLabel.topAnchor.constraint(equalTo: emailContainer.topAnchor),
            emailHeaderLabel.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor),
            emailHeaderLabel.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor),

            emailField.topAnchor.constraint(equalTo: emailHeaderLabel.bottomAnchor, constant: 20),
            emailField.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor),
            emailField.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor),
            emailField.heightAnchor.constraint(equalToConstant: 50),

            sendOTPButton.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 24),
            sendOTPButton.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor),
            sendOTPButton.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor),
            sendOTPButton.heightAnchor.constraint(equalToConstant: 50),
            sendOTPButton.bottomAnchor.constraint(equalTo: emailContainer.bottomAnchor),
        ])

        // — Step 2: OTP —
        otpContainer.addSubview(otpHeaderLabel)
        otpContainer.addSubview(otpStack)
        otpContainer.addSubview(verifyButton)

        NSLayoutConstraint.activate([
            otpContainer.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 32),
            otpContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            otpContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            otpHeaderLabel.topAnchor.constraint(equalTo: otpContainer.topAnchor),
            otpHeaderLabel.leadingAnchor.constraint(equalTo: otpContainer.leadingAnchor),
            otpHeaderLabel.trailingAnchor.constraint(equalTo: otpContainer.trailingAnchor),

            otpStack.topAnchor.constraint(equalTo: otpHeaderLabel.bottomAnchor, constant: 24),
            otpStack.leadingAnchor.constraint(equalTo: otpContainer.leadingAnchor),
            otpStack.trailingAnchor.constraint(equalTo: otpContainer.trailingAnchor),
            otpStack.heightAnchor.constraint(equalToConstant: 54),

            verifyButton.topAnchor.constraint(equalTo: otpStack.bottomAnchor, constant: 28),
            verifyButton.leadingAnchor.constraint(equalTo: otpContainer.leadingAnchor),
            verifyButton.trailingAnchor.constraint(equalTo: otpContainer.trailingAnchor),
            verifyButton.heightAnchor.constraint(equalToConstant: 50),
            verifyButton.bottomAnchor.constraint(equalTo: otpContainer.bottomAnchor),
        ])

        // — Step 3: Password —
        passwordContainer.addSubview(passwordHeaderLabel)
        passwordContainer.addSubview(newPasswordField)
        passwordContainer.addSubview(confirmPasswordField)
        passwordContainer.addSubview(resetButton)

        NSLayoutConstraint.activate([
            passwordContainer.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 32),
            passwordContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            passwordContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            passwordHeaderLabel.topAnchor.constraint(equalTo: passwordContainer.topAnchor),
            passwordHeaderLabel.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor),
            passwordHeaderLabel.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor),

            newPasswordField.topAnchor.constraint(equalTo: passwordHeaderLabel.bottomAnchor, constant: 20),
            newPasswordField.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor),
            newPasswordField.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor),
            newPasswordField.heightAnchor.constraint(equalToConstant: 50),

            confirmPasswordField.topAnchor.constraint(equalTo: newPasswordField.bottomAnchor, constant: 14),
            confirmPasswordField.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor),
            confirmPasswordField.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor),
            confirmPasswordField.heightAnchor.constraint(equalToConstant: 50),

            resetButton.topAnchor.constraint(equalTo: confirmPasswordField.bottomAnchor, constant: 24),
            resetButton.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor),
            resetButton.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor),
            resetButton.heightAnchor.constraint(equalToConstant: 50),
            resetButton.bottomAnchor.constraint(equalTo: passwordContainer.bottomAnchor),
        ])
    }

    // MARK: - OTP Fields Setup
    private func setupOTPFields() {
        otpFields = (0..<6).map { index in
            let tf = OTPTextField()
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.backgroundColor = .white
            tf.layer.cornerRadius = 12
            tf.layer.borderWidth = 0
            tf.font = .monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
            tf.textColor = .black
            tf.tintColor = UIColor(red: 0.11, green: 0.45, blue: 0.98, alpha: 1)
            tf.textAlignment = .center
            tf.keyboardType = .numberPad
            tf.delegate = self
            tf.addTarget(self, action: #selector(otpTextChanged(_:)), for: .editingChanged)

            NSLayoutConstraint.activate([
                tf.heightAnchor.constraint(equalToConstant: 54),
            ])

            tf.onDeleteBackward = { [weak self] in
                guard let self else { return }
                if (tf.text ?? "").isEmpty, index > 0 {
                    self.otpFields[index - 1].text = ""
                    self.otpFields[index - 1].becomeFirstResponder()
                }
                self.updateVerifyState()
            }
            return tf
        }
        otpFields.forEach { otpStack.addArrangedSubview($0) }
    }

    // MARK: - Step Transition
    private func transitionTo(_ step: Step) {
        currentStep = step
        let containers = [emailContainer, otpContainer, passwordContainer]

        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut) {
            containers.forEach { $0.alpha = 0 }
        } completion: { _ in
            containers.forEach { $0.isHidden = true }
            containers[step.rawValue].isHidden = false

            UIView.animate(withDuration: 0.35) {
                containers[step.rawValue].alpha = 1
            }
        }

        UIView.animate(withDuration: 0.35) {
            self.progressView.setProgress(Float(step.rawValue + 1) / 3.0, animated: true)
        }

        stepLabel.text = "Step \(step.rawValue + 1) of 3"
        title = step.title

        // Auto-focus
        switch step {
        case .email:
            emailField.becomeFirstResponder()
        case .otp:
            otpFields.first?.becomeFirstResponder()
        case .newPassword:
            newPasswordField.becomeFirstResponder()
        }
    }

    // MARK: - Helpers
    private func makePasswordField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        tf.layer.cornerRadius = 26
        tf.font = .systemFont(ofSize: 16)
        tf.textColor = .white
        tf.tintColor = .white
        tf.isSecureTextEntry = true
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        )
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        tf.leftView = pad
        tf.leftViewMode = .always
        let padR = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        tf.rightView = padR
        tf.rightViewMode = .always
        tf.delegate = self
        return tf
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func showAlert(_ title: String, _ msg: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }

    // MARK: - Step 1 Action
    @objc private func handleSendOTP() {
        view.endEditing(true)

        guard let emailText = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !emailText.isEmpty else {
            showAlert("Enter Email", "Please enter your registered email.")
            return
        }

        email = emailText
        sendOTPButton.isEnabled = false
        spinner.startAnimating()

        Task {
            do {
                try await AuthService.shared.sendPasswordResetOTP(email: emailText)
                await MainActor.run {
                    self.sendOTPButton.isEnabled = true
                    self.spinner.stopAnimating()
                    self.transitionTo(.otp)
                }
            } catch {
                await MainActor.run {
                    self.sendOTPButton.isEnabled = true
                    self.spinner.stopAnimating()
                    self.showAlert("Error", error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Step 2 OTP Logic
    @objc private func otpTextChanged(_ tf: UITextField) {
        guard let tf = tf as? OTPTextField else { return }
        if let t = tf.text, t.count > 1 { tf.text = String(t.prefix(1)) }

        if let idx = otpFields.firstIndex(of: tf), let text = tf.text, text.count == 1 {
            if idx + 1 < otpFields.count {
                otpFields[idx + 1].becomeFirstResponder()
            } else {
                tf.resignFirstResponder()
            }
        }
        updateVerifyState()
    }

    private func updateVerifyState() {
        let code = otpFields.compactMap { $0.text }.joined()
        let ready = code.count == 6
        verifyButton.isEnabled = ready
        UIView.animate(withDuration: 0.12) {
            self.verifyButton.alpha = ready ? 1.0 : 0.55
        }
    }

    @objc private func handleVerifyOTP() {
        view.endEditing(true)

        let code = otpFields.compactMap { $0.text }.joined()
        guard code.count == 6 else {
            showAlert("Incomplete", "Please enter the full 6-digit code.")
            return
        }

        verifyButton.isEnabled = false
        spinner.startAnimating()

        Task {
            do {
                try await AuthService.shared.verifyRecoveryOTP(email: email, token: code)
                await MainActor.run {
                    self.verifyButton.isEnabled = true
                    self.spinner.stopAnimating()
                    self.transitionTo(.newPassword)
                }
            } catch {
                await MainActor.run {
                    self.verifyButton.isEnabled = true
                    self.spinner.stopAnimating()
                    self.showAlert("Invalid OTP", error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Step 3 Password Logic
    @objc private func passwordFieldsChanged() {
        let a = newPasswordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let b = confirmPasswordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let ready = !a.isEmpty && !b.isEmpty && a == b
        resetButton.isEnabled = ready
        UIView.animate(withDuration: 0.12) {
            self.resetButton.alpha = ready ? 1.0 : 0.55
        }
    }

    @objc private func handleResetPassword() {
        view.endEditing(true)

        let p = newPasswordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cp = confirmPasswordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !p.isEmpty, !cp.isEmpty else {
            showAlert("Missing", "Please enter and confirm your new password.")
            return
        }
        guard p == cp else {
            showAlert("Mismatch", "Passwords do not match.")
            return
        }
        guard p.count >= 6 else {
            showAlert("Weak Password", "Password must be at least 6 characters.")
            return
        }

        resetButton.isEnabled = false
        spinner.startAnimating()

        Task {
            do {
                try await AuthService.shared.updatePassword(newPassword: p)
                await MainActor.run {
                    self.resetButton.isEnabled = true
                    self.spinner.stopAnimating()
                    self.showAlert("Success", "Password changed successfully. Please login.") { [weak self] in
                        self?.navigationController?.popToRootViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.resetButton.isEnabled = true
                    self.spinner.stopAnimating()
                    self.showAlert("Error", error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch currentStep {
        case .email:
            handleSendOTP()
        case .otp:
            break
        case .newPassword:
            if textField == newPasswordField {
                confirmPasswordField.becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
        return true
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if currentStep == .otp {
            return string.isEmpty || CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
        }
        return true
    }
}
