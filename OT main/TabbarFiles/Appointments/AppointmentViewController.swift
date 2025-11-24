import UIKit

// Conform to the delegate to receive data
class AppointmentViewController: UIViewController, AddReminderDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var mainDatePicker: UIDatePicker!
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Data

    private var appointments = [
        ("12:00 PM", "Sudhanshu Therapy", "26.06.24"),
        ("2:00 PM", "Vishal Mentors Meet", "26.06.24"),
        ("2:30 PM", "Rishi Therapy", "26.06.24"),
        ("4:00 PM", "Sahil Therapy", "26.06.24")
    ]

    private let gradientLayer = CAGradientLayer()

    // --- ADDED: Programmatic title label + top add button to match Patients screen ----
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Appointments"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let topAddButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 1.0, alpha: 0.18)
        button.layer.cornerRadius = 22
        button.layer.masksToBounds = true
        return button
    }()
    // -----------------------------------------------------------------------------------

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // IMPORTANT: Hide the navigation bar immediately so safeArea.top matches the Patients screen.
        // Use animated: false to avoid transitional layout where safeArea differs.
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup TableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear

        // Register Custom Cell (Ensure "AppointmentTableViewCell.xib" exists)
        let cellNib = UINib(nibName: "AppointmentTableViewCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "AppointmentCell")

        // DO NOT set `title = "Appointment"` because we use a custom titleLabel pinned to safeArea.top

        setupBackgroundGradient()
        styleUI()

        // ---- Add programmatic title label & top add button (match Patients screen) ----
        view.addSubview(titleLabel)
        view.addSubview(topAddButton)
        topAddButton.addTarget(self, action: #selector(addReminderTapped), for: .touchUpInside)

        // Ensure IB-outlet views will be controlled by our constraints
        mainDatePicker.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // Ensure datePicker is transparent (so gradient shows through)
        mainDatePicker.backgroundColor = .clear
        mainDatePicker.alpha = 1.0

        // Add a tiny shadow to the title to help it stand out on the gradient
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.12
        titleLabel.layer.shadowRadius = 4
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 2)

        // Give higher z-position so it's unlikely to be covered
        titleLabel.layer.zPosition = 1000
        topAddButton.layer.zPosition = 1000

        // Activate constraints
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // title at top-left like Patients
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),

            // topAddButton top-right aligned with title
            topAddButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            topAddButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            topAddButton.widthAnchor.constraint(equalToConstant: 44),
            topAddButton.heightAnchor.constraint(equalToConstant: 44),

            // mainDatePicker positioned under the title
            mainDatePicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            mainDatePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            mainDatePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            // set a reasonable calendar height (adjust as needed for your calendar style)
            mainDatePicker.heightAnchor.constraint(equalToConstant: 260),

            // tableView flows under the date picker
            tableView.topAnchor.constraint(equalTo: mainDatePicker.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // keep bottom pinned to safe area (if you have a custom tab bar, adjust constant accordingly)
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])

        // Ensure title and add button appear above calendar/datePicker
        view.bringSubviewToFront(titleLabel)
        view.bringSubviewToFront(topAddButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds

        // Final safety: bring the title & add button to front after layout to avoid any subview reordering
        view.bringSubviewToFront(titleLabel)
        view.bringSubviewToFront(topAddButton)
    }

    // MARK: - UI Helpers
    private func setupBackgroundGradient() {
        let topColor = UIColor(red: 69.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
        let bottomColor = UIColor.systemGray6.cgColor
        gradientLayer.colors = [topColor, bottomColor]
        gradientLayer.locations = [0.0, 0.4]
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func styleUI() {
        tableView.layer.cornerRadius = 26
        tableView.layer.masksToBounds = true
        mainDatePicker?.backgroundColor = .clear
    }

    // MARK: - Actions
    @objc private func addReminderTapped() {
        // 1. Instantiate the AddReminderViewController directly
        // This calls the init() we defined which loads the XIB
        let addVC = AddReminderViewController()

        // 2. Set self as the delegate to receive data
        addVC.delegate = self

        // 3. Present it
        addVC.modalPresentationStyle = .pageSheet
        present(addVC, animated: true)
    }

    // MARK: - AddReminderDelegate Method
    func didAddAppointment(title: String, subtitle: String, date: Date, time: Date) {
        // Format Data to strings matching your tuple structure
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: time)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        let dateString = dateFormatter.string(from: date)

        let fullTitle = subtitle.isEmpty ? title : "\(title) - \(subtitle)"

        // Append to array
        let newAppointment = (timeString, fullTitle, dateString)
        appointments.append(newAppointment)

        // Refresh Table
        tableView.reloadData()
    }
}

// MARK: - TableView DataSource & Delegate
extension AppointmentViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appointments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AppointmentCell", for: indexPath) as? AppointmentTableViewCell else {
            return UITableViewCell()
        }

        let (time, title, date) = appointments[indexPath.row]
        cell.configure(time: time, title: title, date: date)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
