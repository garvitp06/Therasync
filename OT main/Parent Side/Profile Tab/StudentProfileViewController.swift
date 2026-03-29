import UIKit
import Supabase

class StudentProfileViewController: UIViewController {
    
    // MARK: - UI Components
    private let gradientView = ParentGradientView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Profile"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemGray4
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.backgroundColor = .white
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Loading..."
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let listCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let itemsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Data Properties
    private var linkedPatients: [Patient] = []
    private var currentPatient: Patient?
    private let lastSelectedChildIDKey = "LastSelectedChildID"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchAllLinkedPatients()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientView.frame = view.bounds
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
    }
    
    // MARK: - Data Fetching
    private func fetchAllLinkedPatients() {
        Task {
            do {
                let user = try await supabase.auth.session.user
                
                // Fetch using custom date decoder to prevent DOB crash
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                decoder.dateDecodingStrategy = .formatted(formatter)
                
                let response = try await supabase
                    .from("patients")
                    .select()
                    .eq("parent_uid", value: user.id.uuidString)
                    .execute()
                
                let fetchedPatients = try decoder.decode([Patient].self, from: response.data)
                
                DispatchQueue.main.async {
                    self.linkedPatients = fetchedPatients
                    
                    // Logic: Persistence check
                    if let lastID = UserDefaults.standard.string(forKey: self.lastSelectedChildIDKey),
                       let savedPatient = fetchedPatients.first(where: { $0.patientID == lastID }) {
                        self.currentPatient = savedPatient
                    } else {
                        self.currentPatient = fetchedPatients.first
                    }
                    
                    self.updateHeaderUI()
                    self.addListItems()
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    private func updateHeaderUI() {
        guard let patient = currentPatient else { return }
        nameLabel.text = patient.fullName
        // Set profile image if imageURL exists...
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(gradientView)
        view.addSubview(titleLabel)
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(listCardView)
        listCardView.addSubview(itemsStackView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            profileImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            listCardView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24),
            listCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            listCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            itemsStackView.topAnchor.constraint(equalTo: listCardView.topAnchor, constant: 8),
            itemsStackView.bottomAnchor.constraint(equalTo: listCardView.bottomAnchor, constant: -8),
            itemsStackView.leadingAnchor.constraint(equalTo: listCardView.leadingAnchor, constant: 16),
            itemsStackView.trailingAnchor.constraint(equalTo: listCardView.trailingAnchor, constant: -16)
        ])
    }
    
    private func addListItems() {
        itemsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 1. Core Actions
        let menuItems = ["Update Profile", "Settings", "Add Second Child"]
        for title in menuItems {
            itemsStackView.addArrangedSubview(createListItemView(title: title, showChevron: true, isDestructive: false))
            itemsStackView.addArrangedSubview(createSeparatorView())
        }
        
        // 2. Profile Switcher
        let otherKids = linkedPatients.filter { $0.patientID != currentPatient?.patientID }
        for kid in otherKids {
            let item = createListItemView(title: "Switch to \(kid.firstName)'s Profile", showChevron: false, isDestructive: false)
            item.accessibilityIdentifier = "switch_\(kid.patientID)"
            itemsStackView.addArrangedSubview(item)
            itemsStackView.addArrangedSubview(createSeparatorView())
        }
        
        // 3. Unlink
        if let name = currentPatient?.firstName {
            let unlinkItem = createListItemView(title: "Unlink \(name)", showChevron: false, isDestructive: true)
            unlinkItem.accessibilityIdentifier = "unlink_action"
            itemsStackView.addArrangedSubview(unlinkItem)
            itemsStackView.addArrangedSubview(createSeparatorView())
        }
        
        itemsStackView.addArrangedSubview(createListItemView(title: "Log out", showChevron: false, isDestructive: true))
    }
    
    private func createListItemView(title: String, showChevron: Bool, isDestructive: Bool) -> UIButton {
        let itemView = UIButton(type: .system)
        itemView.translatesAutoresizingMaskIntoConstraints = false
        itemView.contentHorizontalAlignment = .leading
        if itemView.accessibilityIdentifier == nil { itemView.accessibilityIdentifier = title }
        itemView.addTarget(self, action: #selector(listItemTapped(_:)), for: .touchUpInside)
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = .systemFont(ofSize: 17)
        label.textColor = isDestructive ? .systemRed : .black
        itemView.addSubview(label)
        
        NSLayoutConstraint.activate([
            itemView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            label.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: itemView.centerYAnchor)
        ])
        
        if showChevron {
            let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevron.translatesAutoresizingMaskIntoConstraints = false
            chevron.tintColor = .systemGray
            itemView.addSubview(chevron)
            NSLayoutConstraint.activate([
                chevron.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
                chevron.centerYAnchor.constraint(equalTo: itemView.centerYAnchor),
                chevron.widthAnchor.constraint(equalToConstant: 8),
                chevron.heightAnchor.constraint(equalToConstant: 14)
            ])
        }
        return itemView
    }
    
    private func createSeparatorView() -> UIView {
        let view = UIView(); view.backgroundColor = .systemGray5; view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }
    
    // MARK: - Actions
    @objc private func listItemTapped(_ sender: UIButton) {
        guard let id = sender.accessibilityIdentifier else { return }
        
        if id == "Log out" {
            handleLogoutConfirmation() // Updated to show alert
        }
        else if id == "Settings" {
            let settingsVC = SettingsViewController() // Connected Settings
            settingsVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(settingsVC, animated: true)
        }
        else if id == "Add Second Child" {
            showAddChildPopup()
        }
        else if id == "unlink_action" {
            handleUnlink()
        }
        else if id == "Update Profile" {
            let updateVC = ParentUpdateProfileViewController()
            updateVC.patient = self.currentPatient
            navigationController?.pushViewController(updateVC, animated: true)
        }
        else if id.contains("switch_") {
            let patientID = id.replacingOccurrences(of: "switch_", with: "")
            switchToPatient(withID: patientID)
        }
    }
    
    private func switchToPatient(withID id: String) {
        guard let target = linkedPatients.first(where: { $0.patientID == id }) else { return }
        
        Task {
            do {
                let user = try await supabase.auth.session.user
                // Update the profile so the database knows this is now the 'Active' child
                try await supabase
                    .from("profiles")
                    .update(["linked_patient_id": id])
                    .eq("id", value: user.id)
                    .execute()
                
                await MainActor.run {
                    UserDefaults.standard.set(id, forKey: self.lastSelectedChildIDKey)
                    UIView.transition(with: self.view, duration: 0.4, options: .transitionCrossDissolve, animations: {
                        self.currentPatient = target
                        self.updateHeaderUI()
                        self.addListItems()
                    })
                }
            } catch {
                print("Switch Error: \(error)")
            }
        }
    }
    private func showToast(message: String) {
        let toastContainer = UIView()
        toastContainer.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastContainer.layer.cornerRadius = 20
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.textColor = .white
        label.text = message
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        toastContainer.addSubview(label)
        view.addSubview(toastContainer)
        
        NSLayoutConstraint.activate([
            toastContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            toastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastContainer.heightAnchor.constraint(equalToConstant: 40),
            label.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -20),
            label.centerYAnchor.constraint(equalTo: toastContainer.centerYAnchor)
        ])
        
        // Animation: Fade in and slide down
        toastContainer.transform = CGAffineTransform(translationX: 0, y: -20)
        toastContainer.alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            toastContainer.alpha = 1
            toastContainer.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseIn, animations: {
                toastContainer.alpha = 0
                toastContainer.transform = CGAffineTransform(translationX: 0, y: -20)
            }) { _ in
                toastContainer.removeFromSuperview()
            }
        }
    }
    private func handleUnlink() {
        guard let patient = currentPatient else { return }
        
        Task {
            do {
                let user = try await supabase.auth.session.user
                
                // 1. Remove parent_uid from patients table
                try await supabase.from("patients")
                    .update(["parent_uid": String?.none])
                    .eq("patient_id_number", value: patient.patientID).execute()

                // 2. Determine which profile slot to clear
                let profileResponse = try await supabase.from("profiles")
                    .select("linked_patient_id, linked_patient_id_2")
                    .eq("id", value: user.id).single().execute()
                
                let data = try JSONSerialization.jsonObject(with: profileResponse.data) as? [String: Any]
                let slot1 = data?["linked_patient_id"] as? String
                
                let isSlot1 = (slot1 == patient.patientID)
                let fieldToClear = isSlot1 ? "linked_patient_id" : "linked_patient_id_2"
                
                // 3. Clear that specific slot
                try await supabase.from("profiles")
                    .update([fieldToClear: String?.none])
                    .eq("id", value: user.id).execute()

                // 4. Check if the OTHER slot still has a child
                let remainingChildCode = isSlot1 ? (data?["linked_patient_id_2"] as? String) : slot1

                await MainActor.run {
                    if let nextCode = remainingChildCode, !nextCode.isEmpty {
                        // Patient A still exists! Refresh the dashboard for them.
                        self.showToast(message: "Unlinked. Returning to other profile.")
                        self.fetchAllLinkedPatients() // This will find the remaining child
                    } else {
                        // No children left in either slot
                        self.navigateToEmptyState()
                    }
                }
            } catch {
                print("Unlink error: \(error)")
            }
        }
    }
    private func navigateToEmptyState() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let emptyVC = ParentEmptyStateViewController()
        window.rootViewController = UINavigationController(rootViewController: emptyVC)
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: nil)
    }
    private func updateProfileLink(to code: String?, for userID: UUID) {
        Task {
            try? await supabase.from("profiles")
                .update(["linked_patient_id": code])
                .eq("id", value: userID)
                .execute()
        }
    }
    private func showAddChildPopup() {
        let alert = UIAlertController(title: "Link Child", message: "Enter 5-digit code", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "00000"; $0.keyboardType = .numberPad }
        alert.addAction(UIAlertAction(title: "Link", style: .default) { _ in
            guard let code = alert.textFields?.first?.text, code.count == 5 else { return }
            self.performLink(code: code)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func performLink(code: String) {
        Task {
            do {
                let user = try await supabase.auth.session.user
                let currentUID = user.id.uuidString

                // Step 1: Attempt to claim the patient.
                // We use .select() to verify if the row was actually updated.
                let patientUpdate = try await supabase
                    .from("patients")
                    .update(["parent_uid": currentUID])
                    .eq("patient_id_number", value: code)
                    .select()
                    .execute()

                // CHECK: If response data is empty, the RLS policy blocked the update
                // because the patient is already linked to another account (ID 1).
                if patientUpdate.data.isEmpty {
                    await MainActor.run {
                        self.showToast(message: "Patient already linked to another profile.")
                    }
                    return // Exit immediately; DO NOT update the profile slots.
                }

                // Step 2: Only if Step 1 succeeded, find an empty slot in the profile
                let profileResponse = try await supabase.from("profiles")
                    .select("linked_patient_id, linked_patient_id_2")
                    .eq("id", value: user.id).single().execute()
                
                let data = try JSONSerialization.jsonObject(with: profileResponse.data) as? [String: Any]
                let slot1 = data?["linked_patient_id"] as? String
                let slot2 = data?["linked_patient_id_2"] as? String
                
                var updateField = ""
                if slot1 == nil || slot1?.isEmpty == true {
                    updateField = "linked_patient_id"
                } else if slot2 == nil || slot2?.isEmpty == true {
                    updateField = "linked_patient_id_2"
                } else {
                    await MainActor.run { self.showToast(message: "Maximum 2 children reached.") }
                    return
                }

                // Step 3: Update the identified profile slot
                try await supabase.from("profiles")
                    .update([updateField: code])
                    .eq("id", value: user.id).execute()

                await MainActor.run {
                    self.showToast(message: "Child added successfully!")
                    self.fetchAllLinkedPatients()
                }
            } catch {
                print("Link Error: \(error)")
                await MainActor.run {
                    self.showToast(message: "Error linking patient. Please try again.")
                }
            }
        }
    }
    private func handleLogoutConfirmation() {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to sign out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            self.performLogout()
        })
        present(alert, animated: true)
    }
    
    private func performLogout() {
        Task {
            // 1. Sign out from Supabase
            try? await supabase.auth.signOut()
            
            await MainActor.run {
                // 2. Safely find the window through the connected scenes
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first else {
                    return
                }
                
                // 3. Setup the Login Flow
                let loginVC = NewLoginViewController()
                let nav = UINavigationController(rootViewController: loginVC)
                
                // 4. Update the Root View Controller
                window.rootViewController = nav
                
                // 5. Use safe transition
                UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: nil)
            }
        }
    }
}
