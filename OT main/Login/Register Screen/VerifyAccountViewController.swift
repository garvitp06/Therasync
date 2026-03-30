
//
//  VerifyAccountViewController.swift
//  OT main
//
//  Created by user@54 on 20/02/26.
//

import UIKit

final class VerifyAccountViewController: UIViewController {

    // MARK: - Public
    var email: String?

    // MARK: - UI
    private let gradientBackground = GradientView()

    private let headerLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "Enter OTP"
        lbl.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        lbl.textColor = .black
        lbl.textAlignment = .left
        return lbl
    }()

    private let otpStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var doneButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.layer.cornerRadius = 22
        btn.setTitle("Done", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        // Using the lighter blue color to match your other screen
        btn.backgroundColor = UIColor(red: 0.18, green: 0.56, blue: 0.99, alpha: 1)
        btn.isEnabled = false
        btn.alpha = 0.55
        btn.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - OTP
    private var otpFields: [OTPTextField] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupGradientBackground()
        configureNavigationAppearance()
        configureNavigationItems()
        setupUI()
        setupOTPFields()
        setupTapToDismiss()

        otpFields.first?.becomeFirstResponder()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup
    private func setupTapToDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false // Allows the "Done" button to still work
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    private func setupGradientBackground() {
        gradientBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientBackground)

        NSLayoutConstraint.activate([
            gradientBackground.topAnchor.constraint(equalTo: view.topAnchor),
            gradientBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupUI() {
        view.addSubview(headerLabel)
        view.addSubview(otpStack)
        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),

            otpStack.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 18),
            otpStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),

            doneButton.topAnchor.constraint(equalTo: otpStack.bottomAnchor, constant: 28),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            doneButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    private func setupOTPFields() {
        let boxSize: CGFloat = 50
        let cornerRadius: CGFloat = 12

        otpFields = (0..<6).map { index in
            let tf = OTPTextField()
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.backgroundColor = .white
            tf.layer.cornerRadius = cornerRadius
            tf.layer.borderWidth = 1
            tf.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
            tf.layer.shadowColor = UIColor.black.cgColor
            tf.layer.shadowOpacity = 0.06
            tf.layer.shadowRadius = 6
            tf.layer.shadowOffset = CGSize(width: 0, height: 3)
            tf.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .medium)
            tf.textAlignment = .center
            tf.keyboardType = .numberPad
            tf.delegate = self
            tf.addTarget(self, action: #selector(textChanged(_:)), for: .editingChanged)

            NSLayoutConstraint.activate([
                tf.widthAnchor.constraint(equalToConstant: boxSize),
                tf.heightAnchor.constraint(equalToConstant: boxSize)
            ])

            tf.onDeleteBackward = { [weak self] in
                guard let self = self else { return }
                if (tf.text ?? "").isEmpty {
                    let prev = index - 1
                    if prev >= 0 {
                        self.otpFields[prev].text = ""
                        self.otpFields[prev].becomeFirstResponder()
                    }
                }
                self.updateDoneState()
            }
            return tf
        }
        otpFields.forEach { otpStack.addArrangedSubview($0) }
    }
    
    // MARK: - Nav
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func configureNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barStyle = .black
    }

    private func configureNavigationItems() {
        title = "Verify Account"
        navigationItem.backButtonDisplayMode = .minimal
    }

    // MARK: - OTP Logic
    @objc private func textChanged(_ tf: UITextField) {
        guard let tf = tf as? OTPTextField else { return }

        if let t = tf.text, t.count > 1 {
            tf.text = String(t.prefix(1))
        }

        if let idx = otpFields.firstIndex(of: tf), let text = tf.text, text.count == 1 {
            if idx + 1 < otpFields.count {
                otpFields[idx + 1].becomeFirstResponder()
            } else {
                tf.resignFirstResponder()
            }
        }
        updateDoneState()
    }

    private func updateDoneState() {
        let otp = otpFields.compactMap { $0.text }.joined()
        let ready = otp.count == 6
        doneButton.isEnabled = ready
        UIView.animate(withDuration: 0.12) {
            self.doneButton.alpha = ready ? 1.0 : 0.55
        }
    }

    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(_ n: Notification) {
        guard let kbFrame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        // Calculate the gap between the bottom of the button and the top of the keyboard
        let buttonBottom = doneButton.convert(doneButton.bounds, to: self.view).maxY
        let keyboardTop = view.frame.height - kbFrame.height
        
        if buttonBottom > keyboardTop {
            let offset = buttonBottom - keyboardTop + 20 // 20 for extra padding
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.view.transform = CGAffineTransform(translationX: 0, y: -offset)
            }
        }
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.view.transform = .identity
        }
    }

    // MARK: - Action
    @objc private func doneTapped() {
        view.endEditing(true)

        let code = otpFields.compactMap { $0.text }.joined()
        guard code.count == 6 else { return }
        
        guard let email = self.email else {
            showAlert(message: "Email not found. Please try registering again.")
            return
        }

        doneButton.isEnabled = false

        Task {
            do {
                // Verification specific to new account registration
                try await AuthService.shared.verifyRegistration(email: email, token: code)

                await MainActor.run {
                    self.doneButton.isEnabled = true
                    self.showAlertAndDismiss(message: "Account verified successfully! You can now log in.")
                }
            } catch {
                await MainActor.run {
                    self.doneButton.isEnabled = true
                    self.showAlert(message: "Invalid code: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Verification", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showAlertAndDismiss(message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            // Navigate back to the login screen (root)
            self.navigationController?.popToRootViewController(animated: true)
        }))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension VerifyAccountViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.isEmpty || CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
    }
}
