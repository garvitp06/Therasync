import UIKit

class ProfileListViewController: UIViewController {

    // MARK: - UI Components

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
        imageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.white.cgColor
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Sameer Aalam"
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

    private let customTabBarView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Profile"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .white
        return label
    }()

    // MARK: - Lifecycle

    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        addListItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // IMPORTANT: hide the nav bar so safeArea.top equals what Patients VC sees
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // restore navigation bar hidden state if you want (optional)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // make image perfectly circular after layout
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.layer.masksToBounds = true
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(titleLabel)
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(listCardView)
        view.addSubview(customTabBarView)
        listCardView.addSubview(itemsStackView)

        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // Title: same as Patients VC
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),

            // Profile Image: anchored to TITLE (not safeArea)
            profileImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),

            // Name label below image
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Card
            listCardView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24),
            listCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            listCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            listCardView.bottomAnchor.constraint(lessThanOrEqualTo: customTabBarView.topAnchor, constant: -20),

            // Items stack
            itemsStackView.topAnchor.constraint(equalTo: listCardView.topAnchor, constant: 8),
            itemsStackView.bottomAnchor.constraint(equalTo: listCardView.bottomAnchor, constant: -8),
            itemsStackView.leadingAnchor.constraint(equalTo: listCardView.leadingAnchor, constant: 16),
            itemsStackView.trailingAnchor.constraint(equalTo: listCardView.trailingAnchor, constant: -16),

            // Tab bar (simple pin to bottom)
            customTabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customTabBarView.heightAnchor.constraint(equalToConstant: 90)
        ])
    }

    private func addListItems() {
        let items = [
            "Update Profile",
            "Settings",
            "Terms & Conditions",
            "About Us"
        ]

        for (index, itemTitle) in items.enumerated() {
            let item = createListItemView(title: itemTitle, showChevron: true, isDestructive: false)
            itemsStackView.addArrangedSubview(item)
            if index < items.count - 1 {
                itemsStackView.addArrangedSubview(createSeparatorView())
            }
        }

        itemsStackView.addArrangedSubview(createSeparatorView())
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

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(separator)

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: container.topAnchor),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        return container
    }

    @objc private func listItemTapped(_ sender: UIButton) {
            // 1. Get the text of the tapped item
            guard let label = sender.subviews.compactMap({ $0 as? UILabel }).first,
                  let actionTitle = label.text else { return }
            
            print("Tapped: \(actionTitle)")
            
            // 2. Check if it is "Log out"
            if actionTitle == "Log out" {
                handleLogout()
            } else {
                // Handle other actions (Update Profile, Settings, etc.) here
            }
        }

        private func handleLogout() {
            // 1. Instantiate the Login Screen
            // Assuming NewLoginViewController is built programmatically (based on your previous code)
            let loginVC = NewLoginViewController()
            
            // 2. Wrap it in a Navigation Controller
            // (Critical so the Login screen can push Register/Forgot Password screens)
            let nav = UINavigationController(rootViewController: loginVC)
            nav.setNavigationBarHidden(true, animated: false) // Optional: hide nav bar on login
            
            // 3. Get the Window
            guard let window = self.view.window else { return }
            
            // 4. Swap the Root View Controller
            // This destroys the Tab Bar and Profile screen, replacing them with Login
            window.rootViewController = nav
            
            // 5. Add a smooth transition animation
            UIView.transition(with: window,
                              duration: 0.5,
                              options: .transitionCrossDissolve,
                              animations: nil,
                              completion: nil)
        }
}
