import UIKit
import Supabase

final class DashboardViewController: UIViewController {

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Dashboard"
        l.font = .systemFont(ofSize: 34, weight: .bold)
        // DYNAMIC: Black -> White
        l.textColor = .dynamicLabel
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Hi"
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        // DYNAMIC: Black -> White
        l.textColor = .dynamicLabel
        return l
    }()

    private let quoteContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.3)
        v.layer.cornerRadius = 16
        return v
    }()

    private let quoteTextLabel: UILabel = {
        let l = UILabel()
        l.font = .italicSystemFont(ofSize: 18)
        l.numberOfLines = 0
        l.textAlignment = .center
        l.textColor = .dynamicLabel
        return l
    }()
    
    private let parentQuotes: [String] = [
        "\"There is no such thing as a perfect parent. So just be a real one.\" - Sue Atkins",
        "\"Children are not things to be molded, but are people to be unfolded.\" - Jess Lair",
        "\"The way we talk to our children becomes their inner voice.\" - Peggy O'Mara",
        "\"To be in your children's memories tomorrow, you have to be in their lives today.\" - Barbara Johnson",
        "\"There is no single effort more radical in its potential for saving the world than a transformation of the way we raise our children.\" - Marianne Williamson",
        "\"Behind every young child who believes in himself is a parent who believed first.\" - Matthew Jacobson",
        "\"Your kids require you most of all to love them for who they are, not to spend your whole time trying to correct them.\" - Bill Ayers",
        "\"The best inheritance a parent can give his children is a few minutes of his time each day.\" - O.A. Battista",
        "\"We may not be able to prepare the future for our children, but we can at least prepare our children for the future.\" - Franklin D. Roosevelt",
        "\"Encourage your child to have muddy, roly-poly, grubby, active, loud, and noisy adventures.\" - Penny Whitehouse"
    ]

    private let quickAccessLabel: UILabel = {
        let l = UILabel()
        l.text = "Quick Access"
        l.font = .systemFont(ofSize: 22, weight: .bold)
        // DYNAMIC: Black -> White
        l.textColor = .dynamicLabel
        return l
    }()

    // Cards - Background colors remain as brand identifiers
    private let assignmentCard = QuickAccessCard(
        title: "Assignment",
        count: nil,
        systemIcon: "doc.text.fill", // Assignment icon
        color: UIColor(red: 0.95, green: 0.30, blue: 0.36, alpha: 1)
    )

    private let appointmentCard = QuickAccessCard(
        title: "Appointment",
        count: nil,
        systemIcon: "calendar", // Appointment icon
        color: UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1)
    )

    private let chatCard = QuickAccessCard(
        title: "Chat",
        count: nil,
        systemIcon: "message.fill", // Chat icon
        color: UIColor(red: 0.36, green: 0.75, blue: 0.39, alpha: 1)
    )

    private let notesCard = QuickAccessCard(
        title: "Add Notes",
        count: nil,
        systemIcon: "pencil.and.outline", // Notes icon
        color: UIColor(red: 0.68, green: 0.30, blue: 0.82, alpha: 1)
    )

    private let gamesCard = QuickAccessCard(
        title: "Games",
        count: nil,
        systemIcon: "gamecontroller.fill", // Games icon
        color: UIColor(red: 0.98, green: 0.82, blue: 0.30, alpha: 1)
    )

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupLayout()
        setupActions()
        verifyLinkingAndLoadData()
        
        if let randomQuote = parentQuotes.randomElement() {
            quoteTextLabel.text = randomQuote
        }
        
        // Listen for the theme toggle to refresh the Arc if necessary
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: NSNotification.Name("AppThemeChanged"), object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 1. Hide the bar so your manual "Dashboard" label is at the top
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadSelectedChild()
        applyTheme()
        view.layoutIfNeeded()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func applyTheme() {
        // This ensures the labels using .dynamicLabel re-evaluate their color
        view.setNeedsLayout()
        
        // If your ProgressArcView has internal colors that need to change,
        // you would call a refresh method on it here.
    }
    private func verifyLinkingAndLoadData() {
        Task {
            do {
                let user = try await supabase.auth.session.user
                
                // 1. Fetch the linking status from the profile
                let profileResponse = try await supabase
                    .from("profiles")
                    .select("linked_patient_id")
                    .eq("id", value: user.id)
                    .single()
                    .execute()
                
                let data = profileResponse.data
                let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let linkedID = dict?["linked_patient_id"] as? String

                await MainActor.run {
                    if linkedID == nil || linkedID?.isEmpty == true {
                        // CASE: Unlinked elsewhere. Force back to ID Entry screen.
                        self.redirectToEmptyState()
                    } else {
                        // CASE: Still linked. Load the patient data.
                        self.loadPatientData(for: linkedID!)
                    }
                }
            } catch {
                print("❌ Dashboard Sync Error: \(error)")
            }
        }
    }
    private func redirectToEmptyState() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        let emptyVC = ParentEmptyStateViewController()
        window.rootViewController = UINavigationController(rootViewController: emptyVC)
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil)
    }
    private func loadPatientData(for patientID: String) {
        Task {
            do {
                // Setup decoder for date safety
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                decoder.dateDecodingStrategy = .formatted(formatter)

                // Fetch the patient details
                let response = try await supabase
                    .from("patients")
                    .select()
                    .eq("patient_id_number", value: patientID)
                    .execute()

                let fetched = try decoder.decode([Patient].self, from: response.data)

                await MainActor.run {
                    if let patient = fetched.first {
                        self.subtitleLabel.text = "Hi \(patient.firstName)"
                    }
                }
            } catch {
                print("❌ Patient Load Error: \(error)")
            }
        }
    }
    func fetchLinkedChildren() {
        Task {
            do {
                let parent = try await supabase.auth.session.user
                let children: [Patient] = try await supabase
                    .from("patients")
                    .select()
                    .eq("parent_id", value: parent.id) // Only get kids linked to THIS parent
                    .execute()
                    .value
            } catch {
                print(error)
            }
        }
    }
    private func loadSelectedChild() {
        Task {
            do {
                let user = try await supabase.auth.session.user
                let currentUserId = user.id.uuidString

                let response = try await supabase
                    .from("patients")
                    .select()
                    .eq("parent_uid", value: currentUserId) // OWNER CHECK: Prevents seeing other parent's kids
                    .execute()

                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                decoder.dateDecodingStrategy = .formatted(formatter)
                
                let fetched = try decoder.decode([Patient].self, from: response.data)

                await MainActor.run {
                    if fetched.isEmpty {
                        // Force the user out if no kids are found in the database for them
                        let emptyVC = ParentEmptyStateViewController()
                        self.view.window?.rootViewController = UINavigationController(rootViewController: emptyVC)
                        return
                    }

                    // If they have kids, determine which one to show
                    let lastID = UserDefaults.standard.string(forKey: "LastSelectedChildID")
                    let patientToShow = fetched.first(where: { $0.patientID == lastID }) ?? fetched.first
                    
                    if let patient = patientToShow {
                        self.subtitleLabel.text = "Hi \(patient.firstName)"
                        UserDefaults.standard.set(patient.patientID, forKey: "LastSelectedChildID")
                    }
                }
            } catch {
                print("Dashboard Fetch Error: \(error)")
            }
        }
    }
    
    func fetchParentDashboardData() {
        Task {
            do {
                let user = try await supabase.auth.session.user
                
                // Fetch patients where the parent_uid matches the logged-in user
                let linkedPatients: [Patient] = try await supabase
                    .from("patients")
                    .select()
                    .eq("parent_uid", value: user.id)
                    .execute()
                    .value
                
                DispatchQueue.main.async {
                    if linkedPatients.isEmpty {
                        // Show the Empty State (Link Patient Screen)
                    } else {
                        // Show the Dashboard with the child's name
                        self.displayChildData(linkedPatients.first!)
                    }
                }
            } catch {
                print("Dashboard fetch error: \(error)")
            }
        }
    }
    private func displayChildData(_ patient: Patient) {
        subtitleLabel.text = "Hi \(patient.firstName)"
    }
    func fetchMyChild() {
        Task {
            do {
                let user = try await supabase.auth.session.user
                let response: [Patient] = try await supabase
                    .from("patients")
                    .select()
                    .eq("parent_id", value: user.id) // Only children linked to this UID
                    .execute()
                    .value
                
                // If empty, the dashboard remains in an empty state or returns to the link screen
                if response.isEmpty {
                    print("No child linked yet.")
                } else {
                    print("Child found: \(response.first?.fullName ?? "")")
                }
            } catch {
                print(error)
            }
        }
    }
    private func setupGradientBackground() {
        let gradientView = ParentGradientView(frame: view.bounds)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientView)
        view.sendSubviewToBack(gradientView)
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupLayout() {
            let grid = makeGrid()

            [
                titleLabel, subtitleLabel, quoteContainerView,
                quickAccessLabel, grid
            ].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview($0)
            }
            
            quoteContainerView.addSubview(quoteTextLabel)
            quoteTextLabel.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // --- ADJUSTMENT START ---
                // Increased constant from 8 to 40 to push everything down
                titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
                // --- ADJUSTMENT END ---
                
                titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

                subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
                subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

                quoteContainerView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
                quoteContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                quoteContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                
                quoteTextLabel.topAnchor.constraint(equalTo: quoteContainerView.topAnchor, constant: 16),
                quoteTextLabel.leadingAnchor.constraint(equalTo: quoteContainerView.leadingAnchor, constant: 16),
                quoteTextLabel.trailingAnchor.constraint(equalTo: quoteContainerView.trailingAnchor, constant: -16),
                quoteTextLabel.bottomAnchor.constraint(equalTo: quoteContainerView.bottomAnchor, constant: -16),

                quickAccessLabel.topAnchor.constraint(equalTo: quoteContainerView.bottomAnchor, constant: 52),
                quickAccessLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

                grid.topAnchor.constraint(equalTo: quickAccessLabel.bottomAnchor, constant: 14),
                grid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                grid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                grid.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            ])
        }

    private func makeGrid() -> UIStackView {
        let row1 = UIStackView(arrangedSubviews: [assignmentCard, appointmentCard])
        let row2 = UIStackView(arrangedSubviews: [chatCard, notesCard])
        let row3 = UIStackView(arrangedSubviews: [gamesCard, UIView()])

        [row1, row2, row3].forEach {
            $0.axis = .horizontal
            $0.spacing = 14
            $0.distribution = .fillEqually
        }

        let grid = UIStackView(arrangedSubviews: [row1, row2, row3])
        grid.axis = .vertical
        grid.spacing = 16
        return grid
    }

    // MARK: - Actions

    private func setupActions() {
        assignmentCard.addTarget(self, action: #selector(openAssignments), for: .touchUpInside)
        appointmentCard.addTarget(self, action: #selector(openAppointments), for: .touchUpInside)
        chatCard.addTarget(self, action: #selector(openChat), for: .touchUpInside)
        notesCard.addTarget(self, action: #selector(openNotes), for: .touchUpInside)
        gamesCard.addTarget(self, action: #selector(openGames), for: .touchUpInside)
    }

    @objc private func openAssignments() {
        let vc = AssignmentParentViewController()
        if let selectedID = UserDefaults.standard.string(forKey: "LastSelectedChildID") {
            vc.patientID = selectedID
        }
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func openAppointments() {
        let vc = ParentAppointmentViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func openChat() {
        let vc = ParentChatDetailViewController()
        if let selectedID = UserDefaults.standard.string(forKey: "LastSelectedChildID") {
            vc.patientID = selectedID
        }
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func openNotes() {
        let vc = ParentNotesViewController()
        
        if let selectedID = UserDefaults.standard.string(forKey: "LastSelectedChildID") {
            vc.patientID = selectedID
        }
        vc.hidesBottomBarWhenPushed = true
        // This MUST be called on a navigationController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func openGames() {
        let vc = GameListViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

