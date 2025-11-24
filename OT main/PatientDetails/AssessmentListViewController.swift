//
//  AsessmentListViewController.swift
//  AssessmentApp
//
//  Created by Alishri Poddar on 17/11/25.
//

import UIKit

class AssessmentListViewController: UIViewController {

    // MARK: - UI Components

    // Main scroll view (kept for reference, but not used in setupViews/setupLayout)
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    // Content view inside the scroll view (kept for reference, but not used)
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Main stack view to hold all sections
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 24 // Space between sections
        return stackView
    }()

    // Bottom "Begin Assessment" button
    private let beginButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Begin Assessment", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 25 // Adjust for desired roundness (height / 2)
        button.layer.masksToBounds = true
        return button
    }()

    // MARK: - View Lifecycle

    override func loadView() {
        // Create an instance of GradientView and set it as the controller's view
        let gradientView = GradientView()
        // We can customize the colors here if needed, or leave as default
        // gradientView.topColor = .systemBlue
        // gradientView.bottomColor = .systemGray6
        self.view = gradientView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The background is now handled by GradientView
        
        setupNavigationBar()
        setupViews()
        setupLayout()
        addSections()
    }

    // MARK: - Setup Functions

    private func setupNavigationBar() {
        // 1. Set the title
        title = "Assessment List"
        
        // 2. Make navigation bar transparent to show gradient
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        
        // 3. --- FIX: Set the tint color for ALL standard buttons ---
        // This makes your back arrow and "+" icon white
        navigationController?.navigationBar.tintColor = .white
        
        // 4. --- FIX: Change title color to be visible ---
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        // 5. --- REMOVED ---ˀ
        // We REMOVE the custom back button.
        // The UINavigationController will add the default back arrow automatically.
        
        // 6. --- REPLACED ---
        // Create the "Add" button using the standard system item
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                          target: self,
                                                            action: #selector(addButtonTapped))
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // --- THIS IS THE FIX ---
        // We must explicitly show the navigation bar,
        // because the previous screen (Profile) hid it.
        navigationController?.setNavigationBarHidden(false, animated: animated)
        // --- END FIX ---
    }
    private func setupViews() {
        // Add subviews directly to the main view (which is GradientView)
        view.addSubview(beginButton)
        view.addSubview(mainStackView)
    }

    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // MainStackView constraints
            // Pin to safe area top to avoid status bar
            mainStackView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            // Add a constraint to ensure stack view doesn't overlap the button
            mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: beginButton.topAnchor, constant: -20),


            // BeginButton constraints
            beginButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            beginButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            // Pin to safe area bottom to avoid home indicator
            beginButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16),
            beginButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func addSections() {
        // Data for the sections
        let sections = [
            (title: "History", items: ["Birth History", "Medical History"], selected: Set([1])),
            (title: "Complaints", items: ["Patient Difficulties", "School Complaints"], selected: Set([0])),
            (title: "Skills", items: ["Gross Motor Skills", "Fine Motor Skills", "Cognitive Skills", "ADOS"], selected: Set([3]))
        ]
        
        // Create and add each section to the main stack view
        for section in sections {
            let sectionView = createSectionView(title: section.title,
                                                itemTitles: section.items,
                                                selectedIndices: section.selected)
            mainStackView.addArrangedSubview(sectionView)
        }
    }

    // MARK: - View Creation Helpers

    /// Creates a complete section with a title and a card containing list items
    private func createSectionView(title: String, itemTitles: [String], selectedIndices: Set<Int> = []) -> UIView {
        // Stack view for the section (title + card)
        let sectionStackView = UIStackView()
        sectionStackView.axis = .vertical
        sectionStackView.spacing = 8
        sectionStackView.translatesAutoresizingMaskIntoConstraints = false

        // Section title label
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .darkGray // This may need to be changed to .white or .black depending on gradient
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add left padding to the title label
        let titleContainer = UIView()
        titleContainer.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: 8), // Indent title slightly
            titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor)
        ])
        
        sectionStackView.addArrangedSubview(titleContainer)
        
        // Card view
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack view for items inside the card
        let itemsStackView = UIStackView()
        itemsStackView.axis = .vertical
        itemsStackView.spacing = 0 // Separators will handle spacing
        itemsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add items and separators
        for (index, itemTitle) in itemTitles.enumerated() {
            let item = createListItemView(title: itemTitle)
            
            // Set initial selected state
            if let checkbox = item.subviews.first(where: { $0 is UIButton }) as? UIButton {
                checkbox.isSelected = selectedIndices.contains(index)
            }
            
            itemsStackView.addArrangedSubview(item)
            
            // Add separator if not the last item
            if index < itemTitles.count - 1 {
                let separator = createSeparatorView()
                itemsStackView.addArrangedSubview(separator)
            }
        }
        
        cardView.addSubview(itemsStackView)
        sectionStackView.addArrangedSubview(cardView)
        
        // Constraints for itemsStackView inside cardView
        NSLayoutConstraint.activate([
            itemsStackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 8),
            itemsStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -8),
            itemsStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            itemsStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16)
        ])

        return sectionStackView
    }

    /// Creates a single list item (checkbox + label)
    private func createListItemView(title: String) -> UIView {
        let itemView = UIView()
        itemView.translatesAutoresizingMaskIntoConstraints = false
        
        // Checkbox button
        let checkbox = UIButton()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        let deselectedImage = UIImage(systemName: "circle")
        let selectedImage = UIImage(systemName: "checkmark.circle.fill")
        checkbox.setImage(deselectedImage, for: .normal)
        checkbox.setImage(selectedImage, for: .selected)
        checkbox.tintColor = .systemBlue
        checkbox.addTarget(self, action: #selector(checkboxTapped(_:)), for: .touchUpInside)
        
        // Label
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = .systemFont(ofSize: 17)
        label.textColor = .black
        
        itemView.addSubview(checkbox)
        itemView.addSubview(label)
        
        // Constraints for item
        NSLayoutConstraint.activate([
            itemView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44), // Good tap target size
            
            checkbox.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
            checkbox.centerYAnchor.constraint(equalTo: itemView.centerYAnchor),
            checkbox.widthAnchor.constraint(equalToConstant: 24),
            checkbox.heightAnchor.constraint(equalToConstant: 24),
            
            label.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: itemView.centerYAnchor),
            label.topAnchor.constraint(equalTo: itemView.topAnchor, constant: 12), // Ensure padding
            label.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -12) // Ensure padding
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

//    @objc private func backButtonTapped() {
//        // Handle back navigation
//        print("Back button tapped")
//        // if presented modally:
//        // dismiss(animated: true, completion: nil)
//        // if pushed on navigation stack:
//         navigationController?.popViewController(animated: true)
//    }

    @objc private func addButtonTapped() {
        // Handle add action
        print("Add button tapped")
    }
    
    @objc private func checkboxTapped(_ sender: UIButton) {
        // Toggle the selected state
        sender.isSelected.toggle()
    }
}
