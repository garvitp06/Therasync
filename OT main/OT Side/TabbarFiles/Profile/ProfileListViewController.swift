import UIKit
import PhotosUI
import Supabase

class ProfileListViewController: UIViewController, PHPickerViewControllerDelegate {

    // MARK: - UI Components

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
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    private let listCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let itemsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Profile"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .gray
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
        setupViews()
        addListItems()
        setupProfileTap()
        setupTapToDismiss()
        fetchOTProfile()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        fetchOTProfile() // Refresh on appear
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.layer.masksToBounds = true
    }

    // MARK: - Database Logic (Using OTProfileDetails)
    private func setupTapToDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false // Crucial: allows list items to remain clickable
        view.addGestureRecognizer(tap)
    }
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
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
                    
                    // Handle Profile Image Loading
                    if let urlString = profile.avatar_url, let url = URL(string: urlString) {
                        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                            if let data = data, let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    self?.profileImageView.image = image
                                }
                            }
                        }.resume()
                    }
                }
            } catch {
                await MainActor.run { self.activityIndicator.stopAnimating() }
            }
        }
    }
    // MARK: - Setup UI & Actions

    private func setupViews() {
        view.addSubview(titleLabel)
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(listCardView)
        view.addSubview(activityIndicator)
        
        listCardView.addSubview(itemsStackView)

        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),

            profileImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),

            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            activityIndicator.centerXAnchor.constraint(equalTo: nameLabel.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),

            listCardView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24),
            listCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            listCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            listCardView.bottomAnchor.constraint(lessThanOrEqualTo: safeArea.bottomAnchor, constant: -80),

            itemsStackView.topAnchor.constraint(equalTo: listCardView.topAnchor, constant: 8),
            itemsStackView.bottomAnchor.constraint(equalTo: listCardView.bottomAnchor, constant: -8),
            itemsStackView.leadingAnchor.constraint(equalTo: listCardView.leadingAnchor, constant: 16),
            itemsStackView.trailingAnchor.constraint(equalTo: listCardView.trailingAnchor, constant: -16),
        ])
    }
    
    // Photo Logic
    private func setupProfileTap() {
        view.endEditing(true)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapProfilePic))
        profileImageView.addGestureRecognizer(tap)
    }
    
    @objc private func didTapProfilePic() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            DispatchQueue.main.async {
                if let selectedImage = image as? UIImage {
                    self?.profileImageView.image = selectedImage
                }
            }
        }
    }

    // List Logic
    private func addListItems() {
        let items = ["Update Profile", "Settings", "Terms & Conditions", "About Us"]
        
        // 1. Add the main items
        for (index, itemTitle) in items.enumerated() {
            let item = createListItemView(title: itemTitle, showChevron: true, isDestructive: false)
            itemsStackView.addArrangedSubview(item)
            
            // Only add a separator if it's NOT the last item in this array
            if index < items.count - 1 {
                itemsStackView.addArrangedSubview(createSeparatorView())
            }
        }
        
        // 2. Add one separator BEFORE the Logout item to separate it from the main list
        itemsStackView.addArrangedSubview(createSeparatorView())
        
        // 3. Add Logout (Notice NO separator is added after this)
        let logoutItem = createListItemView(title: "Log out", showChevron: false, isDestructive: true)
        itemsStackView.addArrangedSubview(logoutItem)
    }

    private func createListItemView(title: String, showChevron: Bool, isDestructive: Bool) -> UIView {
        let itemView = UIButton(type: .system)
        itemView.translatesAutoresizingMaskIntoConstraints = false
        itemView.contentHorizontalAlignment = .leading
        itemView.addTarget(self, action: #selector(listItemTapped(_:)), for: .touchUpInside)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = .systemFont(ofSize: 17)
        label.textColor = isDestructive ? .systemRed : .black
        itemView.addSubview(label)

        NSLayoutConstraint.activate([
            itemView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            label.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: itemView.centerYAnchor),
            label.topAnchor.constraint(equalTo: itemView.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -12)
        ])

        if showChevron {
            let disclosureIndicator = UIImageView(image: UIImage(systemName: "chevron.right"))
            disclosureIndicator.translatesAutoresizingMaskIntoConstraints = false
            disclosureIndicator.tintColor = .systemGray
            itemView.addSubview(disclosureIndicator)
            NSLayoutConstraint.activate([
                disclosureIndicator.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
                disclosureIndicator.centerYAnchor.constraint(equalTo: itemView.centerYAnchor),
                disclosureIndicator.widthAnchor.constraint(equalToConstant: 10),
                disclosureIndicator.heightAnchor.constraint(equalToConstant: 16),
                label.trailingAnchor.constraint(lessThanOrEqualTo: disclosureIndicator.leadingAnchor, constant: -8)
            ])
        } else {
            label.trailingAnchor.constraint(equalTo: itemView.trailingAnchor).isActive = true
        }
        return itemView
    }

    private func createSeparatorView() -> UIView {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .systemGray5
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }

    @objc private func listItemTapped(_ sender: UIButton) {
        guard let label = sender.subviews.compactMap({ $0 as? UILabel }).first, let actionTitle = label.text else { return }
        
        if actionTitle == "Log out" { handleLogout() }
        else if actionTitle == "Update Profile" { updateProfile() }
        else if actionTitle == "Terms & Conditions" { handleTC() }
        else if actionTitle == "About Us" { handleaboutus() }
        else if actionTitle == "Settings" { opensettings() }
    }
    
    private func opensettings(){
        let updateVC = OTSettingsViewController()
        updateVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(updateVC, animated: true)
    }
    
    private func updateProfile() {
        let updateVC = UpdateProfileViewController()
        updateVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(updateVC, animated: true)
    }
    
    private func handleTC() {
        let updateVC = ConditionViewController()
        updateVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(updateVC, animated: true)
    }
    
    private func handleaboutus() {
        let updateVC = AboutUsViewController()
        updateVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(updateVC, animated: true)
    }
    
    private func handleLogout() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure?", preferredStyle: .alert)
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
