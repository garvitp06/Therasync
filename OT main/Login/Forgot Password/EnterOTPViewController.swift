//
//  EnterOTPViewController.swift
//  TheraSync-Final
//
//  Created by user@54 on 11/11/25.
//

// EnterOTPViewController.swift
import UIKit

class EnterOTPViewController: UIViewController {
    
    // Four visible OTP text fields (connect these to the 4 small boxes in your XIB)
    @IBOutlet weak var otpField1: UITextField?
    @IBOutlet weak var otpField2: UITextField?
    @IBOutlet weak var otpField3: UITextField?
    @IBOutlet weak var otpField4: UITextField?
    
    // Optional: a "Done" button under the fields
    @IBOutlet weak var doneButton: UIButton?
    
    // Data from previous screen
    var email: String?
    
    // Convenience array for handling fields
    private var otpFields: [UITextField] {
        return [otpField1, otpField2, otpField3, otpField4].compactMap { $0 }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Enter OTP"
        setupUI()
        setupFields()
        updateDoneButtonState()
    }
    
    private func setupUI() {
        doneButton?.setTitle("Done", for: .normal)
        doneButton?.layer.cornerRadius = 12
        doneButton?.isEnabled = false
        // style fields if desired
        for tf in otpFields {
            tf.keyboardType = .numberPad
            tf.textAlignment = .center
            tf.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium)
            tf.layer.borderWidth = 1
            tf.layer.cornerRadius = 4
            tf.layer.borderColor = UIColor.systemGray3.cgColor
            tf.tintColor = .systemBlue
            tf.autocorrectionType = .no
            tf.delegate = self
            // allow one character only visually — we'll enforce in delegate
        }
        
        // Add a tap to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    private func setupFields() {
        // Clear fields and focus first
        for tf in otpFields { tf.text = "" }
        otpField1?.becomeFirstResponder()
        
        // Add editing changed so paste can trigger enable state
        for tf in otpFields {
            tf.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func textFieldEditingChanged(_ textField: UITextField) {
        // If user pasted a multi-digit value into one field, handle it
        if let text = textField.text, text.count > 1 {
            handlePaste(text)
            return
        }
        // Move to next when a character typed
        if let idx = otpFields.firstIndex(of: textField),
           let text = textField.text, text.count == 1 {
            let nextIndex = idx + 1
            if nextIndex < otpFields.count {
                otpFields[nextIndex].becomeFirstResponder()
            } else {
                // last field filled -> dismiss keyboard optionally
                textField.resignFirstResponder()
            }
        }
        updateDoneButtonState()
    }
    
    private func handlePaste(_ pasted: String) {
        // keep only digits
        let digits = pasted.filter { $0.isNumber }
        guard digits.count > 0 else { return }
        
        // Fill the OTP fields with the first up-to-4 digits
        let chars = Array(digits)
        for i in 0..<otpFields.count {
            if i < chars.count {
                otpFields[i].text = String(chars[i])
            } else {
                otpFields[i].text = ""
            }
        }
        // focus after last filled field (or dismiss)
        if chars.count < otpFields.count {
            otpFields[chars.count].becomeFirstResponder()
        } else {
            view.endEditing(true)
        }
        updateDoneButtonState()
    }
    
    private func currentOTP() -> String {
        return otpFields.map { $0.text ?? "" }.joined()
    }
    
    private func updateDoneButtonState() {
        let otp = currentOTP()
        doneButton?.isEnabled = otp.count == otpFields.count
        doneButton?.alpha = (doneButton?.isEnabled ?? false) ? 1.0 : 0.6
    }
    
    // MARK: - Actions
    
    @IBAction func doneTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        let otp = currentOTP()
        
        // Ensure OTP is complete
        if otp.count != otpFields.count {
            // Optional: Show alert if incomplete (commented out as per your code)
            // showAlert(title: "Incomplete OTP", message: "Please enter the full code.")
            return
        }
        
        // --- NAVIGATION LOGIC ---
        let newPasswordVC = NewPasswordViewController(nibName: "NewPasswordViewController", bundle: nil)
        
        if let nav = navigationController {
            nav.pushViewController(newPasswordVC, animated: true)
        } else {
            newPasswordVC.modalPresentationStyle = .fullScreen
            present(newPasswordVC, animated: true, completion: nil)
        }
    }
}
    // MARK: - UITextFieldDelegate
    extension EnterOTPViewController: UITextFieldDelegate {
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Allow only digits and single character per field (we handle paste separately)
            if string.count > 1 {
                // This is a paste (multi-char). Allow paste -> will be handled in editingChanged
                return true
            }
            
            // Backspace: when replacement string is empty
            if string.isEmpty {
                // Clear current field and move to previous if empty after deletion
                textField.text = ""
                if let idx = otpFields.firstIndex(of: textField), idx > 0 {
                    otpFields[idx - 1].becomeFirstResponder()
                    // also clear previous if it had something? keep previous value
                }
                updateDoneButtonState()
                return false
            }
            
            // Only accept digits
            guard let _ = string.first, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) else {
                return false
            }
            
            // Set the single digit and move focus
            textField.text = string
            if let idx = otpFields.firstIndex(of: textField) {
                let next = idx + 1
                if next < otpFields.count {
                    otpFields[next].becomeFirstResponder()
                } else {
                    textField.resignFirstResponder()
                }
            }
            updateDoneButtonState()
            // We returned false because we manually set text
            return false
        }
        
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            // Selecting a field: if earlier fields are empty, move focus to first empty field
            for tf in otpFields {
                if (tf.text ?? "").isEmpty {
                    // if the tapped field is after this empty one, move focus to this empty field
                    if let tappedIndex = otpFields.firstIndex(of: textField), let firstEmptyIndex = otpFields.firstIndex(of: tf), tappedIndex > firstEmptyIndex {
                        otpFields[firstEmptyIndex].becomeFirstResponder()
                        return false
                    }
                    break
                }
            }
            return true
        }
    }
