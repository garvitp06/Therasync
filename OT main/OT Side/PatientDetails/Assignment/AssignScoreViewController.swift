import UIKit
import Supabase

struct GradeUpdate: Encodable {
    let score: Int
    let remarks: String
}

class AssignScoreViewController: UIViewController {
    
    var submissionID: UUID?
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        // Dismiss keyboard when dragging
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()

    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 40, right: 16)
        return stackView
    }()
    
    private let scoreContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground.withAlphaComponent(0.9)
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.text = "Total Score (0-10)"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let scoreTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "0"
        tf.font = .systemFont(ofSize: 32, weight: .bold)
        tf.textAlignment = .center
        tf.keyboardType = .numberPad
        tf.textColor = .systemBlue
        return tf
    }()
    
    private let feedbackLabel: UILabel = {
        let label = UILabel()
        label.text = "Clinical Remarks"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white // Assuming dark gradient background
        return label
    }()
    
    private let feedbackTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.backgroundColor = .systemBackground.withAlphaComponent(0.9)
        tv.textColor = .label
        tv.layer.cornerRadius = 16
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.heightAnchor.constraint(equalToConstant: 150).isActive = true
        return tv
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Score", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 25
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        return spinner
    }()

    // MARK: - View Lifecycle

    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        setupLayout()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }
    
    // FIX: Hide Tab Bar when entering, show when leaving
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    // MARK: - Setup Functions

    private func setupNavigationBar() {
        title = "Assign Score"
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(mainStackView)
        
        let scoreStack = UIStackView(arrangedSubviews: [scoreLabel, scoreTextField])
        scoreStack.axis = .vertical
        scoreStack.alignment = .center
        scoreStack.spacing = 8
        
        scoreContainer.addSubview(scoreStack)
        scoreStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scoreStack.topAnchor.constraint(equalTo: scoreContainer.topAnchor, constant: 20),
            scoreStack.bottomAnchor.constraint(equalTo: scoreContainer.bottomAnchor, constant: -20),
            scoreStack.leadingAnchor.constraint(equalTo: scoreContainer.leadingAnchor, constant: 16),
            scoreStack.trailingAnchor.constraint(equalTo: scoreContainer.trailingAnchor, constant: -16)
        ])
        
        mainStackView.addArrangedSubview(scoreContainer)
        mainStackView.setCustomSpacing(32, after: scoreContainer)
        mainStackView.addArrangedSubview(feedbackLabel)
        mainStackView.addArrangedSubview(feedbackTextView)
        mainStackView.setCustomSpacing(40, after: feedbackTextView)
        
        // Add spinner to button
        saveButton.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: saveButton.trailingAnchor, constant: -20)
        ])
        
        mainStackView.addArrangedSubview(saveButton)
    }

    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            mainStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            mainStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    // MARK: - Actions

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func saveButtonTapped() {
        // Validation Checks
        guard let sID = submissionID else {
            showAlert(title: "Error", message: "No submission found to grade. Please try refreshing the previous screen.")
            return
        }
        
        guard let scoreText = scoreTextField.text, let score = Int(scoreText), score >= 0, score <= 10 else {
            showAlert(title: "Invalid Score", message: "Please enter a valid numeric score between 0 and 10.")
            return
        }
        
        let remarks = feedbackTextView.text ?? ""

        // Start Loading UI
        setLoading(true)

        Task {
            do {
                let update = GradeUpdate(score: score, remarks: remarks)
                try await supabase
                    .from("assignment_submissions")
                    .update(update)
                    .eq("id", value: sID)
                    .execute()
                
                await MainActor.run {
                    self.setLoading(false)
                    // Success Haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Show Confirmation Alert before popping
                    let alert = UIAlertController(title: "Success", message: "Score saved successfully.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    print("❌ Error saving score: \(error)")
                    self.showAlert(title: "Failed", message: "Could not save score: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func setLoading(_ loading: Bool) {
        saveButton.isEnabled = !loading
        saveButton.setTitle(loading ? "Saving..." : "Save Score", for: .normal)
        if loading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
