import UIKit
import PhotosUI
import Supabase

class ProfileViewController: UIViewController {
    weak var updateDelegate: ProfileUpdateDelegate?
    var patientData: Patient?
    
    // MARK: - UI Elements
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .clear // Allow GradientView to show through
        tv.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 15.0, *) {
            tv.sectionHeaderTopPadding = 0
        }
        return tv
    }()
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .light)
        iv.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
        iv.tintColor = .systemGray4
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .systemBackground
        iv.clipsToBounds = true
        iv.layer.borderColor = UIColor.systemBackground.cgColor
        iv.layer.borderWidth = 3.0
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let menuItems = [
        ("Patient detail", "person.text.rectangle"),
        ("Assessment", "clipboard"),
        ("Assignment", "doc.text"),
        ("Assessment Progress", "chart.line.uptrend.xyaxis"),
        ("Progress", "chart.bar"),
        ("Notes", "note.text")
    ]
    
    // MARK: - Lifecycle
    override func loadView() {
        self.view = GradientView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateHeaderData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Make image circular
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarAppearance()
        populateHeaderData() // Refresh in case data was updated in sub views
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            profileImageView.layer.borderColor = UIColor.systemBackground.resolvedColor(with: traitCollection).cgColor
        }
    }
    
    private func setupNavigationBarAppearance() {
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ]
        
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore tab bar if popping back to list
        if self.isMovingFromParent {
            self.tabBarController?.tabBar.isHidden = false
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Navigation Back Button action
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
        
        // Setup table view
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
        
        // Setup Header View
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 160))
        headerView.addSubview(profileImageView)
        
        NSLayoutConstraint.activate([
            profileImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            profileImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 110),
            profileImageView.heightAnchor.constraint(equalToConstant: 110),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.tableHeaderView = headerView
    }
    
    private func populateHeaderData() {
        guard let patient = patientData else { return }
        self.title = patient.fullName
        
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .light)
        let defaultPlaceholder = UIImage(systemName: "person.circle.fill", withConfiguration: config)
        
        if let urlString = patient.imageURL {
            profileImageView.loadImage(from: urlString, placeholder: defaultPlaceholder)
        } else if let localImage = patient.profileImage {
            profileImageView.image = localImage
        } else {
            profileImageView.image = defaultPlaceholder
        }
    }
    
    // MARK: - Actions
    @objc func backTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - UITableViewDelegate & DataSource
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        let item = menuItems[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = item.0
        
        let iconConfig = UIImage.SymbolConfiguration(weight: .medium)
        content.image = UIImage(systemName: item.1, withConfiguration: iconConfig)
        content.imageProperties.tintColor = .systemBlue
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = menuItems[indexPath.row].0
        
        switch item {
        case "Patient detail":
            let detailVC = PatientDetailFormViewController()
            detailVC.patientData = self.patientData
            detailVC.updateDelegate = self // Intercept updates so dashboard header reloads
            detailVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(detailVC, animated: true)
            
        case "Assessment":
            let assessmentVC = AssessmentListViewController()
            assessmentVC.patientID = self.patientData?.patientID
            assessmentVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(assessmentVC, animated: true)
            
        case "Assignment":
            let assignmentVC = AssignmentListViewController()
            assignmentVC.patientID = self.patientData?.patientID
            assignmentVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(assignmentVC, animated: true)
            
        case "Assessment Progress":
            let progressVC = AssessmentProgressViewController()
            progressVC.patient = self.patientData
            progressVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(progressVC, animated: true)
            
        case "Progress":
            let progressVC = PatientProgressViewController()
            progressVC.patient = self.patientData
            progressVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(progressVC, animated: true)
            
        case "Notes":
            let noteVC = NotesViewController()
            noteVC.patientID = self.patientData?.patientID
            noteVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(noteVC, animated: true)
            
        default:
            break
        }
    }
}

// MARK: - ProfileUpdateDelegate
extension ProfileViewController: ProfileUpdateDelegate {
    func didUpdatePatient(_ updatedPatient: Patient) {
        self.patientData = updatedPatient
        // When patient data is updated, push the updates up the chain (e.g. to PatientListViewController)
        self.updateDelegate?.didUpdatePatient(updatedPatient)
        
        // Refresh local UI
        DispatchQueue.main.async {
            self.populateHeaderData()
        }
    }
}
