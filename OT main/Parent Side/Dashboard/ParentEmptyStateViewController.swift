import Supabase
import UIKit

class ParentEmptyStateViewController: UIViewController {

    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "No Patient Added"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter the 5-digit Patient ID provided by your therapist to get started."
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let idTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "00000"
        tf.font = .systemFont(ofSize: 32, weight: .bold)
        tf.textAlignment = .center
        tf.keyboardType = .numberPad
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 15
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.systemGray5.cgColor
        tf.heightAnchor.constraint(equalToConstant: 70).isActive = true
        return tf
    }()

    private lazy var linkButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Link Patient", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.layer.cornerRadius = 25
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        btn.addTarget(self, action: #selector(handleLinkTap), for: .touchUpInside)
        return btn
    }()

    private lazy var logoutButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Logout", for: .normal)
        btn.setTitleColor(.systemRed, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        return btn
    }()

    private let mainStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let spinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Properties
    private var isLoading = false {
        didSet { updateButtonState() }
    }

    // MARK: - Lifecycle
    override func loadView() {
        self.view = ParentGradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHierarchy()
        setupConstraints()
        setupSpinner()
        idTextField.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    private func setupHierarchy() {
        view.addSubview(mainStack)
        mainStack.addArrangedSubview(titleLabel)
        mainStack.addArrangedSubview(descriptionLabel)
        mainStack.addArrangedSubview(idTextField)
        mainStack.addArrangedSubview(linkButton)
        mainStack.addArrangedSubview(logoutButton)
        
        mainStack.setCustomSpacing(30, after: linkButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    private func setupSpinner() {
        linkButton.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: linkButton.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: linkButton.centerYAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func handleLogout() {
        Task {
            do {
                // 1. Sign out from Supabase
                try await supabase.auth.signOut()
                
                await MainActor.run {
                    // 2. Safely find the active window
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first else {
                        return
                    }
                    
                    // 3. Prepare the login flow
                    let loginVC = NewLoginViewController()
                    let nav = UINavigationController(rootViewController: loginVC)
                    
                    // 4. Reset Root safely
                    window.rootViewController = nav
                    
                    // 5. Use the window we just found for the transition
                    UIView.transition(with: window,
                                     duration: 0.5,
                                     options: .transitionCrossDissolve,
                                     animations: nil)
                }
            } catch {
                print("Logout failed: \(error)")
                // Fallback: Even if sign out fails locally, force the user to login screen
                self.forceToLogin()
            }
        }
    }

    // Helper to prevent code duplication
    private func forceToLogin() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.rootViewController = UINavigationController(rootViewController: NewLoginViewController())
    }

    @objc private func handleLinkTap() {
        guard let code = idTextField.text, code.count == 5 else { return }
        isLoading = true

        Task {
            do {
                let user = try await supabase.auth.session.user
                let currentUID = user.id

                // Step 1: Update Patients Table (This part is working for you now)
                try await supabase
                    .from("patients")
                    .update(["parent_uid": currentUID.uuidString])
                    .eq("patient_id_number", value: code)
                    .execute()
                print("DEBUG: Patients table linked successfully")

                // Step 2: Update Profiles Table (The part that is failing)
                // Ensure 'linked_patient_id' is the EXACT column name in your profiles table
                let profileResponse = try await supabase
                    .from("profiles")
                    .update(["linked_patient_id": code])
                    .eq("id", value: currentUID)
                    .select() // Force return data to verify
                    .execute()

                // Verify if the profile update actually happened
                if profileResponse.data.isEmpty {
                     print("DEBUG: ⚠️ Profile update failed - likely an RLS issue or wrong ID")
                     throw NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: "Profile update blocked by database."])
                }

                print("DEBUG: Profiles table linked successfully with code: \(code)")

                await MainActor.run {
                    self.showSuccessAnimation()
                }
            } catch {
                print("DEBUG: ❌ Link Error: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    self.showAlert(message: "Linking failed. Please try again.")
                }
            }
        }
    }
    private func showSuccessAnimation() {
        isLoading = false
        linkButton.setTitle("", for: .normal)
        
        // Haptic Feedback Trigger
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = .white
        checkmark.contentMode = .scaleAspectFit
        checkmark.alpha = 0
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        linkButton.addSubview(checkmark)
        
        NSLayoutConstraint.activate([
            checkmark.centerXAnchor.constraint(equalTo: linkButton.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: linkButton.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 30),
            checkmark.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            checkmark.alpha = 1
            checkmark.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.proceedToDashboard()
            }
        }
    }

    private func updateButtonState() {
        if isLoading {
            linkButton.setTitle("", for: .normal)
            spinner.startAnimating()
            linkButton.isEnabled = false
        } else {
            linkButton.setTitle("Link Patient", for: .normal)
            spinner.stopAnimating()
            linkButton.isEnabled = true
        }
    }

    private func proceedToDashboard() {
            // SUCCESS: The 5-digit code worked.
            // We find the window robustly through the connected scenes to avoid nil crashes
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return
            }

            let mainAppTabBar = ParentTabBarViewController()
            
            // Update Root View Controller to the full dashboard
            window.rootViewController = mainAppTabBar
            
            // Smooth transition to signify the app is "unlocking"
            UIView.transition(with: window,
                              duration: 0.5,
                              options: .transitionFlipFromRight,
                              animations: nil)
        }

    @objc private func dismissKeyboard() { view.endEditing(true) }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Invalid ID", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension ParentEmptyStateViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= 5 && updatedText.allSatisfy { $0.isNumber }
    }
}
