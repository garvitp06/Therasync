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
    // ✅ titleLabel and headerPlusButton REMOVED — replaced by native nav bar

    private let searchField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Search"
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.textColor = .white
        tf.backgroundColor = UIColor(white: 1.0, alpha: 0.10)
        tf.layer.cornerRadius = 22
        tf.clipsToBounds = true
        tf.isHidden = true

        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor = UIColor(white: 1.0, alpha: 0.85)
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 52, height: 44))
        iv.frame = CGRect(x: 16, y: 12, width: 20, height: 20)
        container.addSubview(iv)
        tf.leftView = container
        tf.leftViewMode = .always

        tf.attributedPlaceholder = NSAttributedString(
            string: "Search",
            attributes: [.foregroundColor: UIColor(white: 1.0, alpha: 0.72)]
        )
        return tf
    }()

    private let cardShadowContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.12
        v.layer.shadowRadius = 12
        v.layer.shadowOffset = CGSize(width: 0, height: 6)
        v.isHidden = true
        return v
    }()

    private let cardContentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.masksToBounds = true
        return v
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tv.tableFooterView = UIView(frame: .zero)
        tv.alwaysBounceVertical = true
        return tv
    }()

    private let refreshControl = UIRefreshControl()

    private let emptyCenterPlusButton: UIButton = {
        let b = UIButton(type: .system)
        let conf = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        b.setImage(UIImage(systemName: "plus", withConfiguration: conf), for: .normal)
        b.tintColor = .white
        b.backgroundColor = UIColor(red: 0.11, green: 0.45, blue: 0.98, alpha: 1.0)
        b.layer.cornerRadius = 36
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        return b
    }()

    private let emptyCenterLabel: UILabel = {
        let l = UILabel()
        l.text = "Add patients to see details"
        l.textColor = .white
        l.font = UIFont.systemFont(ofSize: 16)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
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

    private var cardHeightConstraint: NSLayoutConstraint?
    private let rowHeight: CGFloat = 80
    private let reservedTabBarHeight: CGFloat = 100

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()           // ✅ Native nav bar configured first
        setupGradientBackground()
        setupHeaderAndSearch()
        setupCardAndTable()
        setupEmptyState()
        setupLoadingIndicator()
        setupTapToDismiss()

        tableView.register(PatientCell.self, forCellReuseIdentifier: "PatientCell")
        tableView.dataSource = self
        tableView.delegate = self

        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        emptyCenterPlusButton.addTarget(self, action: #selector(handleNavPlus), for: .touchUpInside)
        searchField.addTarget(self, action: #selector(searchFieldChanged(_:)), for: .editingChanged)

        fetchPatients()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // ✅ Show native nav bar (was previously hidden)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        fetchPatients()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCardHeightIfNeeded()
    }

    // MARK: - ✅ Native Nav Bar Setup
    private func setupNavBar() {
        // Large title "Patients" in white
        title = "Patients"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        // Transparent so the gradient background shows through
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 36, weight: .bold)
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white  // Makes the + icon white

        // ✅ Native system "+" bar button item
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(handleNavPlus)
        )
    }

    // MARK: - Layout Setup
    private func setupGradientBackground() {
        let gradient = GradientView()
        gradient.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradient)
        view.sendSubviewToBack(gradient)
        NSLayoutConstraint.activate([
            gradient.topAnchor.constraint(equalTo: view.topAnchor),
            gradient.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradient.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradient.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupHeaderAndSearch() {
        // ✅ Only searchField remains — title and plus button live in the nav bar now
        view.addSubview(searchField)

        NSLayoutConstraint.activate([
            // ✅ Search field anchors directly to safe area (nav bar accounts for its own height)
            searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupCardAndTable() {
        view.addSubview(cardShadowContainer)
        cardShadowContainer.addSubview(cardContentView)
        cardContentView.addSubview(tableView)
        tableView.tableFooterView = UIView()
        cardHeightConstraint = cardShadowContainer.heightAnchor.constraint(equalToConstant: 0)
        cardHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            cardShadowContainer.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 12),
            cardShadowContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardShadowContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            cardContentView.topAnchor.constraint(equalTo: cardShadowContainer.topAnchor),
            cardContentView.leadingAnchor.constraint(equalTo: cardShadowContainer.leadingAnchor),
            cardContentView.trailingAnchor.constraint(equalTo: cardShadowContainer.trailingAnchor),
            cardContentView.bottomAnchor.constraint(equalTo: cardShadowContainer.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: cardContentView.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: cardContentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: cardContentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: cardContentView.bottomAnchor, constant: -10)
        ])
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
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupTapToDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
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

        updateCardHeightIfNeeded()

        // ✅ titleLabel and headerPlusButton lines removed — nav bar handles both
        searchField.isHidden = !databaseHasData
        cardShadowContainer.isHidden = !databaseHasData

        emptyCenterPlusButton.isHidden = !showEmptyState
        emptyCenterLabel.isHidden = !showEmptyState

        tableView.reloadData()
    }

    private func updateCardHeightIfNeeded() {
        guard let heightConstraint = cardHeightConstraint else { return }
        if patients.isEmpty {
            heightConstraint.constant = 0
        } else {
            let totalNeeded = CGFloat(patients.count) * rowHeight + 20
            let topOfCard = searchField.frame.maxY > 0 ? searchField.frame.maxY + 12 : 160
            let maxAvailable = view.bounds.height - topOfCard - reservedTabBarHeight - view.safeAreaInsets.bottom
            heightConstraint.constant = min(totalNeeded, maxAvailable)
            tableView.isScrollEnabled = totalNeeded > maxAvailable
        }
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
    }

    @objc private func handleNavPlus() {
        let addVC = addPatient()
        addVC.delegate = self
        let nav = UINavigationController(rootViewController: addVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    @objc private func searchFieldChanged(_ tf: UITextField) {
        guard let query = tf.text?.lowercased(), !query.isEmpty else {
            patients = allPatients
            return
        }
        patients = allPatients.filter {
            $0.fullName.lowercased().contains(query) || $0.patientID.contains(query)
        }
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
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
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

// MARK: - Delegates
extension PatientListViewController: addPatientDelegate, ProfileUpdateDelegate {
    func didAddPatient(_ patient: Patient) {
        self.allPatients.insert(patient, at: 0)
        searchField.text = ""
    }

    func didUpdatePatient(_ updatedPatient: Patient) {
        if let index = allPatients.firstIndex(where: { $0.patientID == updatedPatient.patientID }) {
            allPatients[index] = updatedPatient
        }
    }
}

extension PatientListViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        patients = allPatients
        textField.resignFirstResponder()
        return true
    }
}
