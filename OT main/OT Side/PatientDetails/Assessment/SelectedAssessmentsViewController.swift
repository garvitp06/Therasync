//
//  SelectedAssessmentsViewController.swift
//  OT main
//
//  Created by User on 27/11/25.
//

import UIKit

final class SelectedAssessmentsViewController: UIViewController {

    // MARK: - Data Source
    var assessmentsToPerform: [String] = [] {
        didSet {
            tableView.reloadData()
            // The layout update will happen automatically via the contentSize observer
        }
    }

    private var visited: Set<String> = []

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Selected Assessments"
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 18
        v.layer.masksToBounds = true
        return v
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .systemBackground
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.tableFooterView = UIView() // Removes extra separators below content
        tv.alwaysBounceVertical = false // Prevents bounce when fitting exactly
        return tv
    }()

    private let endButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("End Assessment", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.backgroundColor = .systemRed
        b.layer.cornerRadius = 28
        b.layer.masksToBounds = true
        b.alpha = 0.0
        b.isHidden = true
        return b
    }()

    // MARK: - Layout Variables
    private var cardHeightConstraint: NSLayoutConstraint?
    private var contentSizeObservation: NSKeyValueObservation?

    // MARK: - Lifecycle

    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupTable()
        
        endButton.addTarget(self, action: #selector(didTapEnd), for: .touchUpInside)
        
        // Add Observer to resize card dynamically based on actual table content
        contentSizeObservation = tableView.observe(\.contentSize, options: .new) { [weak self] _, _ in
            self?.updateCardLayout()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavBarAppearance()
        updateEndButtonState()
    }
    
    // MARK: - Setup UI

    private func setupViews() {
        view.addSubview(titleLabel)
        view.addSubview(cardView)
        cardView.addSubview(tableView)
        view.addSubview(endButton)
    }

    private func setupConstraints() {
        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            
            // Card
            cardView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20), // More spacing from title
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Table fills Card exactly
            tableView.topAnchor.constraint(equalTo: cardView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            
            // End Button
            endButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            endButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            endButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -20),
            endButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Initial height (will be updated immediately by observer)
        cardHeightConstraint = cardView.heightAnchor.constraint(equalToConstant: 100)
        cardHeightConstraint?.isActive = true
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 52 // Slightly taller rows for better touch targets
        
        // Add padding inside the table so content doesn't hit the rounded corners
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
    }
    
    private func configureNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        navigationItem.title = ""
        
        // Add Back Button Manually if needed, or rely on system
        if navigationController?.viewControllers.count ?? 0 > 1 {
            let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(didTapBack))
            backButton.tintColor = .white
            navigationItem.leftBarButtonItem = backButton
        }
    }
    
    // MARK: - Dynamic Layout Logic

    private func updateCardLayout() {
        // 1. Get the actual size of the table content
        // We add the contentInset (padding) to the contentSize to get the full visual height
        let totalContentHeight = tableView.contentSize.height + tableView.contentInset.top + tableView.contentInset.bottom
        
        // 2. Calculate the maximum available space on screen
        // Screen Height - (Top UI + Bottom UI + Safety Margins)
        let safeFrame = view.safeAreaLayoutGuide.layoutFrame
        let topUIHeight: CGFloat = 80 // Title + spacing
        let bottomUIHeight: CGFloat = 100 // End button + spacing
        let maxAvailableHeight = safeFrame.height - topUIHeight - bottomUIHeight
        
        // 3. Determine Final Height
        // If content is smaller than max, use content height (shrink wrap).
        // If content is larger, cap at max (scrollable).
        let finalHeight = min(totalContentHeight, maxAvailableHeight)
        
        // 4. Update Scroll State
        tableView.isScrollEnabled = totalContentHeight > maxAvailableHeight
        
        // 5. Update Constraint
        if cardHeightConstraint?.constant != finalHeight {
            cardHeightConstraint?.constant = finalHeight
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }

    // MARK: - End Button Logic

    private func updateEndButtonState() {
        let allVisited = !assessmentsToPerform.isEmpty && visited.count == assessmentsToPerform.count
        
        if allVisited && endButton.isHidden {
            endButton.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.endButton.alpha = 1.0
            }
        } else if !allVisited && !endButton.isHidden {
            UIView.animate(withDuration: 0.18, animations: {
                self.endButton.alpha = 0.0
            }, completion: { _ in
                self.endButton.isHidden = true
            })
        }
    }
    
    // MARK: - Actions

    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func didTapEnd() {
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - Table Delegate & DataSource

extension SelectedAssessmentsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assessmentsToPerform.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let name = assessmentsToPerform[indexPath.row]
        var cfg = cell.defaultContentConfiguration()
        cfg.text = name
        cfg.textProperties.font = .systemFont(ofSize: 16, weight: .medium)

        if visited.contains(name) {
            cfg.textProperties.color = .secondaryLabel
            cfg.image = UIImage(systemName: "checkmark.circle.fill")
            cfg.imageProperties.tintColor = .systemGreen
            cell.accessoryType = .none
        } else {
            cfg.textProperties.color = .label
            cfg.image = UIImage(systemName: "circle")
            cfg.imageProperties.tintColor = .systemBlue
            cell.accessoryType = .disclosureIndicator
        }

        cell.contentConfiguration = cfg
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let name = assessmentsToPerform[indexPath.row]
        
        // Mark as visited
        visited.insert(name)
        tableView.reloadRows(at: [indexPath], with: .automatic)
        updateEndButtonState()

        // Navigation logic
        switch name {
        case "ADOS":
            navigationController?.pushViewController(ADOSAssessmentViewController(), animated: true)
        case "Birth History":
            navigationController?.pushViewController(BirthHistoryViewController(), animated: true)
        case "Patient Difficulties":
            navigationController?.pushViewController(PatientDifficultiesViewController(), animated: true)
        case "School Complaints":
            navigationController?.pushViewController(SchoolComplaintsViewController(), animated: true)
        default:
            break
        }
    }
}
