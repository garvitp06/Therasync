import UIKit

final class EnterOTPViewController: UIViewController {

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

        otpFields.first?.becomeFirstResponder()

        // Keyboard observers (optional)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - UI Setup
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

            // ✅ Backspace jump logic
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
        title = "Forgot Password"
        navigationItem.backButtonDisplayMode = .minimal
    }

    // MARK: - OTP Logic
    @objc private func textChanged(_ tf: UITextField) {
        guard let tf = tf as? OTPTextField else { return }

        // keep only 1 digit
        if let t = tf.text, t.count > 1 {
            tf.text = String(t.prefix(1))
        }

        if let idx = otpFields.firstIndex(of: tf),
           let text = tf.text, text.count == 1 {

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
        guard let kb = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let overlap = doneButton.frame.maxY - (UIScreen.main.bounds.height - kb.height)
        if overlap > 0 {
            UIView.animate(withDuration: 0.25) {
                self.view.transform = CGAffineTransform(translationX: 0, y: -overlap - 10)
            }
        }
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        UIView.animate(withDuration: 0.25) {
            self.view.transform = .identity
        }
    }

    // MARK: - Action
    @objc private func doneTapped() {
        view.endEditing(true)

        let code = otpFields.compactMap { $0.text }.joined()
        guard code.count == 6 else {
            showAlert(message: "Please enter the full 6-digit code.")
            return
        }

        guard let email = self.email else {
            showAlert(message: "Email not found. Please go back and try again.")
            return
        }

        doneButton.isEnabled = false

        Task {
            do {
                try await AuthService.shared.verifyRecoveryOTP(email: email, token: code)

                await MainActor.run {
                    self.doneButton.isEnabled = true

                    let vc = NewPasswordViewController()
                    navigationController?.pushViewController(vc, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.doneButton.isEnabled = true
                    self.showAlert(message: "Invalid OTP: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension EnterOTPViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        // Only allow backspace or digits
        return string.isEmpty || CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
    }
}

// MARK: - OTPTextField (same file)
final class OTPTextField: UITextField {
    var onDeleteBackward: (() -> Void)?

    override func deleteBackward() {
        onDeleteBackward?()
        super.deleteBackward()
    }
}
