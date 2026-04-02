import UIKit
import Supabase

class StudentProfileViewController: UIViewController {

    // MARK: - Data
    private var linkedPatients: [Patient] = []
    private var currentPatient: Patient?
    private let lastSelectedChildIDKey = "LastSelectedChildID"

    // Rebuilt after every fetch
    private var mainItems: [String] = []      // chevron rows
    private var switchItems: [String] = []    // switch child rows (also chevron)
    private var unlinkItems: [String] = []    // red, no chevron
    private let logoutItem = "Log out"

    // MARK: - UI Components
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
        iv.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
        iv.tintColor = .systemGray
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.borderWidth = 3
        iv.layer.borderColor = UIColor.white.cgColor
        return iv
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

    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .black
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    // MARK: - Lifecycle
    override func loadView() {
        self.view = ParentGradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        setupTableView()
        setupHeaderView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyNavBarAppearance()
        navigationController?.setNavigationBarHidden(false, animated: animated)
        fetchAllLinkedPatients()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
    }

    // MARK: - Nav Bar
    private func applyNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .black
    }

    // MARK: - Table Setup
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupHeaderView() {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 180))
        header.addSubview(profileImageView)
        header.addSubview(nameLabel)
        header.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: header.topAnchor, constant: 10),
            profileImageView.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            activityIndicator.centerXAnchor.constraint(equalTo: nameLabel.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor)
        ])
        tableView.tableHeaderView = header
    }

    // MARK: - Data Fetching
    private func fetchAllLinkedPatients() {
        activityIndicator.startAnimating()
        nameLabel.text = ""
        Task {
            do {
                let user = try await supabase.auth.session.user
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                decoder.dateDecodingStrategy = .formatted(formatter)
                let response = try await supabase
                    .from("patients").select()
                    .eq("parent_uid", value: user.id.uuidString).execute()
                let fetched = try decoder.decode([Patient].self, from: response.data)
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.linkedPatients = fetched
                    if let lastID = UserDefaults.standard.string(forKey: self.lastSelectedChildIDKey),
                       let saved = fetched.first(where: { $0.patientID == lastID }) {
                        self.currentPatient = saved
                    } else {
                        self.currentPatient = fetched.first
                    }
                    self.updateHeaderUI()
                    self.rebuildMenu()
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.nameLabel.text = "Error loading"
                }
            }
        }
    }

    private func updateHeaderUI() {
        guard let patient = currentPatient else { nameLabel.text = "No child linked"; return }
        nameLabel.text = patient.fullName
        if let url = patient.imageURL {
            let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
            let placeholder = UIImage(systemName: "person.circle.fill", withConfiguration: config)
            profileImageView.loadImage(from: url, placeholder: placeholder)
        }
    }

    private func rebuildMenu() {
        mainItems = ["Update Profile", "Settings"]
        if linkedPatients.count < 2 { mainItems.append("Add Second Child") }

        let others = linkedPatients.filter { $0.patientID != currentPatient?.patientID }
        switchItems = others.map { "Switch to \($0.firstName)'s Profile" }

        unlinkItems = []
        if let name = currentPatient?.firstName { unlinkItems.append("Unlink \(name)") }
    }

    // MARK: - Number of sections
    // Section 0 = main (Update Profile, Settings, Add Second Child)
    // Section 1 = switch children (optional)
    // Section 2 = unlink + logout
    private var hasSwitchSection: Bool { !switchItems.isEmpty }

    private func destructiveSection() -> Int { hasSwitchSection ? 2 : 1 }

    // MARK: - Action Routing
    private func handleTap(title: String) {
        switch title {
        case "Update Profile":
            let vc = ParentUpdateProfileViewController()
            vc.patient = self.currentPatient
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "Settings":
            let vc = SettingsViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "Add Second Child":
            showAddChildPopup()
        case "Log out":
            handleLogoutConfirmation()
        default:
            if title.hasPrefix("Switch to ") {
                // derive patientID from the matching switchItem index
                let others = linkedPatients.filter { $0.patientID != currentPatient?.patientID }
                if let match = others.first(where: { "Switch to \($0.firstName)'s Profile" == title }) {
                    switchToPatient(withID: match.patientID)
                }
            } else if title.hasPrefix("Unlink ") {
                handleUnlink()
            }
        }
    }

    // MARK: - Business Logic
    private func switchToPatient(withID id: String) {
        guard let target = linkedPatients.first(where: { $0.patientID == id }) else { return }
        Task {
            do {
                let user = try await supabase.auth.session.user
                try await supabase.from("profiles")
                    .update(["linked_patient_id": id])
                    .eq("id", value: user.id).execute()
                await MainActor.run {
                    UserDefaults.standard.set(id, forKey: self.lastSelectedChildIDKey)
                    UIView.transition(with: self.view, duration: 0.35, options: .transitionCrossDissolve) {
                        self.currentPatient = target
                        self.updateHeaderUI()
                        self.rebuildMenu()
                        self.tableView.reloadData()
                    }
                }
            } catch { print("Switch error: \(error)") }
        }
    }

    private func handleUnlink() {
        guard let patient = currentPatient else { return }
        Task {
            do {
                let user = try await supabase.auth.session.user
                try await supabase.from("patients")
                    .update(["parent_uid": String?.none])
                    .eq("patient_id_number", value: patient.patientID).execute()
                let resp = try await supabase.from("profiles")
                    .select("linked_patient_id, linked_patient_id_2")
                    .eq("id", value: user.id).single().execute()
                let data = try JSONSerialization.jsonObject(with: resp.data) as? [String: Any]
                let slot1 = data?["linked_patient_id"] as? String
                let isSlot1 = (slot1 == patient.patientID)
                let fieldToClear = isSlot1 ? "linked_patient_id" : "linked_patient_id_2"
                try await supabase.from("profiles")
                    .update([fieldToClear: String?.none])
                    .eq("id", value: user.id).execute()
                let remaining = isSlot1 ? (data?["linked_patient_id_2"] as? String) : slot1
                await MainActor.run {
                    if let next = remaining, !next.isEmpty {
                        self.showToast(message: "Unlinked. Returning to other profile.")
                        self.fetchAllLinkedPatients()
                    } else {
                        self.navigateToEmptyState()
                    }
                }
            } catch { print("Unlink error: \(error)") }
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
                let update = try await supabase.from("patients")
                    .update(["parent_uid": user.id.uuidString])
                    .eq("patient_id_number", value: code).select().execute()
                if update.data.isEmpty {
                    await MainActor.run { self.showToast(message: "Patient already linked to another profile.") }
                    return
                }
                let resp = try await supabase.from("profiles")
                    .select("linked_patient_id, linked_patient_id_2")
                    .eq("id", value: user.id).single().execute()
                let data = try JSONSerialization.jsonObject(with: resp.data) as? [String: Any]
                let slot1 = data?["linked_patient_id"] as? String
                let slot2 = data?["linked_patient_id_2"] as? String
                var field = ""
                if slot1 == nil || slot1?.isEmpty == true { field = "linked_patient_id" }
                else if slot2 == nil || slot2?.isEmpty == true { field = "linked_patient_id_2" }
                else { await MainActor.run { self.showToast(message: "Maximum 2 children reached.") }; return }
                try await supabase.from("profiles").update([field: code]).eq("id", value: user.id).execute()
                await MainActor.run { self.showToast(message: "Child added!"); self.fetchAllLinkedPatients() }
            } catch {
                await MainActor.run { self.showToast(message: "Error linking. Try again.") }
            }
        }
    }

    private func handleLogoutConfirmation() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to sign out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in self.performLogout() })
        present(alert, animated: true)
    }

    private func performLogout() {
        Task {
            try? await supabase.auth.signOut()
            await MainActor.run {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first else { return }
                let nav = UINavigationController(rootViewController: NewLoginViewController())
                nav.setNavigationBarHidden(true, animated: false)
                window.rootViewController = nav
            }
        }
    }

    private func navigateToEmptyState() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.rootViewController = UINavigationController(rootViewController: ParentEmptyStateViewController())
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: nil)
    }

    private func showToast(message: String) {
        let toast = UIView()
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.layer.cornerRadius = 20
        toast.translatesAutoresizingMaskIntoConstraints = false
        let label = UILabel()
        label.textColor = .white; label.text = message
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center; label.translatesAutoresizingMaskIntoConstraints = false
        toast.addSubview(label); view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.heightAnchor.constraint(equalToConstant: 40),
            label.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -20),
            label.centerYAnchor.constraint(equalTo: toast.centerYAnchor)
        ])
        toast.transform = CGAffineTransform(translationX: 0, y: -20); toast.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            toast.alpha = 1; toast.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseIn) {
                toast.alpha = 0; toast.transform = CGAffineTransform(translationX: 0, y: -20)
            } completion: { _ in toast.removeFromSuperview() }
        }
    }
}

// MARK: - UITableView DataSource & Delegate
extension StudentProfileViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        hasSwitchSection ? 3 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return mainItems.count
        case 1: return hasSwitchSection ? switchItems.count : (unlinkItems.count + 1) // unlink + logout
        case 2: return unlinkItems.count + 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.backgroundColor = .white

        let title: String
        let isDestructive: Bool
        let showChevron: Bool

        switch indexPath.section {
        case 0:
            title = mainItems[indexPath.row]
            isDestructive = false
            showChevron = true
        case 1 where hasSwitchSection:
            title = switchItems[indexPath.row]
            isDestructive = false
            showChevron = true
        default:
            // destructive section: unlink rows first, then logout
            let allDestructive = unlinkItems + [logoutItem]
            title = allDestructive[indexPath.row]
            isDestructive = true
            showChevron = false
        }

        cell.textLabel?.text = title
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.textLabel?.textColor = isDestructive ? .systemRed : .black
        cell.textLabel?.textAlignment = isDestructive ? .center : .natural
        cell.accessoryType = showChevron ? .disclosureIndicator : .none
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if hasSwitchSection && section == 1 { return "Switch Profile" }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let title: String
        switch indexPath.section {
        case 0:
            title = mainItems[indexPath.row]
        case 1 where hasSwitchSection:
            title = switchItems[indexPath.row]
        default:
            let allDestructive = unlinkItems + [logoutItem]
            title = allDestructive[indexPath.row]
        }

        handleTap(title: title)
    }
}
