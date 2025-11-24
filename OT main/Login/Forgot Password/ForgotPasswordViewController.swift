// ForgotPasswordViewController.swift
import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField?
    @IBOutlet weak var sendOTPButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Forgot Password"
        setupUI()
        emailTextField?.delegate = self
    }

    private func setupUI() {
        sendOTPButton?.setTitle("Send OTP", for: .normal)
        sendOTPButton?.layer.cornerRadius = 12
        emailTextField?.keyboardType = .emailAddress
        emailTextField?.autocapitalizationType = .none
    }

    private func pushOrPresent(_ vc: UIViewController) {
        if let nav = self.navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            vc.modalPresentationStyle = .formSheet
            present(vc, animated: true)
        }
    }

    @IBAction func sendOTPButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        guard let email = emailTextField?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showAlert(title: "Enter Email", message: "Please enter your registered email address.")
            return
        }
        print("Valid email entered: \(email). Navigating to OTP screen...")

                // 1. Instantiate the EnterOTPViewController from its XIB
                // Ensure the file name is exactly "EnterOTPViewController"
                let enterOTPVC = EnterOTPViewController(nibName: "EnterOTPViewController", bundle: nil)
                pushOrPresent(enterOTPVC)

    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil){
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(a, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            sendOTPButtonTapped(sendOTPButton ?? UIButton())
        }
        return true
    }
}
