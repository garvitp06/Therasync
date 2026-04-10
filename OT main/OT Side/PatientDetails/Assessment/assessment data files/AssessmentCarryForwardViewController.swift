import UIKit
import Supabase

/// Intermediary screen shown for "static" (history/factual) assessments.
/// If a previous record exists, offers "Carry Forward" or "Review & Edit".
/// If no previous record exists, immediately pushes to the standard form VC.
final class AssessmentCarryForwardViewController: UIViewController {

    // MARK: - Inputs
    var patientID: String?
    var assessmentType: String = ""   // e.g. "Birth History", "Feeding"
    var subSection: String?           // For multi-subsection VCs (DailyLiving, Developmental, Family)

    /// The VC factory that creates the standard form for "Review & Edit" or first-time entry
    var formVCFactory: (() -> UIViewController)?

    // MARK: - Fetched State
    private var previousData: [String: Any]?
    private var previousDate: Date?

    // MARK: - UI
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.12
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 10
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        iv.image = UIImage(systemName: "doc.on.doc.fill", withConfiguration: config)
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textColor = .label
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let carryForwardButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Carry Forward", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.backgroundColor = .systemBlue
        b.layer.cornerRadius = 25
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let reviewButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Review & Edit", for: .normal)
        b.setTitleColor(.systemBlue, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.backgroundColor = .clear
        b.layer.cornerRadius = 25
        b.layer.borderWidth = 1.5
        b.layer.borderColor = UIColor.systemBlue.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.color = .white
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let buttonSpinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.color = .white
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Lifecycle
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = assessmentType
        setupNavBar()
        setupUI()
        fetchPreviousAssessment()
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.reviewButton.layer.borderColor = UIColor.systemBlue.cgColor
                self.cardView.layer.shadowColor = UIColor.black.cgColor
            }
        }
    }

    // MARK: - Nav Bar
    private func setupNavBar() {
        navigationItem.largeTitleDisplayMode = .never
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(spinner)
        view.addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(carryForwardButton)
        cardView.addSubview(reviewButton)
        carryForwardButton.addSubview(buttonSpinner)

        // Initially hide the card while loading
        cardView.alpha = 0

        carryForwardButton.addTarget(self, action: #selector(carryForwardTapped), for: .touchUpInside)
        reviewButton.addTarget(self, action: #selector(reviewTapped), for: .touchUpInside)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            iconView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 32),
            iconView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            carryForwardButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            carryForwardButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            carryForwardButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            carryForwardButton.heightAnchor.constraint(equalToConstant: 50),

            reviewButton.topAnchor.constraint(equalTo: carryForwardButton.bottomAnchor, constant: 12),
            reviewButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            reviewButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            reviewButton.heightAnchor.constraint(equalToConstant: 50),
            reviewButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -28),

            buttonSpinner.centerXAnchor.constraint(equalTo: carryForwardButton.centerXAnchor),
            buttonSpinner.centerYAnchor.constraint(equalTo: carryForwardButton.centerYAnchor),
        ])
    }

    // MARK: - Fetch Previous
    private func fetchPreviousAssessment() {
        guard let pid = patientID else {
            pushToFormDirectly()
            return
        }

        spinner.startAnimating()

        Task {
            do {
                // Use AnyCodable to handle mixed-type jsonb values
                struct AssessmentRecord: Decodable {
                    let id: Int
                    let assessment_data: [String: AnyCodable]
                    let created_at: String
                }

                let response = try await supabase
                    .from("assessments")
                    .select("id, assessment_data, created_at")
                    .eq("patient_id", value: pid)
                    .eq("assessment_type", value: assessmentType)
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()

                let decodedArray = try JSONDecoder().decode([AssessmentRecord].self, from: response.data)
                
                guard let decoded = decodedArray.first else {
                    throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "No previous record found"])
                }

                // Parse date
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let date = formatter.date(from: decoded.created_at)

                // Convert AnyCodable values to their underlying Any values
                var rawData: [String: Any] = [:]
                for (key, val) in decoded.assessment_data {
                    rawData[key] = val.value
                }

                await MainActor.run {
                    self.spinner.stopAnimating()
                    self.previousData = rawData
                    self.previousDate = date
                    self.showCarryForwardCard()
                }
            } catch {
                print("CarryForward fetch error: \(error)")
                // No previous record found — go directly to form
                await MainActor.run {
                    self.spinner.stopAnimating()
                    self.pushToFormDirectly()
                }
            }
        }
    }

    // MARK: - Show Card
    private func showCarryForwardCard() {
        let filledCount = previousData?.values.filter({ "\($0)" != "" }).count ?? 0

        titleLabel.text = "Previous Data Found"

        let dateStr: String
        if let date = previousDate {
            let f = DateFormatter()
            f.dateStyle = .medium
            dateStr = f.string(from: date)
        } else {
            dateStr = "Unknown date"
        }

        subtitleLabel.text = "Last \(assessmentType) from \(dateStr)\n\(filledCount) field\(filledCount == 1 ? "" : "s") answered.\n\nCarry forward to skip re-entering unchanged data, or review to make edits."

        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5) {
            self.cardView.alpha = 1
        }
    }

    // MARK: - Actions
    @objc private func carryForwardTapped() {
        guard let pid = patientID, let data = previousData else { return }

        carryForwardButton.isEnabled = false
        carryForwardButton.setTitle("", for: .normal)
        buttonSpinner.startAnimating()
        reviewButton.isEnabled = false

        // Build the assessment log with previous data
        var dbData: [String: AnyCodable] = [:]
        for (key, val) in data {
            dbData[key] = AnyCodable(value: val)
        }

        let log = AssessmentLog(
            patient_id: pid,
            assessment_type: assessmentType,
            assessment_data: dbData
        )

        Task {
            do {
                try await supabase.from("assessments").insert(log).execute()
                await MainActor.run {
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    // Post completion notification
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AssessmentDidComplete"),
                        object: nil,
                        userInfo: ["assessmentName": self.assessmentType]
                    )
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.carryForwardButton.isEnabled = true
                    self.carryForwardButton.setTitle("Carry Forward", for: .normal)
                    self.buttonSpinner.stopAnimating()
                    self.reviewButton.isEnabled = true

                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    @objc private func reviewTapped() {
        pushToFormDirectly()
    }

    // MARK: - Navigate to Form
    private func pushToFormDirectly() {
        guard let factory = formVCFactory else {
            navigationController?.popViewController(animated: true)
            return
        }

        let formVC = factory()

        // Replace self in the navigation stack so back goes to the assessment list, not this screen
        if var viewControllers = navigationController?.viewControllers,
           let idx = viewControllers.firstIndex(of: self) {
            viewControllers[idx] = formVC
            navigationController?.setViewControllers(viewControllers, animated: true)
        } else {
            navigationController?.pushViewController(formVC, animated: true)
        }
    }

}
