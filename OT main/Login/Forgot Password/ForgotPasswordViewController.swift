// ForgotPasswordViewController.swift
import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField?
    @IBOutlet weak var sendOTPButton: UIButton?

    // MARK: - UI

    private let progEmailLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "Email"
        lbl.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        lbl.textColor = .label
        return lbl
    }()

    private let progEmailField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 26
        tf.layer.masksToBounds = false

        tf.layer.shadowColor = UIColor.black.cgColor
        tf.layer.shadowOpacity = 0.06
        tf.layer.shadowRadius = 8
        tf.layer.shadowOffset = CGSize(width: 0, height: 3)

        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 18, height: 1))
        tf.leftView = pad
        tf.leftViewMode = .always

        tf.font = UIFont.systemFont(ofSize: 16)
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none

        tf.attributedPlaceholder = NSAttributedString(
            string: "something@email.com",
            attributes: [
                .foregroundColor: UIColor.systemGray3,
                .font: UIFont.systemFont(ofSize: 15)
            ]
        )
        return tf
    }()

    private let progSendOTPButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Send OTP", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        btn.backgroundColor = UIColor(red: 0.18, green: 0.56, blue: 0.99, alpha: 1)
        btn.layer.cornerRadius = 22
        return btn
    }()

    private let gradientHeader = UIView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        //view.backgroundColor = UIColor(white: 0.96, alpha: 1)

        configureNavigationAppearance()
        configureNavigationItems()

        emailTextField?.isHidden = true
        sendOTPButton?.isHidden = true
        hideAnyXIBEmailLabel()

        //setupGradient()
        setupHierarchy()
        setupConstraints()

        progSendOTPButton.addTarget(self, action: #selector(handleSendOTP), for: .touchUpInside)
        progEmailField.delegate = self
    }
    
    override func loadView() {
        self.view = GradientView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationAppearance()
        navigationController?.setNavigationBarHidden(false, animated: false)
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientHeader.layer.sublayers?.first?.frame = gradientHeader.bounds
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - NAVBAR (NATIVE BACK BUTTON)

    private func configureNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

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

    private func configureNavigationItems() {
        title = "Forgot Password"

        // Native back button, no text
        navigationItem.backButtonDisplayMode = .minimal
    }

    // MARK: - GRADIENT (INSPIRED BY GradientView)

    private func setupGradient() {
        gradientHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientHeader)

        NSLayoutConstraint.activate([
            gradientHeader.topAnchor.constraint(equalTo: view.topAnchor),
            gradientHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientHeader.heightAnchor.constraint(equalToConstant: 310)
        ])

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1).cgColor, // #00B8FF
            UIColor(white: 0.95, alpha: 1).cgColor
        ]
        gradient.locations = [0, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint   = CGPoint(x: 0.5, y: 1)

        gradientHeader.layer.insertSublayer(gradient, at: 0)
    }

    // MARK: - Layout

    private func setupHierarchy() {
        view.addSubview(progEmailLabel)
        view.addSubview(progEmailField)
        view.addSubview(progSendOTPButton)
    }

    private func setupConstraints() {
        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            progEmailLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 30),
            progEmailLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 30),

            progEmailField.topAnchor.constraint(equalTo: progEmailLabel.bottomAnchor, constant: 12),
            progEmailField.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 30),
            progEmailField.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -30),
            progEmailField.heightAnchor.constraint(equalToConstant: 56),

            progSendOTPButton.topAnchor.constraint(equalTo: progEmailField.bottomAnchor, constant: 20),
            progSendOTPButton.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 30),
            progSendOTPButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -30),
            progSendOTPButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Helpers

    private func hideAnyXIBEmailLabel() {
        func hide(in view: UIView) {
            for v in view.subviews {
                if let lbl = v as? UILabel, lbl.text == "Email" {
                    lbl.isHidden = true
                }
                hide(in: v)
            }
        }
        hide(in: self.view)
    }

    // MARK: - Actions

    @objc private func handleSendOTP() {
            view.endEditing(true)

            guard let email = progEmailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
                showAlert("Enter Email", "Please enter your registered email.")
                return
            }
            
            // Disable button to prevent double taps
            progSendOTPButton.isEnabled = false

            Task {
                do {
                    // 1. Call Supabase
                    try await AuthService.shared.sendPasswordResetOTP(email: email)

                    await MainActor.run {
                        self.progSendOTPButton.isEnabled = true
                        // 2. Navigate to OTP Screen
                        let vc = EnterOTPViewController()
                        vc.email = email
                        navigationController?.pushViewController(vc, animated: true)

                    }
                } catch {
                    await MainActor.run {
                        self.progSendOTPButton.isEnabled = true
                        self.showAlert("Error", error.localizedDescription)
                    }
                }
            }
        }

    private func showAlert(_ title: String, _ msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSendOTP()
        return true
    }
}
