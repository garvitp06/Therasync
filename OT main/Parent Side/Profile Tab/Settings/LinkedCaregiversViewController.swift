//
//  LinkedCaregiversViewController.swift
//  OT main
//
//  Created by Garvit Pareek on 20/12/2025.
//
import UIKit
class LinkedCaregiversViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var caregivers = ["Alishri Poddar (Primary)", "Nanny Maria"]
    
    private let inviteButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Invite New Caregiver", for: .normal)
        btn.backgroundColor = UIColor(red: 0.24, green: 0.51, blue: 1.0, alpha: 1.0)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.layer.cornerRadius = 25
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        title = "Caregivers"
        
        // Listen for the theme change notification to refresh the table cells
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTheme), name: NSNotification.Name("AppThemeChanged"), object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func refreshTheme() {
        tableView.reloadData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        let bg = ParentGradientView()
        bg.frame = view.bounds
        view.addSubview(bg)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        // Using a standard cell but setting its dynamic properties in cellForRowAt
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "caregiverCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        view.addSubview(inviteButton)
        
        inviteButton.addTarget(self, action: #selector(showInviteOptions), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inviteButton.topAnchor, constant: -20),
            
            inviteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            inviteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            inviteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            inviteButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return caregivers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "caregiverCell", for: indexPath)
        
        // --- DYNAMIC THEME UPDATES ---
        cell.backgroundColor = .dynamicCard   // White -> Grey
        cell.textLabel?.textColor = .dynamicLabel // Black -> White
        cell.textLabel?.text = caregivers[indexPath.row]
        
        // Handle Icon tint
        cell.imageView?.image = UIImage(systemName: "person.circle.fill")
        let isDark = UserDefaults.standard.bool(forKey: "Dark Mode")
        cell.imageView?.tintColor = isDark ? .lightGray : .systemGray
        
        cell.accessoryType = caregivers[indexPath.row].contains("(Primary)") ? .none : .disclosureIndicator
        
        return cell
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if caregivers[indexPath.row].contains("(Primary)") { return }
        showEditAlert(at: indexPath)
    }
    // MARK: - Invitation & Edit Alerts
    // The alert controllers naturally adapt to Dark Mode if you use standard UIAlertControllers
    private func showEditAlert(at indexPath: IndexPath) {
        let currentName = caregivers[indexPath.row]
        let alert = UIAlertController(title: "Edit Caregiver", message: "Update name or role", preferredStyle: .alert)
        alert.addTextField { $0.text = currentName }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                self?.caregivers[indexPath.row] = newName
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                self?.showToast(message: "Updated successfully")
            }
        }))
        present(alert, animated: true)
    }
    @objc private func showInviteOptions() {
        let alert = UIAlertController(title: "Invite Caregiver", message: "Choose a method to invite a new caregiver.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Send Email Invite", style: .default, handler: { _ in self.presentEmailInput() }))
        alert.addAction(UIAlertAction(title: "Share Join Code", style: .default, handler: { _ in self.showJoinCode() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    private func presentEmailInput() {
        let alert = UIAlertController(title: "Invite via Email", message: "Enter the email address.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "email@example.com" }
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak self] _ in self?.showToast(message: "Invite sent successfully") }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    private func showJoinCode() {
        let code = "OT-789-XYZ"
        let alert = UIAlertController(title: "Join Code", message: "Share this code: \(code)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Copy Code", style: .default, handler: { _ in
            UIPasteboard.general.string = code
            self.showToast(message: "Code copied")
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if caregivers[indexPath.row].contains("(Primary)") { return nil }
        let deleteAction = UIContextualAction(style: .destructive, title: "Remove") { [weak self] (_, _, completion) in
            self?.confirmRemoval(at: indexPath, completionHandler: completion)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func confirmRemoval(at indexPath: IndexPath, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Remove?", message: "Confirm removal", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in completionHandler(false) }))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { [weak self] _ in
            self?.caregivers.remove(at: indexPath.row)
            self?.tableView.deleteRows(at: [indexPath], with: .fade)
            self?.showToast(message: "Removed")
            completionHandler(true)
        }))
        present(alert, animated: true)
    }
    // MARK: - Toast
    private func showToast(message: String) {
        let toastLabel = UILabel()
        // Toast stays dark with white text for high contrast visibility
        toastLabel.backgroundColor = UIColor.label.withAlphaComponent(0.8)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14, weight: .medium)
        toastLabel.text = message
        toastLabel.layer.cornerRadius = 20
        toastLabel.clipsToBounds = true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toastLabel)
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            toastLabel.widthAnchor.constraint(equalToConstant: 250),
            toastLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { _ in toastLabel.removeFromSuperview() })
    }
}
