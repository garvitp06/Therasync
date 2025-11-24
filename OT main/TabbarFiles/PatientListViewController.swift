import UIKit

// --- PROTOCOLS & MODELS ---

// protocol AddPatientDelegate: AnyObject {
//     func didAddPatient(_ patient: Patient)
// }

struct Patient {
    let firstName: String
    let lastName: String
    let gender: String
    let dateOfBirth: Date
    let bloodGroup: String
    let address: String
    let parentName: String
    let parentContact: String
    let referredBy: String
    let diagnosis: String
    let medication: String
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }
    
    var formattedDOB: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateOfBirth)
    }
}

// --- MAIN VIEW CONTROLLER ---

class PatientListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddPatientDelegate {

    // MARK: - Data
    var patients: [Patient] = []
    
    // MARK: - UI Components (Common)
    
    // 1. Gradient Layer (Background)
    private lazy var gradientLayer: CAGradientLayer = {
        let topColor = UIColor(red: 0.18, green: 0.50, blue: 0.98, alpha: 1.0).cgColor // Vibrant Blue
        let bottomColor = UIColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0).cgColor // Lighter Blue
        
        let layer = CAGradientLayer()
        layer.colors = [topColor, bottomColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0.0)
        layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        return layer
    }()
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Patients"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .white
        return label
    }()

    // MARK: - UI Components (Populated State)
    
    // Top Right Small Button
    private let topAddButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        // Glassmorphism / Semi-transparent background
        button.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        button.layer.cornerRadius = 22
        button.layer.masksToBounds = true
        return button
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search"
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundImage = UIImage()
        
        if let searchTextField = searchBar.value(forKey: "searchField") as? UITextField {
            searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.25)
            searchTextField.textColor = .white
            searchTextField.layer.cornerRadius = 10
            searchTextField.clipsToBounds = true
            
            let placeholderAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white.withAlphaComponent(0.8)]
            searchTextField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: placeholderAttributes)
            
            if let leftView = searchTextField.leftView as? UIImageView {
                leftView.tintColor = .white
            }
        }
        return searchBar
    }()

    // The White Card Container
    private let mainContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        // Rounded top corners
        view.layer.cornerRadius = 30
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        return view
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .systemGray5
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 16)
        return tableView
    }()
    
    // MARK: - UI Components (Empty State)
    
    // Big Center Button
    private let centerAddButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue // Or custom bright blue
        button.layer.cornerRadius = 16 // Slightly squared rounded corners
        return button
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Add patient to see details"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Setup Background
        view.backgroundColor = .systemBlue
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        
        // 2. Add Targets
        topAddButton.addTarget(self, action: #selector(didTapAddButton), for: .touchUpInside)
        centerAddButton.addTarget(self, action: #selector(didTapAddButton), for: .touchUpInside)
        
        // 3. Setup Table
        tableView.register(patientcellList.self, forCellReuseIdentifier: patientcellList.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        // 4. Layout & State
        setupUI()
        updateUIState()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = backgroundView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    // MARK: - Logic: State Management

    private func updateUIState() {
        let isEmpty = patients.isEmpty
        
        // Elements visible when EMPTY
        centerAddButton.isHidden = !isEmpty
        emptyStateLabel.isHidden = !isEmpty
        
        // Elements visible when POPULATED
        topAddButton.isHidden = isEmpty
        searchBar.isHidden = isEmpty
        mainContentView.isHidden = isEmpty // Hides the white card + tableview
    }

    // MARK: - Actions & Delegate

    @objc private func didTapAddButton() {
        let addPatientVC = addPatient(nibName: "addPatient", bundle: nil)
        addPatientVC.delegate = self
        let navigationController = UINavigationController(rootViewController: addPatientVC)
        
        // Sheet configuration
        if #available(iOS 15.0, *) {
            if let sheet = navigationController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        }
        
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func didAddPatient(_ patient: Patient) {
        patients.append(patient)
        updateUIState() // This switches the view from Empty -> List
        tableView.reloadData()
    }

    // MARK: - Setup UI Constraints

    private func setupUI() {
        // Add everything to view
        view.addSubview(backgroundView)
        view.addSubview(titleLabel)
        
        // Populated State Views
        view.addSubview(topAddButton)
        view.addSubview(searchBar)
        view.addSubview(mainContentView)
        mainContentView.addSubview(tableView)
        
        // Empty State Views
        view.addSubview(centerAddButton)
        view.addSubview(emptyStateLabel)

        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            // 1. Background (Fills entire screen)
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 2. Title (Common)
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            
            // --- POPULATED STATE CONSTRAINTS ---
            
            // 3. Top Right Button
            topAddButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            topAddButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            topAddButton.widthAnchor.constraint(equalToConstant: 44),
            topAddButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 4. Search Bar
            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            searchBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 10),
            searchBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -10),
            searchBar.heightAnchor.constraint(equalToConstant: 50),
            
            // 5. White Card Container
            // Pins top to search bar bottom + padding
            mainContentView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20),
            mainContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 6. TableView (Inside Card)
            tableView.topAnchor.constraint(equalTo: mainContentView.topAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: mainContentView.bottomAnchor),
            
            // --- EMPTY STATE CONSTRAINTS ---
            
            // 7. Center Button
            centerAddButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerAddButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            centerAddButton.widthAnchor.constraint(equalToConstant: 60),
            centerAddButton.heightAnchor.constraint(equalToConstant: 60),
            
            // 8. Empty Label
            emptyStateLabel.topAnchor.constraint(equalTo: centerAddButton.bottomAnchor, constant: 16),
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return patients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: patientcellList.identifier, for: indexPath) as? patientcellList else {
            return UITableViewCell()
        }
        let patient = patients[indexPath.row]
        cell.configure(with: patient)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedPatient = patients[indexPath.row]
        let patientprofileVC = ProfileViewController(nibName: "ProfileViewController", bundle: nil)
        patientprofileVC.hidesBottomBarWhenPushed = true
         patientprofileVC.patientData = selectedPatient
        self.navigationController?.pushViewController(patientprofileVC, animated: true)
    }
}
