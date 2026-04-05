import UIKit
import PhotosUI
import Supabase

class ProfileListViewController: UIViewController {
    private var hasCustomProfilePhoto: Bool = false
    
    // MARK: - Data Models
    private let regularItems = ["Update Profile", "Settings", "Terms & Conditions", "About Us"]
    private let actionItems = ["Log out"]
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear // Ensures GradientView shines through
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
        imageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
        imageView.tintColor = .systemGray4
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Loading..."
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    // MARK: - Lifecycle
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Profile"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        setupTableView()
        setupHeaderView()
        setupProfileTap()
        fetchOTProfile()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Restore transparent and white text appearance (if other views made it opaque/black)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        fetchOTProfile() // Refresh on appear
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
    }
    
    // MARK: - Navigation Bar Setup
    // (Removed setupNavBar as it is split safely to avoid inset jumps)

    // MARK: - Setup UI
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
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 180))
        
        headerView.addSubview(profileImageView)
        headerView.addSubview(nameLabel)
        headerView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            profileImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),

            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            activityIndicator.centerXAnchor.constraint(equalTo: nameLabel.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor)
        ])
        
        tableView.tableHeaderView = headerView
    }

    // MARK: - Database Logic
    private func fetchOTProfile() {
        guard let currentUser = supabase.auth.currentUser else { return }
        activityIndicator.startAnimating()
        
        Task {
            do {
                let profile: OTProfileDetails = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: currentUser.id)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.nameLabel.text = profile.fullName
                    
                    if let urlString = profile.avatar_url {
                        self.hasCustomProfilePhoto = true
                        self.profileImageView.loadImage(from: urlString, placeholder: self.profileImageView.image)
                    } else {
                        self.hasCustomProfilePhoto = false
                        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
                        self.profileImageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
                    }
                }
            } catch {
                await MainActor.run { self.activityIndicator.stopAnimating() }
            }
        }
    }
    
    // MARK: - Actions
    private func setupProfileTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapProfilePic))
        profileImageView.addGestureRecognizer(tap)
    }
    
    @objc private func didTapProfilePic() {
        if hasCustomProfilePhoto, let image = profileImageView.image {
            let viewer = FullScreenImageViewController(image: image)
            viewer.modalPresentationStyle = .overFullScreen
            viewer.modalTransitionStyle = .crossDissolve
            present(viewer, animated: true)
        } else {
            let alert = UIAlertController(title: nil, message: "No profile photo there.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func handleLogout() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out of your account?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
            Task {
                try? await supabase.auth.signOut()
                await MainActor.run {
                    let loginVC = NewLoginViewController()
                    let nav = UINavigationController(rootViewController: loginVC)
                    nav.setNavigationBarHidden(true, animated: false)
                    self.view.window?.rootViewController = nav
                }
            }
        }))
        self.present(alert, animated: true)
    }
}

// MARK: - UITableView DataSource & Delegate
extension ProfileListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Main Settings & Logout
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? regularItems.count : actionItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        if indexPath.section == 0 {
            cell.textLabel?.text = regularItems[indexPath.row]
            cell.textLabel?.textColor = .label
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.textLabel?.text = actionItems[indexPath.row]
            cell.textLabel?.textColor = .systemRed
            cell.accessoryType = .none
            cell.textLabel?.textAlignment = .center
        }
        
        cell.backgroundColor = .systemBackground
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            let item = regularItems[indexPath.row]
            switch item {
            case "Update Profile":
                let vc = UpdateProfileViewController()
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            case "Settings":
                let vc = OTSettingsViewController()
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            case "Terms & Conditions":
                let vc = ConditionViewController()
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            case "About Us":
                let vc = AboutUsViewController()
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            default: break
            }
        } else {
            handleLogout()
        }
    }
}

// MARK: - FullScreenImageViewController
class FullScreenImageViewController: UIViewController {
    let imageView = UIImageView()
    
    init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = image
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissViewer))
        view.addGestureRecognizer(tap)
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(dismissViewer))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
    }
    
    @objc func dismissViewer() {
        dismiss(animated: true)
    }
}
