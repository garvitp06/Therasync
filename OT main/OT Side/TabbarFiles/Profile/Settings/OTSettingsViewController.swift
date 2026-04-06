//
//  OTSettingsViewController.swift
//  OT main
//
//  Created by Garvit Pareek on 17/01/2026.


import UIKit

class OTSettingsViewController: UIViewController {

    // MARK: - Data Structure
    enum SettingsSection: Int, CaseIterable {
        case schedule
        case sensory
        case support

        var headerTitle: String? {
            switch self {
            case .schedule: return "Schedule Management"
            case .sensory: return "Sensory & Accessibility"
            case .support: return "Support"
            }
        }

        var rows: [String] {
            switch self {
            case .schedule:
                return ["Unavailability"]
            case .sensory:
                return ["Notification Settings", "Global Haptics"]
            case .support:
                return ["Report Technical Issue"]
            }
        }
    }

    // MARK: - UI Components
    private let backgroundView: GradientView = {
        let view = GradientView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tv.delegate = self
        tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        return tv
    }()
    

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        applyOTNavigationStyling(title: "Settings")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        applyOTNavigationStyling(title: "Settings")
        tableView.reloadData()
    }
    

    private func setupLayout() {
        view.addSubview(backgroundView)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Actions

    @objc func toggleGlobalHaptics(_ sender: UISwitch) { }
}

// MARK: - TableView Delegate & DataSource
extension OTSettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingsSection.allCases[section].rows.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = SettingsSection.allCases[section].headerTitle else { return nil }
        
        let headerView = UIView()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title.uppercased()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor(white: 0.3, alpha: 1.0)
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor)
        ])
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 { return 70 }
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        let sectionData = SettingsSection.allCases[indexPath.section]
        let rowTitle = sectionData.rows[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = rowTitle
        content.textProperties.color = .otDynamicLabel
        
        cell.accessoryType = .disclosureIndicator
        cell.accessoryView = nil
        cell.selectionStyle = .default

        if rowTitle == "Global Haptics" {
            cell.accessoryType = .none
            cell.selectionStyle = .none
            let sw = UISwitch()
            sw.isOn = true
            sw.addTarget(self, action: #selector(toggleGlobalHaptics(_:)), for: .valueChanged)
            cell.accessoryView = sw
            
        } else if sectionData == .support {
            content.textProperties.color = .systemBlue
        }

        cell.contentConfiguration = content
        cell.backgroundColor = .otDynamicCard
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowTitle = SettingsSection.allCases[indexPath.section].rows[indexPath.row]
        if rowTitle == "Global Haptics" { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch rowTitle {
        case "Unavailability":
            navigationController?.pushViewController(AvailabilityViewController(), animated: true)
        case "Notification Settings":
            navigationController?.pushViewController(NotificationSettingsViewController(), animated: true)
        case "Report Technical Issue":
            navigationController?.pushViewController(ReportIssueViewController(), animated: true)
        default: break
        }
    }
}

// MARK: - Navigation Styling
extension UIViewController {
    func applyOTNavigationStyling(title: String) {
        self.title = title
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        
        if navigationController?.viewControllers.count ?? 0 > 1 {
            let backButton = UIBarButtonItem(
                image: UIImage(systemName: "chevron.backward"),
                style: .plain,
                target: self,
                action: #selector(handleCustomBack)
            )
            navigationItem.leftBarButtonItem = backButton
        }
    }
    
    @objc private func handleCustomBack() {
        navigationController?.popViewController(animated: true)
    }
}
