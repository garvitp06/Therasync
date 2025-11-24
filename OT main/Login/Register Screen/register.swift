//
//  register.swift
//  OT main
//
//  Created by Garvit Pareek on 14/11/2025.
//

import UIKit

class register: UIViewController {
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        updateBackground(animated: true)
        updateFormFields()
    }
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var gradientBG: segGradientView!
    
    
    let blueTopColor = UIColor(red: 0.0, green: 122/255, blue: 1.0, alpha: 1.0)
    let whiteColor = UIColor.systemGray5
        
        // This is the yellow/orange from your image
    let yellowTopColor = UIColor(red: 255/255, green: 166/255, blue: 0/255, alpha: 1.0)
    @objc func didTapCustomBack() {
        // If pushed, pop. If presented, dismiss.
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            
            // This makes it a perfect pill shape
            // We do it here because we need the final height of the control
            segmentedControl.layer.cornerRadius = segmentedControl.bounds.height / 2
            segmentedControl.layer.masksToBounds = true
        }
    
    func updateBackground(animated: Bool) {
            let newTopColor: UIColor
            if segmentedControl.selectedSegmentIndex == 0 {
                // First segment: Blue
                newTopColor = blueTopColor
            } else {
                // Second segment: Yellow
                newTopColor = yellowTopColor
            }
            
            let titleColor: UIColor = (segmentedControl.selectedSegmentIndex == 0) ? .white : .black
            
            // Animate the color change
            if animated {
                UIView.transition(with: gradientBG, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    self.gradientBG.topColor = newTopColor
                    self.gradientBG.bottomColor = self.whiteColor
                    
                    if let navBar = self.navigationController?.navigationBar {
                        let appearance = UINavigationBarAppearance()
                        appearance.configureWithOpaqueBackground()
                        appearance.backgroundColor = navBar.standardAppearance.backgroundColor
                        appearance.titleTextAttributes = [.foregroundColor: titleColor]
                        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
                        navBar.standardAppearance = appearance
                        navBar.scrollEdgeAppearance = appearance
                        navBar.compactAppearance = appearance
                        navBar.tintColor = titleColor == .white ? .white : .black
                    }
                })
            } else {
                // Set immediately
                gradientBG.topColor = newTopColor
                gradientBG.bottomColor = whiteColor
                
                if let navBar = self.navigationController?.navigationBar {
                    let appearance = UINavigationBarAppearance()
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundColor = navBar.standardAppearance.backgroundColor
                    appearance.titleTextAttributes = [.foregroundColor: titleColor]
                    appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
                    navBar.standardAppearance = appearance
                    navBar.scrollEdgeAppearance = appearance
                    navBar.compactAppearance = appearance
                    navBar.tintColor = titleColor == .white ? .white : .black
                }
            }
        }
    func setupSegmentedControl() {
            // 1. Define your colors
        _ = segmentedControl.backgroundColor ?? UIColor.systemBlue
            let whiteColor = UIColor.white
            let blackColor = UIColor.black
            
            // 2. Set the text color for both states
            // Unselected state
            segmentedControl.setTitleTextAttributes([.foregroundColor: blackColor], for: .normal)
            // Selected state
            segmentedControl.setTitleTextAttributes([.foregroundColor: blackColor], for: .selected)
            
            // 3. Add the outer white border (like in your image)
            segmentedControl.layer.borderColor = whiteColor.cgColor
            segmentedControl.layer.borderWidth = 2.0 // You can adjust this thickness
        }

    func createUnderlinedTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        
        // Add some padding to the left
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        textField.leftViewMode = .always
        
        return textField
    }
    func createSeparatorLine() -> UIView {
        let underlineView = UIView()
        underlineView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        underlineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return underlineView
    }
    
        lazy var patientNameField = createUnderlinedTextField(placeholder: "Patient Name")
        lazy var firstNameField = createUnderlinedTextField(placeholder: "First Name")
        lazy var lastNameField = createUnderlinedTextField(placeholder: "Last Name")
        lazy var contactNoField = createUnderlinedTextField(placeholder: "Contact No.")
        
        lazy var nbcotField = createUnderlinedTextField(placeholder: "NBCOT Number")
        lazy var degreeField = createUnderlinedTextField(placeholder: "Relevant Degree")
        lazy var experienceField = createUnderlinedTextField(placeholder: "Years of Experience")

        lazy var emailField = createUnderlinedTextField(placeholder: "Email ID")
        lazy var passwordField: UITextField = {
            let textField = createUnderlinedTextField(placeholder: "New Password")
            textField.isSecureTextEntry = true // <-- This hides the text
            return textField
        }()

        lazy var verifyPasswordField: UITextField = {
            let textField = createUnderlinedTextField(placeholder: "Verify Password")
            textField.isSecureTextEntry = true // <-- This hides the text
            return textField
        }()
        lazy var separator1 = createSeparatorLine()
        lazy var separator2 = createSeparatorLine()
        lazy var separator3 = createSeparatorLine()
        lazy var separator4 = createSeparatorLine()
    // MARK: - Section Labels & Button
        
        private func createSectionLabel(text: String) -> UILabel {
            let label = UILabel()
            label.text = text
            // Use a semi-bold, slightly smaller font, in a gray color
            label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            label.textColor = UIColor(white: 0.4, alpha: 1.0)
            return label
        }

        lazy var basicDetailsLabel: UILabel = createSectionLabel(text: "Basic Details")
        
        lazy var professionalDetailsLabel: UILabel = createSectionLabel(text: "Professional Details")
        
        lazy var emailLabel: UILabel = createSectionLabel(text: "Email & Password")
        
        lazy var registerButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Register", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            button.backgroundColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1.0)
            button.layer.cornerRadius = 28 // Half of height
            button.heightAnchor.constraint(equalToConstant: 56).isActive = true
            // Add action:
            // button.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
            return button
        }()

    lazy var basicDetailsStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [
                patientNameField,
                separator1,
                firstNameField,
                separator2,
                lastNameField,
                separator3,
                contactNoField
                // We DON'T add separator4 here, so there is no line at the bottom
            ])
            stack.axis = .vertical
            stack.spacing = 16
            stack.translatesAutoresizingMaskIntoConstraints = false
            return stack
        }()
    lazy var basicDetailsCard: UIView = {
            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 35 // Made it more round
            card.translatesAutoresizingMaskIntoConstraints = false
            return card
        }()
        
    lazy var professionalDetailsCard: UIView = {
            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 35
            card.translatesAutoresizingMaskIntoConstraints = false
            return card
        }()
            
        // REPLACE your old emailCard with this one
    lazy var emailCard: UIView = {
            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 35
            card.translatesAutoresizingMaskIntoConstraints = false
            return card
        }()
    lazy var professionalStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [
                nbcotField,
                createSeparatorLine(),
                degreeField,
                createSeparatorLine(),
                experienceField
            ])
            stack.axis = .vertical
            stack.spacing = 16
            stack.translatesAutoresizingMaskIntoConstraints = false
            return stack
        }()
        
        lazy var emailStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [
                emailField,
                createSeparatorLine(),
                passwordField,
                createSeparatorLine(),
                verifyPasswordField
            ])
            stack.axis = .vertical
            stack.spacing = 16
            stack.translatesAutoresizingMaskIntoConstraints = false
            return stack
        }()
        // --- Main Stack View ---
        // This will hold all the cards
        lazy var mainStackView: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [
                basicDetailsLabel,basicDetailsCard,professionalDetailsLabel, professionalDetailsCard, emailLabel,emailCard,registerButton
            ])
            stack.axis = .vertical
            stack.spacing = 16 // Space between the cards
            return stack
        }()
        
        // MARK: - Layout
    func setupCustomSpacing() {
            // Space between segment control and first label
//            mainStackView.setCustomSpacing(30, after: segmentedControl)
            
            // Space between label and its card (small)
            mainStackView.setCustomSpacing(12, after: basicDetailsLabel)
            mainStackView.setCustomSpacing(12, after: professionalDetailsLabel)
            mainStackView.setCustomSpacing(12, after: emailLabel)
            
            // Space between card and next label (large)
            mainStackView.setCustomSpacing(24, after: basicDetailsCard)
            mainStackView.setCustomSpacing(24, after: professionalDetailsCard)
            
            // Space between last card and register button (large)
            mainStackView.setCustomSpacing(40, after: emailCard)
        }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 1. Force the navigation bar to SHOW
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // 2. Configure Transparent Appearance (so gradient shows)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // 3. Set Title Color based on current segment (White for OT, Black for Parent)
        let titleColor: UIColor = (segmentedControl.selectedSegmentIndex == 0) ? .white : .black
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
        
        // 4. Apply Appearance
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        // 5. Set Button Color (Back arrow)
        navigationController?.navigationBar.tintColor = titleColor
    }
    func setupLayout() {
            // 1. Create and add the ScrollView
            let scrollView = UIScrollView()
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(scrollView)
        
            // 2. Create the ContentView
            let contentView = UIView()
            contentView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(contentView)
        
            // 3. Add your mainStackView to the *ContentView*
            contentView.addSubview(mainStackView)
            mainStackView.translatesAutoresizingMaskIntoConstraints = false // Good, you have this
        
            // 4. Set constraints
            NSLayoutConstraint.activate([
                // --- ScrollView ---
                
                //  THIS IS THE CRITICAL FIX:
                //  Pin the ScrollView's Top to the XIB SegmentedControl's Bottom
                scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20), // 20 points of space
                
                // Pin the rest to the screen edges
                scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                // --- ContentView ---
                contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

                // --- MainStackView ---
                mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0), // No space needed
                mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
                mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
        }
    @objc func registerTapped() {
        // 1. Get the text safely
        let password = passwordField.text ?? ""
        let verify = verifyPasswordField.text ?? ""
        
        // 2. Check if fields are empty
        if password.isEmpty || verify.isEmpty {
            showAlert(message: "Please fill in both password fields.")
            return
        }
        
        // 3. Check if passwords match
        if password != verify {
            // --- THIS IS THE POPUP ---
            showAlert(message: "Passwords do not match. Please try again.")
            return // Stop here, do not go back
        }
        
        // 4. If successful, go back to Login screen
        print("Passwords match, registering...")
        navigationController?.popViewController(animated: true)
    }
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Registration", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    func updateFormFields() {
            let isTherapist = segmentedControl.selectedSegmentIndex == 0
            
            // Animate the changes
            UIView.animate(withDuration: 0.3) {
                
                // 1. Show/Hide Professional Details
                self.professionalDetailsCard.isHidden = !isTherapist
                self.professionalDetailsLabel.isHidden = !isTherapist
                
                // 2. THIS IS THE FIX:
                // Hide the "Patient Name" field and its line
                self.patientNameField.isHidden = isTherapist
                self.separator1.isHidden = isTherapist
                
                // 3. Update placeholders
                self.firstNameField.placeholder = isTherapist ? "First Name" : "Parent First Name"
                self.lastNameField.placeholder = isTherapist ? "Last Name" : "Parent Last Name"
                
                // This forces the stack view to re-layout
                self.view.layoutIfNeeded()
            }
        }
    override func viewDidLoad() {
        super.viewDidLoad()
        updateBackground(animated: false)
        
        
        self.title = "Create Account"
        // Initial appearance will be set by updateBackground(animated:) based on selected segment
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(didTapCustomBack)
        
        )
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = backButton
        // --- ADD CONTENT TO ALL CARDS ---

                // 1. Add content to basicDetailsCard
                basicDetailsCard.addSubview(basicDetailsStack)
                
                // 2. Add content to professionalDetailsCard
                professionalDetailsCard.addSubview(professionalStack)

                // 3. Add content to emailCard
                emailCard.addSubview(emailStack)
                    
                // REPLACE your old constraints block with this one
        // REPLACE your old constraints block with this one
                NSLayoutConstraint.activate([
                    // --- Constraints for basicDetailsCard ---
                    basicDetailsStack.topAnchor.constraint(equalTo: basicDetailsCard.topAnchor, constant: 20),
                    basicDetailsStack.bottomAnchor.constraint(equalTo: basicDetailsCard.bottomAnchor, constant: -20),
                    basicDetailsStack.leadingAnchor.constraint(equalTo: basicDetailsCard.leadingAnchor, constant: 20),
                    basicDetailsStack.trailingAnchor.constraint(equalTo: basicDetailsCard.trailingAnchor, constant: -20),
                    
                    // --- Constraints for other cards ---
                    professionalStack.topAnchor.constraint(equalTo: professionalDetailsCard.topAnchor, constant: 20),
                    professionalStack.bottomAnchor.constraint(equalTo: professionalDetailsCard.bottomAnchor, constant: -20),
                    professionalStack.leadingAnchor.constraint(equalTo: professionalDetailsCard.leadingAnchor, constant: 20),
                    professionalStack.trailingAnchor.constraint(equalTo: professionalDetailsCard.trailingAnchor, constant: -20),
                    
                    emailStack.topAnchor.constraint(equalTo: emailCard.topAnchor, constant: 20),
                    emailStack.bottomAnchor.constraint(equalTo: emailCard.bottomAnchor, constant: -20),
                    emailStack.leadingAnchor.constraint(equalTo: emailCard.leadingAnchor, constant: 20),
                    emailStack.trailingAnchor.constraint(equalTo: emailCard.trailingAnchor, constant: -20)
                ])
        setupSegmentedControl()
        setupLayout()
        setupCustomSpacing()
        updateFormFields()
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
