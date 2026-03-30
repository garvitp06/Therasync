// NewPasswordViewController.swift
// TheraSync-Final
//
// Created by user@54 on 11/11/25.
//

import UIKit

final class NewPasswordViewController: UIViewController {

    // MARK: - Properties
    var email: String?

    private let gradientBackground = GradientView()

    // MARK: - UI
    private let headerLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "New Password"
        lbl.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        lbl.textColor = .black
        lbl.textAlignment = .left
        return lbl
    }()


    private lazy var newPasswordTextField: UITextField = makePasswordTextField(placeholder: "new password")
    private lazy var confirmPasswordTextField: UITextField = makePasswordTextField(placeholder: "confirm password")

    private lazy var submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.layer.cornerRadius = 22
        btn.setTitle("Submit", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        btn.backgroundColor = UIColor(red: 0.18, green: 0.56, blue: 0.99, alpha: 1)
        btn.isEnabled = false
        btn.alpha = 0.55
        btn.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupGradientBackground()
        configureNavBarAppearance()
        configureNavigationItems()
        setupUI()
        hookTextFieldTargets()

        newPasswordTextField.becomeFirstResponder()
        setSubmitEnabled(false)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavBarAppearance()
        navigationController?.setNavigationBarHidden(false, animated: false)
        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Background
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

    // MARK: - UI Layout
    private func setupUI() {
        view.addSubview(headerLabel)
        view.addSubview(newPasswordTextField)
        view.addSubview(confirmPasswordTextField)
        view.addSubview(submitButton)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),

            newPasswordTextField.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            newPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            newPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            newPasswordTextField.heightAnchor.constraint(equalToConstant: 56),

            confirmPasswordTextField.topAnchor.constraint(equalTo: newPasswordTextField.bottomAnchor, constant: 18),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 56),

            submitButton.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 22),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            submitButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }


    private func makePasswordTextField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 26
        tf.layer.masksToBounds = false

        tf.layer.shadowColor = UIColor.black.cgColor
        tf.layer.shadowOpacity = 0.08
        tf.layer.shadowRadius = 8
        tf.layer.shadowOffset = CGSize(width: 0, height: 4)

        tf.font = UIFont.systemFont(ofSize: 16)
        tf.textColor = .darkText
        tf.tintColor = UIColor(red: 0.18, green: 0.56, blue: 0.99, alpha: 1)

        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.isSecureTextEntry = true
        tf.delegate = self

        let placeholderColor = UIColor(white: 0.78, alpha: 1)
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: placeholderColor,
                .font: UIFont.systemFont(ofSize: 15)
            ]
        )

        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 18, height: 52))
        tf.leftViewMode = .always

        return tf
    }

    // MARK: - Nav
    private func configureNavBarAppearance() {
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

    // MARK: - Text / Validation
    private func hookTextFieldTargets() {
        newPasswordTextField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        confirmPasswordTextField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    @objc private func textChanged() {
        let a = newPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let b = confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        setSubmitEnabled(!a.isEmpty && !b.isEmpty && a == b)
    }

    private func setSubmitEnabled(_ enabled: Bool) {
        submitButton.isEnabled = enabled
        UIView.animate(withDuration: 0.12) {
            self.submitButton.alpha = enabled ? 1.0 : 0.55
            self.submitButton.backgroundColor = enabled
                ? UIColor(red: 0.18, green: 0.56, blue: 0.99, alpha: 1)
                : UIColor(white: 0.88, alpha: 1)
            self.submitButton.setTitleColor(
                enabled ? .white : UIColor(white: 0.6, alpha: 1),
                for: .normal
            )
        }
    }

    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func submitTapped() {
        view.endEditing(true)

        let p = newPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cp = confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !p.isEmpty && !cp.isEmpty else {
            showAlert(title: "Missing", message: "Please enter and confirm your new password.")
            return
        }

        guard p == cp else {
            showAlert(title: "Mismatch", message: "Passwords do not match.")
            return
        }

        guard p.count >= 6 else {
            showAlert(title: "Weak Password", message: "Password must be at least 6 characters.")
            return
        }

        submitButton.isEnabled = false

        Task {
            do {
                try await AuthService.shared.updatePassword(newPassword: p)

                await MainActor.run {
                    self.submitButton.isEnabled = true
                    self.showAlert(title: "Success", message: "Password changed successfully. Please login.") { [weak self] in
                        self?.navigationController?.popToRootViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.submitButton.isEnabled = true
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(a, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension NewPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == newPasswordTextField {
            confirmPasswordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
