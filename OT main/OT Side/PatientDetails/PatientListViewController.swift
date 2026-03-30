import UIKit
import Supabase

struct Patient: Codable {
    var id: UUID?
    var firstName: String
    var lastName: String
    var gender: String?
    var dateOfBirth: Date?
    var bloodGroup: String?
    var address: String?
    var parentName: String?
    var parentContact: String?
    var referredBy: String?
    var diagnosis: String?
    var medication: String?
    var profileImage: UIImage?
    var imageURL: String?
    var parentID: UUID?
    var parentUID: UUID?
    var patientID: String
    var otID: UUID?

    // MARK: - Convenience
    var fullName: String { "\(firstName) \(lastName)" }

    // MARK: - Safety Fix for Age
    var age: Int {
        // Safe unwrap: If dateOfBirth is nil, return 0 instead of crashing
        guard let dob = dateOfBirth else { return 0 }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case id, gender, address, diagnosis, medication
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "dob"
        case bloodGroup = "blood_group"
        case parentName = "parent_name"
        case parentContact = "parent_contact"
        case referredBy = "referred_by"
        case parentID = "parent_id"
        case parentUID = "parent_uid"
        case patientID = "patient_id_number"
        case imageURL = "image_url"
        case otID = "ot_id"
    }
}

protocol ProfileUpdateDelegate: AnyObject {
    func didUpdatePatient(_ updatedPatient: Patient)
}

// MARK: - PatientListViewController
class PatientListViewController: UIViewController {
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .systemGroupedBackground
        tv.rowHeight = 84
        return tv
    }()

    private let searchController = UISearchController(searchResultsController: nil)
    private let refreshControl = UIRefreshControl()

    private let emptyCenterPlusButton: UIButton = {
        let b = UIButton(type: .system)
        let conf = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        b.setImage(UIImage(systemName: "plus", withConfiguration: conf), for: .normal)
        b.tintColor = .white
        b.backgroundColor = .systemBlue
        b.layer.cornerRadius = 36
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        return b
    }()

    private let emptyCenterLabel: UILabel = {
        let l = UILabel()
        l.text = "Add patients to see details"
        l.textColor = .secondaryLabel
        l.font = UIFont.systemFont(ofSize: 16)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Properties
    private var isInitialLoading = true
    private var patients: [Patient] = [] {
        didSet { updateUIForDataState() }
    }
    
    private var allPatients: [Patient] = [] {
        didSet { self.patients = allPatients }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        
        
        setupNavigationBar()
        setupSearchController()
        setupTableView()
        setupEmptyState()
        setupLoadingIndicator()
        
        fetchPatients()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure standard large native title bar is visible
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        fetchPatients()
    }

    // MARK: - Layout Setup
    private func setupNavigationBar() {
        self.title = "Patients"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleNavPlus))
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Patients"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.register(PatientCell.self, forCellReuseIdentifier: "PatientCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    private func setupEmptyState() {
        view.addSubview(emptyCenterPlusButton)
        view.addSubview(emptyCenterLabel)
        NSLayoutConstraint.activate([
            emptyCenterPlusButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyCenterPlusButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            emptyCenterPlusButton.widthAnchor.constraint(equalToConstant: 72),
            emptyCenterPlusButton.heightAnchor.constraint(equalToConstant: 72),
            
            emptyCenterLabel.topAnchor.constraint(equalTo: emptyCenterPlusButton.bottomAnchor, constant: 12),
            emptyCenterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        emptyCenterPlusButton.addTarget(self, action: #selector(handleNavPlus), for: .touchUpInside)
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Database Fetch
    @objc func handleRefresh() { fetchPatients() }

    func fetchPatients() {
        if isInitialLoading { loadingIndicator.startAnimating() }
        Task {
            do {
                let user = try await supabase.auth.session.user
                let currentUserId = user.id.uuidString
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                decoder.dateDecodingStrategy = .formatted(formatter)
                
                let response = try await supabase
                    .from("patients")
                    .select()
                    .eq("ot_id", value: currentUserId)
                    .order("created_at", ascending: false)
                    .execute()
                
                let fetched = try decoder.decode([Patient].self, from: response.data)
                
                await MainActor.run {
                    self.isInitialLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.refreshControl.endRefreshing()
                    self.allPatients = fetched
                }
            } catch {
                await MainActor.run {
                    self.isInitialLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.refreshControl.endRefreshing()
                    self.allPatients = []
                }
            }
        }
    }

    // MARK: - Logic
    private func updateUIForDataState() {
        let databaseHasData = !allPatients.isEmpty
        let showEmptyState = !databaseHasData && !isInitialLoading
        
        if showEmptyState {
            navigationItem.rightBarButtonItem = nil
            navigationItem.searchController = nil
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleNavPlus))
            navigationItem.searchController = searchController
        }
        
        tableView.isHidden = !databaseHasData
        emptyCenterPlusButton.isHidden = !showEmptyState
        emptyCenterLabel.isHidden = !showEmptyState
        
        tableView.reloadData()
    }

    @objc private func handleNavPlus() {
        let addVC = addPatient()
        addVC.delegate = self
        // addPatient is now designed native, let's wrap it uniformly
        let nav = UINavigationController(rootViewController: addVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
}

// MARK: - TableView Extensions
extension PatientListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return patients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PatientCell", for: indexPath) as! PatientCell
        cell.configure(with: patients[indexPath.row])
        // To ensure cell background integrates with insetGrouped beautifully:
        cell.backgroundColor = .secondarySystemGroupedBackground
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let profileVC = ProfileViewController()
        profileVC.patientData = patients[indexPath.row]
        profileVC.updateDelegate = self
        profileVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(profileVC, animated: true)
    }
}

// MARK: - Search Extension
extension PatientListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text?.lowercased(), !query.isEmpty else {
            patients = allPatients
            return
        }
        patients = allPatients.filter {
            $0.fullName.lowercased().contains(query) || $0.patientID.lowercased().contains(query)
        }
    }
}

// MARK: - Delegates
extension PatientListViewController: addPatientDelegate, ProfileUpdateDelegate {
    func didAddPatient(_ patient: Patient) {
        self.allPatients.insert(patient, at: 0)
        searchController.searchBar.text = ""
        searchController.isActive = false
    }
    
    func didUpdatePatient(_ updatedPatient: Patient) {
        if let index = allPatients.firstIndex(where: { $0.patientID == updatedPatient.patientID }) {
            allPatients[index] = updatedPatient
        }
    }
}
