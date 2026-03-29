//
//  NotificationSettingsViewController.swift
//  OT main
//
//  Created by Garvit Pareek on 17/01/2026.
//


//
//  NotificationSettingsViewController.swift
//  OT main
//
//  Created by Alishri Poddar on 16/01/26.
//



//

import UIKit

class NotificationSettingsViewController: UIViewController {

    private let backgroundView: GradientView = {
        let view = GradientView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.delegate = self
        tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "NotifyCell")
        return tv
    }()
    
    // Updated data source
    let options = ["Message Alerts", "Submission Reminders", "Global Notifications"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyOTNavigationStyling(title: "Notifications")
    }
    
    private func setupUI() {
        view.addSubview(backgroundView)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

extension NotificationSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotifyCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = options[indexPath.row]
        cell.contentConfiguration = content
        
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.selectionStyle = .none
        
        let switchView = UISwitch()
        switchView.isOn = true
        cell.accessoryView = switchView
        
        return cell
    }
}
