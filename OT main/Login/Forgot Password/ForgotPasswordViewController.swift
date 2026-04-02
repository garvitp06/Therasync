// ForgotPasswordViewController.swift
// Unified 3-step native iOS forgot-password flow — white background design
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
            case .email:       return "Forgot Password"
            case .otp:         return "Verify Code"
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
        pv.trackTintColor = .systemGray5
        pv.progressTintColor = .systemBlue
        pv.layer.cornerRadius = 2
        pv.clipsToBounds = true
        pv.setProgress(0.33, animated: false)
        return pv
    }()

    private let stepLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .systemGray
        l.text = "Step 1 of 3"
        return l
    }()

    // MARK: - Step 1: Email

    private let emailContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let emailHeaderLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Enter your registered email address and we'll send you a verification code."
        l.font = .systemFont(ofSize: 15)
        l.textColor = .systemGray
        l.numberOfLines = 0
        return l
    }()

    private let emailFieldContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 26
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let emailFieldIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "envelope"))
        iv.tintColor = .systemGray3
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "email@example.com"
        tf.font = .systemFont(ofSize: 16)
        tf.textColor = .black
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .done
        return tf
    }()

    private let sendOTPButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Send Code", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 26
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Step 2: OTP

    private let otpContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        v.alpha = 0
        return v
    }()

    private let otpHeaderLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "We've sent a 6-digit code to your email. Enter it below."
        l.font = .systemFont(ofSize: 15)
        l.textColor = .systemGray
        l.numberOfLines = 0
        return l
    }()

    private let otpStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private var otpFields: [OTPTextField] = []

    private let verifyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Verify Code", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 26
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isEnabled = false
        btn.alpha = 0.5
        return btn
    }()

    // MARK: - Step 3: New Password

    private let passwordContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        v.alpha = 0
        return v
    }()

    private let passwordHeaderLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Create a strong new password for your account."
        l.font = .systemFont(ofSize: 15)
        l.textColor = .systemGray
        l.numberOfLines = 0
        return l
    }()

    private let newPasswordFieldContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 26
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let newPasswordIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "lock"))
        iv.tintColor = .systemGray3; iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false; return iv
    }()
    private let newPasswordField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "New password"
        tf.font = .systemFont(ofSize: 16)
        tf.isSecureTextEntry = true
        tf.textContentType = .newPassword
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let confirmPasswordFieldContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 26
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let confirmPasswordIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "lock.fill"))
        iv.tintColor = .systemGray3; iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false; return iv
    }()
    private let confirmPasswordField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Confirm password"
        tf.font = .systemFont(ofSize: 16)
        tf.isSecureTextEntry = true
        tf.textContentType = .newPassword
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let resetButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Reset Password", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 26
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isEnabled = false
        btn.alpha = 0.5
        return btn
    }()

    // MARK: - Spinner
    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.translatesAutoresizingMaskIntoConstraints = false
        s.color = .systemBlue
        s.hidesWhenStopped = true
        return s
    }()

    // MARK: - Lifecycle

    // This MUST be here — the VC is sometimes instantiated with nibName:, so
    // we override loadView() to ignore the XIB and use our programmatic layout.
    override func loadView() {
        self.view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = currentStep.title
        navigationItem.backButtonDisplayMode = .minimal

        setupLayout()
        setupOTPFields()

        emailField.delegate = self
        newPasswordField.delegate = self
        confirmPasswordField.delegate = self
        newPasswordField.addTarget(self, action: #selector(passwordFieldsChanged), for: .editingChanged)
        confirmPasswordField.addTarget(self, action: #selector(passwordFieldsChanged), for: .editingChanged)
        sendOTPButton.addTarget(self, action: #selector(handleSendOTP), for: .touchUpInside)
        verifyButton.addTarget(self, action: #selector(handleVerifyOTP), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(handleResetPassword), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyNavBarAppearance()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func applyNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .systemBlue
    }

    // MARK: - Layout
    private func setupLayout() {
        [progressView, stepLabel,
         emailContainer, otpContainer, passwordContainer,
         spinner].forEach { view.addSubview($0) }

        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            progressView.heightAnchor.constraint(equalToConstant: 5),

            stepLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 6),
            stepLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        setupStep1Layout()
        setupStep2Layout()
        setupStep3Layout()
    }

    private func setupStep1Layout() {
        emailContainer.addSubview(emailHeaderLabel)
        emailFieldContainer.addSubview(emailFieldIcon)
        emailFieldContainer.addSubview(emailField)
        emailContainer.addSubview(emailFieldContainer)
        emailContainer.addSubview(sendOTPButton)

        NSLayoutConstraint.activate([
            emailContainer.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 28),
            emailContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emailContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            emailHeaderLabel.topAnchor.constraint(equalTo: emailContainer.topAnchor),
            emailHeaderLabel.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor),
            emailHeaderLabel.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor),

            emailFieldContainer.topAnchor.constraint(equalTo: emailHeaderLabel.bottomAnchor, constant: 20),
            emailFieldContainer.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor),
            emailFieldContainer.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor),
            emailFieldContainer.heightAnchor.constraint(equalToConstant: 52),

            emailFieldIcon.leadingAnchor.constraint(equalTo: emailFieldContainer.leadingAnchor, constant: 14),
            emailFieldIcon.centerYAnchor.constraint(equalTo: emailFieldContainer.centerYAnchor),
            emailFieldIcon.widthAnchor.constraint(equalToConstant: 18),
            emailFieldIcon.heightAnchor.constraint(equalToConstant: 18),

            emailField.leadingAnchor.constraint(equalTo: emailFieldIcon.trailingAnchor, constant: 10),
            emailField.trailingAnchor.constraint(equalTo: emailFieldContainer.trailingAnchor, constant: -14),
            emailField.topAnchor.constraint(equalTo: emailFieldContainer.topAnchor),
            emailField.bottomAnchor.constraint(equalTo: emailFieldContainer.bottomAnchor),

            sendOTPButton.topAnchor.constraint(equalTo: emailFieldContainer.bottomAnchor, constant: 24),
            sendOTPButton.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor),
            sendOTPButton.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor),
            sendOTPButton.heightAnchor.constraint(equalToConstant: 52),
            sendOTPButton.bottomAnchor.constraint(equalTo: emailContainer.bottomAnchor),
        ])
    }

    private func setupStep2Layout() {
        otpContainer.addSubview(otpHeaderLabel)
        otpContainer.addSubview(otpStack)
        otpContainer.addSubview(verifyButton)

        NSLayoutConstraint.activate([
            otpContainer.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 28),
            otpContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            otpContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            otpHeaderLabel.topAnchor.constraint(equalTo: otpContainer.topAnchor),
            otpHeaderLabel.leadingAnchor.constraint(equalTo: otpContainer.leadingAnchor),
            otpHeaderLabel.trailingAnchor.constraint(equalTo: otpContainer.trailingAnchor),

            otpStack.topAnchor.constraint(equalTo: otpHeaderLabel.bottomAnchor, constant: 28),
            otpStack.leadingAnchor.constraint(equalTo: otpContainer.leadingAnchor),
            otpStack.trailingAnchor.constraint(equalTo: otpContainer.trailingAnchor),
            otpStack.heightAnchor.constraint(equalToConstant: 56),

            verifyButton.topAnchor.constraint(equalTo: otpStack.bottomAnchor, constant: 28),
            verifyButton.leadingAnchor.constraint(equalTo: otpContainer.leadingAnchor),
            verifyButton.trailingAnchor.constraint(equalTo: otpContainer.trailingAnchor),
            verifyButton.heightAnchor.constraint(equalToConstant: 52),
            verifyButton.bottomAnchor.constraint(equalTo: otpContainer.bottomAnchor),
        ])
    }

    private func setupStep3Layout() {
        newPasswordFieldContainer.addSubview(newPasswordIcon)
        newPasswordFieldContainer.addSubview(newPasswordField)
        confirmPasswordFieldContainer.addSubview(confirmPasswordIcon)
        confirmPasswordFieldContainer.addSubview(confirmPasswordField)

        passwordContainer.addSubview(passwordHeaderLabel)
        passwordContainer.addSubview(newPasswordFieldContainer)
        passwordContainer.addSubview(confirmPasswordFieldContainer)
        passwordContainer.addSubview(resetButton)

        let iconConstraints = [
            newPasswordIcon.leadingAnchor.constraint(equalTo: newPasswordFieldContainer.leadingAnchor, constant: 14),
            newPasswordIcon.centerYAnchor.constraint(equalTo: newPasswordFieldContainer.centerYAnchor),
            newPasswordIcon.widthAnchor.constraint(equalToConstant: 18),
            newPasswordIcon.heightAnchor.constraint(equalToConstant: 18),
            newPasswordField.leadingAnchor.constraint(equalTo: newPasswordIcon.trailingAnchor, constant: 10),
            newPasswordField.trailingAnchor.constraint(equalTo: newPasswordFieldContainer.trailingAnchor, constant: -14),
            newPasswordField.topAnchor.constraint(equalTo: newPasswordFieldContainer.topAnchor),
            newPasswordField.bottomAnchor.constraint(equalTo: newPasswordFieldContainer.bottomAnchor),

            confirmPasswordIcon.leadingAnchor.constraint(equalTo: confirmPasswordFieldContainer.leadingAnchor, constant: 14),
            confirmPasswordIcon.centerYAnchor.constraint(equalTo: confirmPasswordFieldContainer.centerYAnchor),
            confirmPasswordIcon.widthAnchor.constraint(equalToConstant: 18),
            confirmPasswordIcon.heightAnchor.constraint(equalToConstant: 18),
            confirmPasswordField.leadingAnchor.constraint(equalTo: confirmPasswordIcon.trailingAnchor, constant: 10),
            confirmPasswordField.trailingAnchor.constraint(equalTo: confirmPasswordFieldContainer.trailingAnchor, constant: -14),
            confirmPasswordField.topAnchor.constraint(equalTo: confirmPasswordFieldContainer.topAnchor),
            confirmPasswordField.bottomAnchor.constraint(equalTo: confirmPasswordFieldContainer.bottomAnchor),
        ]

        NSLayoutConstraint.activate(iconConstraints + [
            passwordContainer.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 28),
            passwordContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            passwordContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            passwordHeaderLabel.topAnchor.constraint(equalTo: passwordContainer.topAnchor),
            passwordHeaderLabel.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor),
            passwordHeaderLabel.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor),

            newPasswordFieldContainer.topAnchor.constraint(equalTo: passwordHeaderLabel.bottomAnchor, constant: 20),
            newPasswordFieldContainer.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor),
            newPasswordFieldContainer.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor),
            newPasswordFieldContainer.heightAnchor.constraint(equalToConstant: 52),

            confirmPasswordFieldContainer.topAnchor.constraint(equalTo: newPasswordFieldContainer.bottomAnchor, constant: 14),
            confirmPasswordFieldContainer.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor),
            confirmPasswordFieldContainer.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor),
            confirmPasswordFieldContainer.heightAnchor.constraint(equalToConstant: 52),

            resetButton.topAnchor.constraint(equalTo: confirmPasswordFieldContainer.bottomAnchor, constant: 24),
            resetButton.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor),
            resetButton.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor),
            resetButton.heightAnchor.constraint(equalToConstant: 52),
            resetButton.bottomAnchor.constraint(equalTo: passwordContainer.bottomAnchor),
        ])
    }

    // MARK: - OTP Fields
    private func setupOTPFields() {
        otpFields = (0..<6).map { index in
            let tf = OTPTextField()
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.backgroundColor = .systemGray6
            tf.layer.cornerRadius = 12
            tf.font = .monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
            tf.textColor = .black
            tf.tintColor = .systemBlue
            tf.textAlignment = .center
            tf.keyboardType = .numberPad
            tf.delegate = self
            tf.addTarget(self, action: #selector(otpTextChanged(_:)), for: .editingChanged)
            tf.heightAnchor.constraint(equalToConstant: 56).isActive = true
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
        let containers: [UIView] = [emailContainer, otpContainer, passwordContainer]

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            containers.forEach { $0.alpha = 0 }
        } completion: { _ in
            containers.forEach { $0.isHidden = true; $0.alpha = 0 }
            let next = containers[step.rawValue]
            next.isHidden = false
            UIView.animate(withDuration: 0.3) { next.alpha = 1 }
        }

        progressView.setProgress(Float(step.rawValue + 1) / 3.0, animated: true)
        stepLabel.text = "Step \(step.rawValue + 1) of 3"
        title = step.title

        switch step {
        case .email:       DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.emailField.becomeFirstResponder() }
        case .otp:         DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.otpFields.first?.becomeFirstResponder() }
        case .newPassword: DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.newPasswordField.becomeFirstResponder() }
        }
    }

    // MARK: - Helpers
    @objc private func dismissKeyboard() { view.endEditing(true) }

    private func showAlert(_ title: String, _ msg: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }

    // MARK: - Step 1
    @objc private func handleSendOTP() {
        view.endEditing(true)
        guard let emailText = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !emailText.isEmpty else {
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

    // MARK: - Step 2
    @objc private func otpTextChanged(_ tf: UITextField) {
        guard let tf = tf as? OTPTextField else { return }
        if let t = tf.text, t.count > 1 { tf.text = String(t.prefix(1)) }
        if let idx = otpFields.firstIndex(of: tf), let text = tf.text, text.count == 1 {
            if idx + 1 < otpFields.count { otpFields[idx + 1].becomeFirstResponder() }
            else { tf.resignFirstResponder() }
        }
        updateVerifyState()
    }

    private func updateVerifyState() {
        let ready = otpFields.compactMap { $0.text }.joined().count == 6
        verifyButton.isEnabled = ready
        UIView.animate(withDuration: 0.12) { self.verifyButton.alpha = ready ? 1.0 : 0.5 }
    }

    @objc private func handleVerifyOTP() {
        view.endEditing(true)
        let code = otpFields.compactMap { $0.text }.joined()
        guard code.count == 6 else { showAlert("Incomplete", "Enter the full 6-digit code."); return }
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
                    self.showAlert("Invalid Code", error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Step 3
    @objc private func passwordFieldsChanged() {
        let a = newPasswordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let b = confirmPasswordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let ready = !a.isEmpty && !b.isEmpty && a == b
        resetButton.isEnabled = ready
        UIView.animate(withDuration: 0.12) { self.resetButton.alpha = ready ? 1.0 : 0.5 }
    }

    @objc private func handleResetPassword() {
        view.endEditing(true)
        let p  = newPasswordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cp = confirmPasswordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !p.isEmpty else { showAlert("Missing", "Please enter your new password."); return }
        guard p == cp   else { showAlert("Mismatch", "Passwords do not match."); return }
        guard p.count >= 6 else { showAlert("Weak Password", "Password must be at least 6 characters."); return }

        resetButton.isEnabled = false
        spinner.startAnimating()
        Task {
            do {
                try await AuthService.shared.updatePassword(newPassword: p)
                await MainActor.run {
                    self.resetButton.isEnabled = true
                    self.spinner.stopAnimating()
                    self.showAlert("Success ✓", "Password changed successfully. Please sign in.") { [weak self] in
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
        case .email:       handleSendOTP()
        case .otp:         break
        case .newPassword:
            if textField == newPasswordField { confirmPasswordField.becomeFirstResponder() }
            else { textField.resignFirstResponder() }
        }
        return true
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if otpFields.contains(textField as? OTPTextField ?? OTPTextField()) {
            return string.isEmpty || CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
        }
        return true
    }
}
