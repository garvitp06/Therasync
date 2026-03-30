import UIKit

class AssessmentListViewController: UIViewController {

    var patientID: String?

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let v = UIScrollView(); v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let contentView: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let mainStackView: UIStackView = {
        let v = UIStackView(); v.translatesAutoresizingMaskIntoConstraints = false; v.axis = .vertical; v.spacing = 24; return v
    }()
    private let beginButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Begin Assessment", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.backgroundColor = .systemBlue
        b.layer.cornerRadius = 25
        b.layer.masksToBounds = true
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = GradientView() // Assuming GradientView exists
        setupNavigationBar()
        setupViews()
        setupLayout()
        addSections()
        beginButton.addTarget(self, action: #selector(didTapBeginButton), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh UI state if needed (e.g. if coming back from an assessment)
    }

    @objc private func checkboxTapped(_ sender: UIButton) {
        guard let pid = patientID else { return }
        
        sender.isSelected.toggle()
        
        if let parentView = sender.superview,
           let label = parentView.subviews.compactMap({ $0 as? UILabel }).first,
           let text = label.text {
            
            // FIX: Retrieve current selection using the getter
            var currentSelection = AssessmentSessionManager.shared.getSelectedAssessments(for: pid)
            
            if sender.isSelected {
                currentSelection.insert(text)
            } else {
                currentSelection.remove(text)
            }
            
            // FIX: Save updated selection using the setter
            AssessmentSessionManager.shared.updateSelection(for: pid, selection: currentSelection)
        }
    }
    
    @objc private func didTapBeginButton() {
        guard let pid = patientID else { return }
        
        // FIX: Check selection using getter
        let currentSelection = AssessmentSessionManager.shared.getSelectedAssessments(for: pid)
        
        if currentSelection.isEmpty {
            let alert = UIAlertController(title: "No Selection", message: "Please select at least one assessment.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let nextVC = AssessmentList()
        nextVC.assessmentsToDisplay = Array(currentSelection).sorted()
        nextVC.patientID = self.patientID
        navigationController?.pushViewController(nextVC, animated: true)
    }

    // MARK: - UI Construction
    private func setupNavigationBar() {
        title = "Assessment List"
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupViews() {
        view.addSubview(beginButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mainStackView)
    }

    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: beginButton.topAnchor, constant: -10),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            beginButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            beginButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            beginButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -10),
            beginButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func addSections() {
        let sections = [
            (title: "History", items: ["Birth History", "Medical History"]),
            (title: "Complaints", items: ["Patient Difficulties", "School Complaints"]),
            (title: "Skills", items: ["Gross Motor Skills", "Fine Motor Skills", "Cognitive Skills", "ADOS"])
        ]
        for section in sections {
            mainStackView.addArrangedSubview(createSectionView(title: section.title, itemTitles: section.items))
        }
    }

    private func createSectionView(title: String, itemTitles: [String]) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .darkGray
        stack.addArrangedSubview(label)
        
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        
        let itemsStack = UIStackView()
        itemsStack.axis = .vertical
        itemsStack.translatesAutoresizingMaskIntoConstraints = false
        
        for (index, itemTitle) in itemTitles.enumerated() {
            itemsStack.addArrangedSubview(createListItemView(title: itemTitle))
            if index < itemTitles.count - 1 { itemsStack.addArrangedSubview(createSeparatorView()) }
        }
        
        card.addSubview(itemsStack)
        stack.addArrangedSubview(card)
        
        NSLayoutConstraint.activate([
            itemsStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            itemsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            itemsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            itemsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
        return stack
    }

    private func createListItemView(title: String) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        
        let checkbox = UIButton()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.setImage(UIImage(systemName: "circle"), for: .normal)
        checkbox.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        checkbox.tintColor = .systemBlue
        checkbox.addTarget(self, action: #selector(checkboxTapped(_:)), for: .touchUpInside)
        
        // FIX: Check session manager using patient ID
        if let pid = patientID {
            let currentSelection = AssessmentSessionManager.shared.getSelectedAssessments(for: pid)
            checkbox.isSelected = currentSelection.contains(title)
        }
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = .systemFont(ofSize: 17)
        label.textColor = .black
        
        v.addSubview(checkbox)
        v.addSubview(label)
        
        NSLayoutConstraint.activate([
            v.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            checkbox.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            checkbox.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            checkbox.widthAnchor.constraint(equalToConstant: 24), checkbox.heightAnchor.constraint(equalToConstant: 24),
            label.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            label.topAnchor.constraint(equalTo: v.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -12)
        ])
        return v
    }
    
    private func createSeparatorView() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false; v.backgroundColor = .systemGray5
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }
}
