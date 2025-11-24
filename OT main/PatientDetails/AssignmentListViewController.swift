import UIKit

class AssignmentListViewController: UIViewController {

    // MARK: - UI Components
    
    // Main scroll view
    /*
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    */

    // Content view inside the scroll view
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20 // Space between card and other elements
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 70, left: 16, bottom: 20, right: 16) // Increased top from 20 to 40
        return stackView
    }()
    
    // Main list card
    private let listCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Stack view for items inside the card
    private let itemsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0 // Separators will handle spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Bottom "Add New Assignment" button
    private let addNewButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Add New Assignment", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 25 // height / 2
        button.layer.masksToBounds = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    // MARK: - View Lifecycle

    override func loadView() {
        // Set GradientView as the main view
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupViews()
        setupLayout()
        addListItems()
    }

    // MARK: - Setup Functions

    private func setupNavigationBar() {
        // 1. Set the title
        title = "Assignments" // Changed from "Assignment"
        
        // 2. Make navigation bar transparent to show gradient
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        
        // 3. Configure Large Title
        navigationController?.navigationBar.prefersLargeTitles = false // Changed from true
        navigationItem.largeTitleDisplayMode = .never // Changed from .always
        
        // 4. Set title color (for both large and small)
        let titleColor: UIColor = .black // From your image
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: titleColor]
        // navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: titleColor] // No longer needed
        
        // 5. REMOVED All custom back button code.
        // The navigation controller will now add the native back button
        // automatically when this view controller is pushed.
        
        // We add this tint color so the native back button is blue.
        navigationController?.navigationBar.tintColor = .systemBlue
    }

    private func setupViews() {
        // view.addSubview(scrollView) // Removed
        view.addSubview(addNewButton)
        // scrollView.addSubview(mainStackView) // Removed
        view.addSubview(mainStackView) // Added
        
        // Add card to stack view
        mainStackView.addArrangedSubview(listCardView)
        listCardView.addSubview(itemsStackView)
    }

    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            // Button constraints
            addNewButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            addNewButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            addNewButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16),

            // ScrollView constraints (Removed)
            /*
            scrollView.topAnchor.constraint(equalTo: view.topAnchor), // Edge-to-edge for gradient
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: addNewButton.topAnchor, constant: -20), // Pin to button
            */

            // MainStackView constraints (holds the card)
            mainStackView.topAnchor.constraint(equalTo: safeArea.topAnchor), // Changed
            mainStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor), // Changed
            mainStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor), // Changed
            mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: addNewButton.topAnchor, constant: -20), // Changed
            // mainStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor), // Removed

            // ItemsStackView inside the listCardView
            itemsStackView.topAnchor.constraint(equalTo: listCardView.topAnchor, constant: 8),
            itemsStackView.bottomAnchor.constraint(equalTo: listCardView.bottomAnchor, constant: -8),
            itemsStackView.leadingAnchor.constraint(equalTo: listCardView.leadingAnchor, constant: 16),
            itemsStackView.trailingAnchor.constraint(equalTo: listCardView.trailingAnchor, constant: -16)
        ])
    }
    
    private func addListItems() {
        let items = [
            "Assignment 1", "Assignment 2", "Assignment 3",
            "Assignment 4", "Assignment 5", "Assignment 6",
            "Assignment 7", "Assignment 8"
        ]
        
        for (index, itemTitle) in items.enumerated() {
            let item = createListItemView(title: itemTitle)
            itemsStackView.addArrangedSubview(item)
            
            // Add separator if not the last item
            if index < items.count - 1 {
                itemsStackView.addArrangedSubview(createSeparatorView())
            }
        }
    }

    // MARK: - View Creation Helpers

    /// Creates a single list item (label + disclosure indicator)
    private func createListItemView(title: String) -> UIView {
        let itemView = UIButton(type: .system) // Use UIButton for easy tap handling
        itemView.translatesAutoresizingMaskIntoConstraints = false
        itemView.contentHorizontalAlignment = .leading
        itemView.addTarget(self, action: #selector(listItemTapped(_:)), for: .touchUpInside)
        
        // Label
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = .systemFont(ofSize: 17)
        label.textColor = .black
        
        // Disclosure indicator (>)
        let disclosureIndicator = UIImageView(image: UIImage(systemName: "chevron.right"))
        disclosureIndicator.translatesAutoresizingMaskIntoConstraints = false
        disclosureIndicator.tintColor = .systemGray
        
        itemView.addSubview(label)
        itemView.addSubview(disclosureIndicator)
        
        // Constraints
        NSLayoutConstraint.activate([
            itemView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            
            label.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: itemView.centerYAnchor),
            label.topAnchor.constraint(equalTo: itemView.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -12),
            
            disclosureIndicator.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
            disclosureIndicator.centerYAnchor.constraint(equalTo: itemView.centerYAnchor),
            disclosureIndicator.widthAnchor.constraint(equalToConstant: 10),
            disclosureIndicator.heightAnchor.constraint(equalToConstant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: disclosureIndicator.leadingAnchor, constant: -8)
        ])
        
        return itemView
    }
    
    /// Creates a thin separator line
    private func createSeparatorView() -> UIView {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .systemGray5
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }

    // MARK: - Actions

    
    /*
    @objc private func backButtonTapped() {
        print("Back button tapped")
        // This will pop the view controller if it was pushed,
        // or do nothing if it's the root (which is safe).
        navigationController?.popViewController(animated: true)
    }
    */
    

    @objc private func listItemTapped(_ sender: UIButton) {
        if let label = sender.subviews.compactMap({ $0 as? UILabel }).first {
            print("List item tapped: \(label.text ?? "Unknown")")
            navigationController?.pushViewController(AssignmentViewController(), animated: true)
        }
    }
}
