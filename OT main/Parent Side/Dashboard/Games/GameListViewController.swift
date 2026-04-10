//
//  GameListViewController.swift
//  OT main
//
//  Created by Garvit Pareek on 22/01/2026.
//


import UIKit

class GameListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let games = ["Memorizo","Mazilo","Patternation","Bubbly"]
    
    // MARK: - Initializers
    init() {
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.hidesBottomBarWhenPushed = true
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTheme), name: NSNotification.Name("AppThemeChanged"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func refreshTheme() {
        setupNavBar()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Always show the bar when this screen is about to appear
        navigationController?.setNavigationBarHidden(false, animated: animated)
        setupNavBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Check if we are being "popped" (going back to Dashboard)
        // or "pushed" (going forward to a game)
        if isMovingFromParent {
            // We are going BACK to Dashboard -> Hide the nav bar
            navigationController?.setNavigationBarHidden(true, animated: animated)
        } else {
            // We are going FORWARD to a game -> Keep the nav bar VISIBLE
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    private func setupNavBar() {
        self.title = "Games"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        let backBtn = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"),
                                    style: .plain,
                                    target: self,
                                    action: #selector(handleBack))
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn
    }

    @objc func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    private func setupUI() {
        let bg = ParentGradientView()
        bg.frame = view.bounds
        view.addSubview(bg)
        
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorColor = .dynamicSeparator
        
        // IMPORTANT: Let the Safe Area handle the top spacing
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            // FIXED: Using safeAreaLayoutGuide.topAnchor ensures the list sits BELOW the bar
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
        ])
    }

    // MARK: - TableView Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.count
    }
    // MARK: - Navigation Logic
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // Deselect the row so it doesn't stay highlighted
            tableView.deselectRow(at: indexPath, animated: true)
            
            var destinationVC: UIViewController?
            
            switch indexPath.row {
            case 0: // Memorizo
                destinationVC = MemoryGameViewController()
            case 1: // Game 2
                destinationVC = MazeGameViewController()
            case 2: // Game 3
                destinationVC = PatternGameViewController()
            case 3:
                destinationVC = BubblePopViewController()
            default:
                break
            }
            
            if let vc = destinationVC {
                vc.hidesBottomBarWhenPushed = true
                // Ensure the title is set for the next screen's back button
                vc.navigationItem.title = games[indexPath.row]
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = games[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .dynamicCard
        cell.textLabel?.textColor = .dynamicLabel
        return cell
    }
}
