//
//  ChatListViewController.swift
//  Screens1
//
//  Created by user@54 on 16/11/25.
//

import UIKit

// single shared model
struct ChatSummary {
    let id: UUID
    let name: String
    let message: String
    let time: String
    let avatar: UIImage?
}

// single class declaration - explicit protocol conformance here
class ChatListViewController: UIViewController,
                             UITableViewDataSource,
                             UITableViewDelegate,
                             UISearchBarDelegate {

    // MARK: - IBOutlets (connect in XIB)
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar?    // optional

    // MARK: - Programmatic Title + Top Button (to match Patients layout)
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "Chat"
        lbl.font = .systemFont(ofSize: 34, weight: .bold)
        lbl.textColor = .white
        return lbl
    }()

    private let topAddButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        btn.setImage(UIImage(systemName: "plus", withConfiguration: cfg), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor(white: 1.0, alpha: 0.18)
        btn.layer.cornerRadius = 22
        btn.layer.masksToBounds = true
        return btn
    }()

    // MARK: - Data
    private var chats: [ChatSummary] = []
    private var filteredChats: [ChatSummary] = []

    private var isSearching: Bool {
        guard let sb = searchBar, let t = sb.text else { return false }
        return !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the nav bar so safeArea.top equals Patients VC's safe area.
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup table and search bar delegates / styling
        setupTable()
        setupSearchBar()
        loadSampleData()

        // -------------------
        // 1) Remove any XIB constraints that reference searchBar or tableView
        // -------------------
        // This will search the whole view hierarchy for constraints where either
        // firstItem or secondItem is the searchBar or the tableView and deactivate them.
        // It avoids having to edit the XIB by hand.
        if let sb = searchBar {
            deactivateConstraintsReferencing(view: view, target: sb)
            // Also remove constraints owned by the searchBar itself
            sb.removeConstraints(sb.constraints)
            sb.translatesAutoresizingMaskIntoConstraints = false
        }
        if let tv = tableView {
            deactivateConstraintsReferencing(view: view, target: tv)
            tv.removeConstraints(tv.constraints)
            tv.translatesAutoresizingMaskIntoConstraints = false
        }

        // -------------------
        // 2) Add programmatic title + add-button
        // -------------------
        view.addSubview(titleLabel)
        view.addSubview(topAddButton)
        topAddButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)

        // Debug aid if you cannot see the title: uncomment to show red background
        // titleLabel.backgroundColor = .red

        // Bring to front so other subviews can't cover them
        view.bringSubviewToFront(titleLabel)
        view.bringSubviewToFront(topAddButton)

        // -------------------
        // 3) Add our constraints
        // -------------------
        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // Title at top-left like Patients VC
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),

            // topAddButton at top-right aligning with title
            topAddButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            topAddButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20),
            topAddButton.widthAnchor.constraint(equalToConstant: 44),
            topAddButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        // Now pin the searchBar under titleLabel (if exists) and re-enable Auto Layout for it.
        if let sb = searchBar {
            NSLayoutConstraint.activate([
                sb.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
                sb.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 10),
                sb.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -10),
                sb.heightAnchor.constraint(equalToConstant: 50)
            ])
        }

        // Pin the tableView under the searchBar (or under the titleLabel if searchBar missing)
        if let sb = searchBar {
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: sb.bottomAnchor, constant: 8),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: safe.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: safe.bottomAnchor)
            ])
        }

        // ensure the newly added constraints are used
        view.layoutIfNeeded()

        // Small drop shadow for title (optional to improve contrast)
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.12
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        titleLabel.layer.shadowRadius = 4
    }

    // MARK: - Helper: deactivate constraints referencing a target view
    private func deactivateConstraintsReferencing(view root: UIView, target: UIView) {
        // Deactivate constraints owned by root that reference target
        var toDeactivate: [NSLayoutConstraint] = []

        // 1) check constraints on the root and its subviews
        func collectConstraints(in view: UIView) {
            for c in view.constraints {
                if let first = c.firstItem as? UIView, first == target { toDeactivate.append(c); continue }
                if let second = c.secondItem as? UIView, second == target { toDeactivate.append(c); continue }
            }
            for sub in view.subviews { collectConstraints(in: sub) }
        }

        collectConstraints(in: root)

        // 2) Also check target's own constraints (already removed elsewhere but safe)
        for c in target.constraints {
            toDeactivate.append(c)
        }

        // De-duplicate and deactivate
        let unique = Array(Set(toDeactivate))
        NSLayoutConstraint.deactivate(unique)
    }

    // MARK: - Setup
    private func setupTable() {
        // register nib if you have it, otherwise fallback
        if Bundle.main.path(forResource: "ChatCell", ofType: "nib") != nil {
            tableView.register(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "ChatCell")
        } else {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "fallbackCell")
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .clear
    }

    private func setupSearchBar() {
        guard let sb = searchBar else { return }
        sb.delegate = self
        sb.placeholder = "Search"
        sb.returnKeyType = .done
        sb.enablesReturnKeyAutomatically = true
        sb.searchBarStyle = .minimal

        // style inner field (optional)
        sb.backgroundImage = UIImage()
        if let field = sb.value(forKey: "searchField") as? UITextField {
            field.backgroundColor = UIColor(white: 1.0, alpha: 0.95)
            field.layer.cornerRadius = 20
            field.clipsToBounds = true
            field.font = UIFont.systemFont(ofSize: 16)
            field.textColor = .label
        }
    }

    // MARK: - Data
    private func loadSampleData() {
        let baseNames = ["Ashutosh Anand", "Ravi Kumar", "Neha Sharma", "Priya Verma", "Sahil Jain", "Ananya Roy"]
        let msgOptions = ["Hey, I'll check and get back to you.","Sure — noted.","Thanks!","Ok sir...","On my way","Let's do it tomorrow"]

        var arr: [ChatSummary] = []
        for i in 0..<12 {
            let name = baseNames[i % baseNames.count]
            let msg = msgOptions[i % msgOptions.count]
            let time = String(format: "%02d:%02d", 20 + (i/6), i % 60)
            arr.append(.init(id: UUID(), name: name, message: msg, time: time, avatar: UIImage(named: "avatar_placeholder")))
        }
        chats = arr
        filteredChats = arr
        tableView.reloadData()
    }

    private func filterChats(with query: String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            filteredChats = chats
        } else {
            filteredChats = chats.filter {
                $0.name.lowercased().contains(q) || $0.message.lowercased().contains(q)
            }
        }
        tableView.reloadData()
    }

    private func chat(at indexPath: IndexPath) -> ChatSummary {
        return isSearching ? filteredChats[indexPath.row] : chats[indexPath.row]
    }

    // MARK: - Actions
    @objc private func didTapAdd() {
        // Wire this to whatever add flow you have
        print("Add tapped")
        // Example: show a new chat create screen or push a VC
    }
}

// MARK: - UITableViewDataSource & Delegate (in same file)
extension ChatListViewController {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredChats.count : chats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let item = chat(at: indexPath)

        if let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as? ChatCell {
            cell.configure(with: item)
            return cell
        }

        let fallback = tableView.dequeueReusableCell(withIdentifier: "fallbackCell", for: indexPath)
        fallback.textLabel?.text = item.name
        fallback.detailTextLabel?.text = item.message
        fallback.selectionStyle = .none
        return fallback
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = chat(at: indexPath)
        let detailVC = ChatDetailViewController()
        detailVC.titleName = item.name
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // optional swipe-to-delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Delete") { [weak self] action, view, completion in
            guard let self = self else { completion(false); return }
            if self.isSearching {
                let removed = self.filteredChats.remove(at: indexPath.row)
                self.chats.removeAll { $0.id == removed.id }
            } else {
                self.chats.remove(at: indexPath.row)
            }
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }
}

// MARK: - UISearchBarDelegate
extension ChatListViewController {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterChats(with: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        filterChats(with: "")
        searchBar.resignFirstResponder()
    }
}
