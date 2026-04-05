import UIKit
import Supabase

class PatientDifficultiesViewController: UIViewController {

    var patientID: String?
    
    var questions: [Question] = [
        // Phase 7: Behavioral Observations
        Question(id: 1, text: "Does the child engage in self-stimulatory behaviors (stimming)?", options: ["Frequently", "Sometimes", "Rarely"], selectedOptionIndex: nil),
        Question(id: 2, text: "Does the child have rigid routines?", options: ["Yes", "Sometimes", "No"], selectedOptionIndex: nil),
        Question(id: 3, text: "Does the child have intense, narrow interests?", options: ["Yes", "Somewhat", "No"], selectedOptionIndex: nil),
        Question(id: 4, text: "Does the child have aggressive behaviors (hitting, biting, kicking)?", options: ["Frequently", "Sometimes", "Rarely"], selectedOptionIndex: nil),
        Question(id: 5, text: "Does the child engage in self-injurious behavior?", options: ["Frequently", "Sometimes", "Never"], selectedOptionIndex: nil),
        Question(id: 6, text: "Does the child have difficulty with transitions between activities?", options: ["Yes", "Sometimes", "No"], selectedOptionIndex: nil),
        Question(id: 7, text: "Does the child demonstrate frustration tolerance?", options: ["Good", "Limited", "Very limited"], selectedOptionIndex: nil),
        Question(id: 8, text: "Does the child have meltdowns vs. shutdowns?", options: ["Meltdowns", "Shutdowns", "Both"], selectedOptionIndex: nil),
        // Phase 7: Attention & Executive Function
        Question(id: 9, text: "How long can the child attend to a preferred activity?", options: ["10+ minutes", "5-10 minutes", "Under 5 minutes"], selectedOptionIndex: nil),
        Question(id: 10, text: "Can the child follow multi-step instructions?", options: ["Yes", "Sometimes", "No"], selectedOptionIndex: nil)
    ]
    
    var currentQuestionIndex = 0
    var userAnswers: [Int: Int] = [:] // QuestionIndex : OptionIndex
    
    // MARK: - UI Components
    
    // Note: We don't use 'lazy var gradientBackground' here because we set the main view to be the gradient in loadView()
    
    let progressBar: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        // Match Fine Motor Skills colors (white translucent track, solid white progress)
        pv.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        pv.progressTintColor = .white
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    let questionContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 25
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    let questionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.textColor = .label
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    let optionsContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 25
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    let optionsStackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.distribution = .fill
        s.alignment = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Next", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 25
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isEnabled = false
        btn.alpha = 0.5
        return btn
    }()
    
    // MARK: - Lifecycle

    // CRITICAL FIX: This stops the app from trying to load the broken XIB/Storyboard file
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // LOAD SESSION
        if let pid = patientID {
            let allAnswers = AssessmentSessionManager.shared.getTestAnswers(for: pid)
            if let saved = allAnswers["Patient Difficulties"] as? [Int: Int] {
                userAnswers = saved
            }
        }
        
        setupNavBar()
        setupUI()
        loadQuestion(at: currentQuestionIndex)
    }
    
    func setupNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        self.title = "Patient Difficulties"
        
        let back = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
        back.tintColor = .black
        navigationItem.leftBarButtonItem = back
    }
    
    func setupUI() {
        // Add Subviews (Note: self.view is already the GradientView from loadView)
        view.addSubview(progressBar)
        view.addSubview(questionContainer)
        questionContainer.addSubview(questionLabel)
        view.addSubview(optionsContainer)
        optionsContainer.addSubview(optionsStackView)
        view.addSubview(nextButton)
        
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        let safe = view.safeAreaLayoutGuide
        
        // Setup Constraints (Matching Fine Motor Skills exactly)
        NSLayoutConstraint.activate([
            // Progress Bar (Top 13, Height 4, Side 20)
            progressBar.topAnchor.constraint(equalTo: safe.topAnchor, constant: 13),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            progressBar.heightAnchor.constraint(equalToConstant: 4),
            
            // Question Container
            questionContainer.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 30),
            questionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            questionContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Question Label
            questionLabel.topAnchor.constraint(equalTo: questionContainer.topAnchor, constant: 20),
            questionLabel.bottomAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: -20),
            questionLabel.leadingAnchor.constraint(equalTo: questionContainer.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: questionContainer.trailingAnchor, constant: -20),
            
            // Options Container
            optionsContainer.topAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: 20),
            optionsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            optionsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Stack View
            optionsStackView.topAnchor.constraint(equalTo: optionsContainer.topAnchor),
            optionsStackView.bottomAnchor.constraint(equalTo: optionsContainer.bottomAnchor),
            optionsStackView.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor),
            optionsStackView.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor),
            
            // Next Button
            nextButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -20),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    func loadQuestion(at index: Int) {
        let q = questions[index]
        
        // Added question ID number as requested
        questionLabel.text = "\(q.id). \(q.text)"
        
        let savedAns = userAnswers[index]
        
        optionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (i, opt) in q.options.enumerated() {
            let rv = RadioOptionView()
            rv.optionLabel.text = opt
            rv.tag = i
            rv.isOn = (i == savedAns)
            rv.showSeparator(i != q.options.count - 1)
            rv.addTarget(self, action: #selector(optionSelected(_:)), for: .touchUpInside)
            optionsStackView.addArrangedSubview(rv)
        }
        
        // Fix: Ensure denominator is at least 1 to avoid division by zero crash if questions array is small
        let total = max(Float(questions.count - 1), 1.0)
        let progress = Float(currentQuestionIndex) / total
        progressBar.setProgress(progress, animated: true)
        
        let isAns = savedAns != nil
        nextButton.isEnabled = isAns
        nextButton.alpha = isAns ? 1.0 : 0.5
        nextButton.setTitle(index == questions.count - 1 ? "Submit" : "Next", for: .normal)
    }

    @objc func optionSelected(_ sender: RadioOptionView) {
        optionsStackView.arrangedSubviews.forEach { ($0 as? RadioOptionView)?.isOn = ($0 == sender) }
        
        userAnswers[currentQuestionIndex] = sender.tag
        
        // SAVE SESSION
        if let pid = patientID {
            AssessmentSessionManager.shared.updateTestAnswer(for: pid, key: "Patient Difficulties", value: userAnswers)
        }
        
        nextButton.isEnabled = true
        nextButton.alpha = 1.0
    }

    @IBAction func nextButtonTapped(_ sender: UIButton) {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            loadQuestion(at: currentQuestionIndex)
        } else {
            guard let pid = patientID else { return }
            nextButton.isEnabled = false
            nextButton.setTitle("Saving...", for: .normal)
            
            var results: [String: AnyCodable] = [:]
            
            for (idx, optIdx) in userAnswers {
                results["Q\(idx+1)"] = AnyCodable(value: questions[idx].options[optIdx])
            }
            
            let log = AssessmentLog(patient_id: pid, assessment_type: "Patient Difficulties", assessment_data: results)
            
            Task {
                do {
                    try await supabase.from("assessments").insert(log).execute()
                    await MainActor.run {
                        NotificationCenter.default.post(name: NSNotification.Name("AssessmentDidComplete"), object: nil, userInfo: ["assessmentName": "Patient Difficulties"])
                        self.navigationController?.popViewController(animated: true)
                    }
                } catch {
                    await MainActor.run { self.nextButton.isEnabled = true }
                }
            }
        }
    }
    
    @objc func backButtonTapped() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            loadQuestion(at: currentQuestionIndex)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}
