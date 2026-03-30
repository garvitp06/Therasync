import UIKit
import Supabase

class AppointmentViewController: UIViewController,
                                 UITableViewDelegate,
                                 UITableViewDataSource,
                                 OTCalendarViewDelegate,
                                 AddReminderDelegate {

    // MARK: - Data Source
    var appointments: [Appointment] = []
    var filteredAppointments: [Appointment] = []
    var selectedDate: Date = Date()

    // MARK: - Filter Mode
    private enum AppointmentFilterMode {
        case selectedDay
        case upcoming
    }

    private var filterMode: AppointmentFilterMode = .selectedDay

    // MARK: - UI Elements
    private var customCalendar: OTCalendarView!

    // ✅ Segmented control
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["Selected Day", "Upcoming"]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        sc.translatesAutoresizingMaskIntoConstraints = false
        
        // Native iOS Segment styling suitable for a dark/gradient background
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
        
        self.title = "Appointments"
        navigationItem.largeTitleDisplayMode = .always
        
        // Native add button
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        addBtn.tintColor = .
        
        navigationItem.rightBarButtonItem = addBtn
        
        setupNativeNavBar()
        setupUI()
    }

    private func setupNativeNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        fetchAppointments()
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

                // Smart Decoder (ISO8601 + Fallback)
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
            filteredAppointments = appointments.filter { $0.date >= now }
            filteredAppointments.sort { $0.date < $1.date }
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

    // MARK: - Delegates
    func didSelectDate(date: Date) {
        selectedDate = date

        // ✅ Automatically show Selected Day when user taps calendar
        filterMode = .selectedDay
        segmentedControl.selectedSegmentIndex = 0
        applyFilter()
    }

    func didAddAppointment() {
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
            sheet.preferredCornerRadius = 24
        }

        present(nav, animated: true)
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            filterMode = .selectedDay
        } else {
            filterMode = .upcoming
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

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: AppointmentTableViewCell.identifier,
            for: indexPath
        ) as! AppointmentTableViewCell

        let appt = filteredAppointments[indexPath.section]
        var display = appt

        if let name = appt.patient?.firstName {
            display.title = "\(appt.title) - \(name)"
        }

        cell.configure(with: display)
        cell.layer.cornerRadius = 16
        cell.layer.masksToBounds = true

        return cell
    }

    // MARK: - Swipe Delete
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            self?.showDeleteConfirmation(indexPath: indexPath, completion: completion)
        }

        deleteAction.image = createCircularTrashImage()
        deleteAction.backgroundColor = UIColor(red: 0.11, green: 0.45, blue: 0.98, alpha: 1.0)

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    func createCircularTrashImage() -> UIImage {
        let diameter: CGFloat = 50
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))

        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            UIColor.systemRed.setFill()
            context.cgContext.fillEllipse(in: rect)

            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
            if let trashImage = UIImage(systemName: "trash.fill", withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {

                let imageSize = trashImage.size
                let x = (diameter - imageSize.width) / 2
                let y = (diameter - imageSize.height) / 2
                trashImage.draw(at: CGPoint(x: x, y: y))
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

        customCalendar = OTCalendarView()
        customCalendar.delegate = self
        view.addSubview(customCalendar)

        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        customCalendar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // ✅ native segmented control attached to safe area
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),

            customCalendar.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            customCalendar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customCalendar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            customCalendar.heightAnchor.constraint(equalToConstant: 320),

            tableView.topAnchor.constraint(equalTo: customCalendar.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
