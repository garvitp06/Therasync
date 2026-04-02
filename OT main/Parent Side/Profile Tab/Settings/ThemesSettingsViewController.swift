//
//  ThemesSettingsViewController.swift
//  OT main
//
//  Created by Garvit Pareek on 20/12/2025.
//
import UIKit
class ThemesSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let options = [
        ("High Contrast", "Increases visibility of buttons and text"),
        ("Reduced Motion", "Simplifies animations for sensitive eyes"),
        ("Dark Mode", "Reduces screen brightness and glare")
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        title = "Themes & Motion"
    }
    
    private func setupUI() {
        let bg = ParentGradientView()
        bg.frame = view.bounds
        view.addSubview(bg)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "themeCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Use the subtitle style to show the description
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "themeCell")
        let option = options[indexPath.row]
        
        cell.textLabel?.text = option.0
        cell.detailTextLabel?.text = option.1
        
        // --- DYNAMIC STYLING ---
        // These colors now automatically flip based on the window style
        cell.backgroundColor = .dynamicCard
        cell.textLabel?.textColor = .dynamicLabel
        cell.detailTextLabel?.textColor = .secondaryLabel // System secondary color adapts well
        
        let switchView = UISwitch()
        switchView.isOn = UserDefaults.standard.bool(forKey: option.0)
        switchView.tag = indexPath.row
        switchView.addTarget(self, action: #selector(themeChanged(_:)), for: .valueChanged)
        
        cell.accessoryView = switchView
        cell.selectionStyle = .none
        
        return cell
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        // Sync the window style to the saved state
        let isDarkMode = UserDefaults.standard.bool(forKey: "Dark Mode")
        view.window?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        // Refresh table to make sure toggles and colors match
        tableView.reloadData()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    @objc private func themeChanged(_ sender: UISwitch) {
        let optionName = options[sender.tag].0
        UserDefaults.standard.set(sender.isOn, forKey: optionName)
        
        if optionName == "Dark Mode" {
            let isDark = sender.isOn
            
            // 1. Update the entire app window style
            if let window = view.window {
                window.overrideUserInterfaceStyle = isDark ? .dark : .light
            }
            
            // 2. Notify other parts of the app (like the Profile screen)
            NotificationCenter.default.post(name: NSNotification.Name("AppThemeChanged"), object: nil)
            
            // 3. Refresh this table to update cell backgrounds/text colors
            tableView.reloadData()
        }
        
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
extension UIColor {
    // 1. All text that should be Black (Light) or White (Dark)
    static var dynamicLabel: UIColor {
        return UIColor { trait in
            return UserDefaults.standard.bool(forKey: "Dark Mode") ? .white : .black
        }
    }
    
    // 2. All white cards that should turn Grey (Dark)
    static var dynamicCard: UIColor {
            return UIColor { trait in
                // When Dark Mode is ON, use the official iOS 'Secondary System Grouped' grey
                // In Light Mode, we use pure White.
                return UserDefaults.standard.bool(forKey: "Dark Mode")
                    ? .secondarySystemGroupedBackground
                    : .white
            }
        }
    static var dynamicSeparator: UIColor {
            return UIColor { trait in
                return UserDefaults.standard.bool(forKey: "Dark Mode") ? .darkGray : .systemGray5
            }
        }
    static var dynamicPlaceholder: UIColor {
            return UIColor { trait in
                return UserDefaults.standard.bool(forKey: "Dark Mode") ? .lightGray : .systemGray
            }
        }
}
extension UITextField {
    func makeDynamicTextField(placeholderText: String) {
        // 1. Basic Style
        self.backgroundColor = .dynamicCard
        self.textColor = .dynamicLabel
        self.layer.cornerRadius = 20
        self.translatesAutoresizingMaskIntoConstraints = false
        
        // 2. Add Left Padding (so text doesn't touch the edge)
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        self.leftView = paddingView
        self.leftViewMode = .always
        
        // 3. Set the Placeholder
        self.placeholder = placeholderText
        
        // 4. Apply the color logic
        self.updatePlaceholderColor()
    }
    func updatePlaceholderColor() {
        guard let pText = self.placeholder else { return }
        
        self.attributedPlaceholder = NSAttributedString(
            string: pText,
            attributes: [.foregroundColor: UIColor.dynamicPlaceholder]
        )
    }
}
