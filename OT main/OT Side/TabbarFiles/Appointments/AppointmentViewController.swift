import UIKit
import Supabase

class AppointmentViewController: UIViewController,
                                 UITableViewDelegate,
                                 UITableViewDataSource,
                                 AddReminderDelegate,
                                 AppointmentCellDelegate,
                                 EditAppointmentDelegate,
                                 OTCalendarViewDelegate { // ✅ Swapped to your custom delegate

    // MARK: - Data Source
    var appointments: [Appointment] = []
    var filteredAppointments: [Appointment] = []
    var selectedDate: Date = Date()
    
    // MARK: - Filter Mode
    private enum AppointmentFilterMode {
        case selectedDay
        case upcoming
        case previous
    }
    
    private var filterMode: AppointmentFilterMode = .selectedDay
    
    // MARK: - UI Elements
    
    // ✅ Replaced native calendar with your custom OTCalendarView
    private let customCalendar: OTCalendarView = {
        let cv = OTCalendarView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        // Optional: Add shadow to match your UI aesthetic
        cv.layer.shadowColor = UIColor.black.cgColor
        cv.layer.shadowOpacity = 0.08
        cv.layer.shadowRadius = 10
        cv.layer.shadowOffset = CGSize(width: 0, height: 4)
        cv.layer.masksToBounds = false
        return cv
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["Selected Day", "Upcoming", "Previous"]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        sc.translatesAutoresizingMaskIntoConstraints = false
        
        sc.selectedSegmentTintColor = .white
        sc.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        return sc
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.register(AppointmentTableViewCell.self,
                    forCellReuseIdentifier: AppointmentTableViewCell.identifier)
        return tv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        fetchAppointments()
    }
    
    // MARK: - Native Nav Bar Setup
    private func setupNavBar() {
        self.title = "Appointments"
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        addBtn.tintColor = .black
        navigationItem.rightBarButtonItem = addBtn
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }
    
    // MARK: - Fetching Logic
    func fetchAppointments() {
        Task {
            do {
                let userID = try await supabase.auth.session.user.id
                
                let response = try await supabase
                    .from("appointments")
                    .select("*, patients(*)")
                    .eq("therapist_id", value: userID)
                    .order("date", ascending: true)
                    .execute()
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = isoFormatter.date(from: dateString) { return date }
                    
                    isoFormatter.formatOptions = [.withInternetDateTime]
                    if let date = isoFormatter.date(from: dateString) { return date }
                    
                    let simpleFormatter = DateFormatter()
                    simpleFormatter.dateFormat = "yyyy-MM-dd"
                    if let date = simpleFormatter.date(from: dateString) { return date }
                    
                    throw DecodingError.dataCorruptedError(in: container,
                                                           debugDescription: "Invalid date: \(dateString)")
                }
                
                let fetchedAppointments = try decoder.decode([Appointment].self, from: response.data)
                
                await MainActor.run {
                    self.appointments = fetchedAppointments
                    
                    // ✅ Feed the dates directly into your custom calendar to show the dots
                    self.customCalendar.appointmentDates = fetchedAppointments.map { $0.date }
                    
                    self.applyFilter()
                }
                
            } catch {
                print("❌ Fetch Error: \(error)")
            }
        }
    }
    
    // MARK: - Filtering
    private func applyFilter() {
        let calendar = Calendar.current
        
        switch filterMode {
        case .selectedDay:
            filteredAppointments = appointments.filter {
                calendar.isDate($0.date, inSameDayAs: selectedDate)
            }
            filteredAppointments.sort { $0.date < $1.date }
            
        case .upcoming:
            let now = Date()
            filteredAppointments = appointments.filter { $0.date >= now && $0.status.lowercased() != "completed" }
            filteredAppointments.sort { $0.date < $1.date }
            
        case .previous:
            let now = Date()
            filteredAppointments = appointments.filter { $0.status.lowercased() == "completed" || $0.date < now }
            filteredAppointments.sort { $0.date > $1.date }
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Delete Logic
    func deleteAppointment(at indexPath: IndexPath) {
        let apptToDelete = filteredAppointments[indexPath.section]
        guard let id = apptToDelete.id else { return }
        
        filteredAppointments.remove(at: indexPath.section)
        tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
        
        Task {
            do {
                try await supabase.from("appointments")
                    .delete()
                    .eq("id", value: id)
                    .execute()
                
                if let index = appointments.firstIndex(where: { $0.id == id }) {
                    appointments.remove(at: index)
                }
                
            } catch {
                print("❌ Delete Error: \(error)")
                fetchAppointments()
            }
        }
    }

    // MARK: - ✅ OTCalendarView Delegate
    func didSelectDate(date: Date) {
        selectedDate = date
        filterMode = .selectedDay
        segmentedControl.selectedSegmentIndex = 0
        applyFilter()
    }

    func didAddAppointment() {
        fetchAppointments()
    }
    
    func didUpdateAppointment() {
        fetchAppointments()
    }

    @objc func didTapAdd() {
        let vc = AddReminderViewController()
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        
        nav.modalPresentationStyle = .pageSheet
        
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 26
        }
        
        present(nav, animated: true)
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            filterMode = .selectedDay
        } else if sender.selectedSegmentIndex == 1 {
            filterMode = .upcoming
        } else {
            filterMode = .previous
        }
        applyFilter()
    }
    
    // MARK: - TableView Data Source
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredAppointments.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 4 }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: AppointmentTableViewCell.identifier,
            for: indexPath
        ) as! AppointmentTableViewCell
        
        let appt = filteredAppointments[indexPath.section]
        cell.configure(with: appt)
        cell.delegate = self
        cell.layer.cornerRadius = 26
        cell.layer.masksToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }

    // MARK: - AppointmentCellDelegate (Chevron → Patient Profile)
    // MARK: - AppointmentCellDelegate (Cell Tap → Patient Profile)
    func didTapCell(for appointment: Appointment) {
        guard let patient = appointment.patient else {
            let alert = UIAlertController(title: "No Patient",
                                          message: "No patient data linked to this appointment.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let profileVC = ProfileViewController()
        profileVC.patientData = patient
        profileVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect the row immediately so it doesn't stay gray
        tableView.deselectRow(at: indexPath, animated: true)

        // Get the appointment for the tapped row
        let appt = filteredAppointments[indexPath.section]

        // Trigger the exact same navigation logic
        didTapCell(for: appt)
    }

    // MARK: - Swipe Actions
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let appt = filteredAppointments[indexPath.section]
        let isCompleted = appt.status.lowercased() == "completed"

        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            self?.showDeleteConfirmation(indexPath: indexPath, completion: completion)
        }
        deleteAction.image = createCircularImage(systemName: "trash.fill", backgroundColor: .systemRed)
        deleteAction.backgroundColor = .systemBackground

        let infoAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            self?.openEditAppointment(at: indexPath)
            completion(true)
        }
        infoAction.image = createCircularImage(systemName: "info.circle.fill", backgroundColor: .systemBlue)
        infoAction.backgroundColor = .systemBackground

        var actions = [deleteAction, infoAction]
        
        if !isCompleted {
            let completeAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
                self?.markAppointmentComplete(at: indexPath)
                completion(true)
            }
            completeAction.image = createCircularImage(systemName: "checkmark.circle.fill", backgroundColor: .systemGreen)
            completeAction.backgroundColor = .systemBackground
            actions.append(completeAction)
        }

        let configuration = UISwipeActionsConfiguration(actions: actions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    // MARK: - Mark as Complete
    private func markAppointmentComplete(at indexPath: IndexPath) {
        let appt = filteredAppointments[indexPath.section]
        guard let id = appt.id else { return }
        
        Task {
            do {
                struct StatusUpdate: Encodable {
                    let status: String
                }
                let payload = StatusUpdate(status: "completed")
                
                try await supabase.from("appointments")
                    .update(payload)
                    .eq("id", value: id)
                    .execute()
                
                await MainActor.run {
                    self.fetchAppointments()
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Open Edit/Reschedule Modal
    private func openEditAppointment(at indexPath: IndexPath) {
        let appt = filteredAppointments[indexPath.section]
        
        let editVC = EditAppointmentViewController()
        editVC.appointment = appt
        editVC.delegate = self
        
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .pageSheet
        
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 26
        }
        
        present(nav, animated: true)
    }

    func createCircularImage(systemName: String, backgroundColor: UIColor) -> UIImage {
        let diameter: CGFloat = 50
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        
        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            backgroundColor.setFill()
            context.cgContext.fillEllipse(in: rect)

            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            if let icon = UIImage(systemName: systemName, withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {

                let imageSize = icon.size
                let x = (diameter - imageSize.width) / 2
                let y = (diameter - imageSize.height) / 2
                icon.draw(at: CGPoint(x: x, y: y))
            }
        }
    }
    
    func showDeleteConfirmation(indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Delete Appointment?",
                                      message: "This cannot be undone.",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion(false) })
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteAppointment(at: indexPath)
            completion(true)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - UI Setup
    func setupUI() {
        let gradient = GradientView()
        gradient.frame = view.bounds
        gradient.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(gradient, at: 0)

        view.addSubview(segmentedControl)
        
        // ✅ Add your custom calendar directly (no container needed, it handles its own background)
        view.addSubview(customCalendar)
        customCalendar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // ✅ Your custom calendar layout.
            // Fixed height to ~340 so your UICollectionView grid has enough space for 6 rows
            customCalendar.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            customCalendar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customCalendar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            customCalendar.heightAnchor.constraint(equalToConstant: 340),
            
            tableView.topAnchor.constraint(equalTo: customCalendar.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
