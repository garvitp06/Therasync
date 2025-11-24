//
//  NewPasswordViewController.swift
//  TheraSync-Final
//
//  Created by user@54 on 11/11/25.
//

// NewPasswordViewController.swift
import UIKit

class NewPasswordViewController: UIViewController {

    @IBOutlet weak var newPasswordTextField: UITextField?
    @IBOutlet weak var confirmPasswordTextField: UITextField?
    @IBOutlet weak var submitButton: UIButton?

    // Optional: passed from OTP screen
    var email: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Password"
        setupUI()
        newPasswordTextField?.delegate = self
        confirmPasswordTextField?.delegate = self
    }

    private func setupUI() {
        submitButton?.setTitle("Submit", for: .normal)
        submitButton?.layer.cornerRadius = 12
        // Secure entries
        newPasswordTextField?.isSecureTextEntry = true
        confirmPasswordTextField?.isSecureTextEntry = true

        // Helpful keyboard options
        newPasswordTextField?.textContentType = .newPassword
        confirmPasswordTextField?.textContentType = .newPassword

        // Styling placeholders etc — optional
        newPasswordTextField?.placeholder = "New Password"
        confirmPasswordTextField?.placeholder = "Confirm Password"
    }

    @IBAction func submitTapped(_ sender: UIButton) {
        view.endEditing(true)

        guard let p = newPasswordTextField?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !p.isEmpty,
              let cp = confirmPasswordTextField?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !cp.isEmpty else {
            showAlert(title: "Missing", message: "Please enter and confirm your new password.")
            return
        }

        guard p == cp else {
            showAlert(title: "Mismatch", message: "Passwords do not match.")
            return
        }

        // TODO: call your API to update the password for `email`
        // On success, return to login screen:
        showAlert(title: "Success", message: "Password changed. Please login.") { [weak self] in
            if let nav = self?.navigationController {
                nav.popToRootViewController(animated: true)
            } else {
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(a, animated: true)
    }
}

extension NewPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == newPasswordTextField {
            confirmPasswordTextField?.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
