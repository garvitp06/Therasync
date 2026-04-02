import UIKit
import Supabase

class ParentAppointmentViewController: UIViewController,
                                       UITableViewDelegate,
                                       UITableViewDataSource,
                                       OTCalendarViewDelegate {

    // MARK: - Data Source
    private var appointments: [Appointment] = []
    private var filteredAppointments: [Appointment] = []
    private var selectedDate: Date = Date()

    // MARK: - UI Elements
    private var customCalendar: OTCalendarView!

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .clear
        tv.register(
            AppointmentTableViewCell.self,
            forCellReuseIdentifier: AppointmentTableViewCell.identifier
        )
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Navigation Title
        self.title = "Appointments"
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false

        setupNativeNavBar()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = false

        fetchAppointments()
    }

    // MARK: - Fetch Appointments
    private func fetchAppointments() {
        Task {
            do {
                let currentUser = try await supabase.auth.session.user
                let currentUserID = currentUser.id

                // Step 1: Get the linked patient's UUID
                // First try LastSelectedChildID from UserDefaults (patient_id_number)
                var patientUUID: UUID?

                if let savedPatientIDNumber = UserDefaults.standard.string(forKey: "LastSelectedChildID") {
                    // Resolve patient_id_number → UUID
                    struct PatientID: Decodable { let id: UUID }
                    let patientRes = try await supabase
                        .from("patients")
                        .select("id")
                        .eq("patient_id_number", value: savedPatientIDNumber)
                        .limit(1)
                        .single()
                        .execute()
                    let decoded = try JSONDecoder().decode(PatientID.self, from: patientRes.data)
                    patientUUID = decoded.id
                }

                // Fallback: find patient by parent_uid
                if patientUUID == nil {
                    struct PatientID: Decodable { let id: UUID }
                    let patientRes = try await supabase
                        .from("patients")
                        .select("id")
                        .eq("parent_uid", value: currentUserID.uuidString)
                        .limit(1)
                        .single()
                        .execute()
                    let decoded = try JSONDecoder().decode(PatientID.self, from: patientRes.data)
                    patientUUID = decoded.id
                }

                guard let linkedPatientID = patientUUID else {
                    print("❌ No linked patient found for parent")
                    return
                }

                // Step 2: Fetch appointments for this specific patient
                let response = try await supabase
                    .from("appointments")
                    .select("*, patients(*)")
                    .eq("patient_id", value: linkedPatientID)
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

                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Invalid date format: \(dateString)"
                    )
                }

                let fetched = try decoder.decode([Appointment].self, from: response.data)

                await MainActor.run {
                    self.appointments = fetched
                    self.filterAppointments(for: self.selectedDate)
                }

            } catch {
                print("❌ Parent Fetch Error:", error)
            }
        }
    }

    // MARK: - Calendar Delegate
    func didSelectDate(date: Date) {
        selectedDate = date
        filterAppointments(for: date)
    }

    // MARK: - Filtering Logic
    private func filterAppointments(for date: Date) {
        let calendar = Calendar.current

        filteredAppointments = appointments.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }

        filteredAppointments.sort { $0.date < $1.date }
        tableView.reloadData()
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredAppointments.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: AppointmentTableViewCell.identifier,
            for: indexPath
        ) as! AppointmentTableViewCell

        cell.configure(with: filteredAppointments[indexPath.row])
        cell.hideChevron()
        cell.accessoryType = .none
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }

    // MARK: - Navigation Bar Styling
    private func setupNativeNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .black
    }

    // MARK: - UI Setup
    private func setupUI() {

        let gradient = ParentGradientView(frame: view.bounds)
        gradient.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(gradient, at: 0)

        customCalendar = OTCalendarView()
        customCalendar.delegate = self
        customCalendar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customCalendar)

        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            customCalendar.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 10
            ),
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
