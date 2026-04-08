import UIKit
class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    enum Section: String, CaseIterable {
        case notifications = "Notifications"
        case sensory = "Sensory & Accessibility"
        case security = "Security & Access"
        case support = "Support"
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Listen for theme changes to refresh table appearance and Nav Bar colors
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUI), name: NSNotification.Name("AppThemeChanged"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 1. Force the bar to be visible
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tabBarController?.tabBar.isHidden = true
        // 2. Apply centered small title styling
        setupNavBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only hide the bar when going BACK to Dashboard/Profile, not when pushing child VCs
        if isMovingFromParent {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func refreshUI() {
        setupNavBar()
        tableView.reloadData()
    }
    
    private func setupNavBar() {
        title = "Settings"
        
        // Disable Large Titles to ensure the title is small and centered
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        let isDark = UserDefaults.standard.bool(forKey: "Dark Mode")
        let color: UIColor = isDark ? .white : .black
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        
        // Set Centered Title Attributes
        appearance.titleTextAttributes = [
            .foregroundColor: color,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        // Back Button styling
        let backBtn = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(handleBack))
        backBtn.tintColor = color
        navigationItem.leftBarButtonItem = backBtn
    }
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    private func setupUI() {
        let bg = ParentGradientView()
        bg.frame = view.bounds
        view.addSubview(bg)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Stop the table from jumping to accommodate the bar height automatically
        tableView.contentInsetAdjustmentBehavior = .never
        // Remove empty top space in insetGrouped style
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            // FIXED: Pin to safeAreaLayoutGuide.topAnchor with constant for breathing room
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    // MARK: - TableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section.allCases[section].rawValue
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .dynamicLabel
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .notifications: return 2
        case .sensory: return 3
        case .security: return 2
        case .support: return 1
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "settingCell")
        cell.backgroundColor = .dynamicCard
        cell.textLabel?.textColor = .dynamicLabel
        
        let section = Section.allCases[indexPath.section]
        
        switch section {
        case .notifications:
            if indexPath.row == 0 {
                setupSwitchCell(cell, title: "Assignment Reminders", key: "assignmentReminders")
            } else {
                setupSwitchCell(cell, title: "Message Alerts", key: "messageAlerts")
            }
        case .sensory:
            if indexPath.row == 0 {
                setupSwitchCell(cell, title: "Global Haptics", key: "Global Haptics")
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Audio Volume Limiter"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "Color Themes & Motion"
                cell.accessoryType = .disclosureIndicator
            }
        case .security:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Linked Caregivers"
                cell.accessoryType = .disclosureIndicator
            } else {
                setupFaceIDCell(cell)
            }
        case .support:
            cell.textLabel?.text = "Report Technical Issue"
            cell.textLabel?.textColor = .systemBlue
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
    
    // MARK: - Helper Cell Builders
    
    private func setupSwitchCell(_ cell: UITableViewCell, title: String, key: String) {
        cell.textLabel?.text = title
        let switchView = UISwitch()
        switchView.isOn = UserDefaults.standard.bool(forKey: key)
        switchView.onTintColor = .systemBlue
        switchView.accessibilityIdentifier = key
        switchView.addTarget(self, action: #selector(generalToggleChanged(_:)), for: .valueChanged)
        cell.accessoryView = switchView
        cell.selectionStyle = .none
    }
    private func setupFaceIDCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = "FaceID Lock"
        let switchView = UISwitch()
        switchView.isOn = UserDefaults.standard.bool(forKey: "isFaceIDEnabled")
        switchView.onTintColor = .systemBlue
        switchView.addTarget(self, action: #selector(faceIDToggleChanged(_:)), for: .valueChanged)
        cell.accessoryView = switchView
        cell.selectionStyle = .none
    }
    // MARK: - Actions
    
    @objc private func generalToggleChanged(_ sender: UISwitch) {
        if let key = sender.accessibilityIdentifier {
            UserDefaults.standard.set(sender.isOn, forKey: key)
        }
    }
    @objc private func faceIDToggleChanged(_ sender: UISwitch) {
        if sender.isOn {
            BiometricAuthManager.shared.authenticateUser { success, _ in
                DispatchQueue.main.async {
                    if !success {
                        sender.setOn(false, animated: true)
                        UserDefaults.standard.set(false, forKey: "isFaceIDEnabled")
                    } else {
                        UserDefaults.standard.set(true, forKey: "isFaceIDEnabled")
                    }
                }
            }
        } else {
            UserDefaults.standard.set(false, forKey: "isFaceIDEnabled")
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = Section.allCases[indexPath.section]
        
        switch section {
        case .sensory:
            if indexPath.row == 1 {
                navigationController?.pushViewController(VolumeSettingsViewController(), animated: true)
            } else if indexPath.row == 2 {
                navigationController?.pushViewController(ThemesSettingsViewController(), animated: true)
            }
        case .security:
            if indexPath.row == 0 {
                navigationController?.pushViewController(LinkedCaregiversViewController(), animated: true)
            }
        case .support:
            if indexPath.row == 0 {
                navigationController?.pushViewController(SupportTicketViewController(), animated: true)
            }
        default: break
        }
    }
}
