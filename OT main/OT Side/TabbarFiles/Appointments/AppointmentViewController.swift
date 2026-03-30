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

    // ✅ titleLabel and addButton REMOVED — replaced by native nav bar

    // ✅ Dropdown filter button
    private lazy var filterButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Selected Day ▾", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        btn.layer.cornerRadius = 14
        btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
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
        setupNavBar()   // ✅ Configure native nav bar
        setupUI()
        setupFilterMenu()
        updateFilterMenuTitle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // ✅ Show the nav bar (was previously hidden)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        fetchAppointments()
    }

    // MARK: - ✅ Native Nav Bar Setup
    private func setupNavBar() {
        // Large title "Appointments" in white
        title = "Appointments"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        // Transparent appearance so the gradient background shows through
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
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
            action: #selector(didTapAdd)
        )
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
        updateFilterMenuTitle()
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

    // MARK: - Dropdown Menu
    private func setupFilterMenu() {

        let selectedDayAction = UIAction(
            title: "Selected Day",
            image: UIImage(systemName: "calendar")
        ) { [weak self] _ in
            guard let self else { return }
            self.filterMode = .selectedDay
            self.updateFilterMenuTitle()
            self.applyFilter()
        }

        let upcomingAction = UIAction(
            title: "Upcoming Appointments",
            image: UIImage(systemName: "clock")
        ) { [weak self] _ in
            guard let self else { return }
            self.filterMode = .upcoming
            self.updateFilterMenuTitle()
            self.applyFilter()
        }

        filterButton.menu = UIMenu(title: "", options: .displayInline, children: [
            selectedDayAction,
            upcomingAction
        ])

        filterButton.showsMenuAsPrimaryAction = true
    }

    private func updateFilterMenuTitle() {
        switch filterMode {
        case .selectedDay:
            filterButton.setTitle("Selected Day ▾", for: .normal)
        case .upcoming:
            filterButton.setTitle("Upcoming ▾", for: .normal)
        }
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

        // ✅ titleLabel and addButton removed — nav bar handles both now
        view.addSubview(filterButton)

        customCalendar = OTCalendarView()
        customCalendar.delegate = self
        view.addSubview(customCalendar)

        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        customCalendar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // ✅ filterButton now anchors directly under the safe area (nav bar handles the title)
            filterButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            customCalendar.topAnchor.constraint(equalTo: filterButton.bottomAnchor, constant: 12),
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
