import UIKit
import Supabase

class CognitiveSkillsViewController: UIViewController {

    var patientID: String?
    
    var questions: [Question] = [
        Question(id: 1, text: "Which object is soft?", options: ["Teddy Bear", "Pencil Box", "Chair", "Ladder"], selectedOptionIndex: nil),
        Question(id: 2, text: "Which number comes after 5?", options: ["2", "7", "1", "4"], selectedOptionIndex: nil),
        Question(id: 3, text: "What is the shape of a ball?", options: ["Square", "Rectangle", "Circle", "Triangle"], selectedOptionIndex: nil),
        Question(id: 4, text: "Which animal says 'Meow'?", options: ["Dog", "Cat", "Cow", "Bird"], selectedOptionIndex: nil),
        Question(id: 5, text: "What color is a banana?", options: ["Red", "Blue", "Yellow", "Purple"], selectedOptionIndex: nil),
        Question(id: 6, text: "Which one is cold?", options: ["Fire", "Soup", "Ice Cream", "Sun"], selectedOptionIndex: nil),
        Question(id: 7, text: "What do you use to see?", options: ["Ears", "Eyes", "Nose", "Hands"], selectedOptionIndex: nil),
        Question(id: 8, text: "Which one is bigger?", options: ["Elephant", "Mouse", "Ant", "Cat"], selectedOptionIndex: nil),
        Question(id: 9, text: "Match the shapes: Triangle", options: ["3 sides", "4 sides", "No sides", "5 sides"], selectedOptionIndex: nil),
        Question(id: 10, text: "What do you do when you are tired?", options: ["Run", "Sleep", "Eat", "Jump"], selectedOptionIndex: nil)
    ]
    var currentQuestionIndex = 0

    // UI Elements
    lazy var gradientBackground: GradientView = { let v = GradientView(); v.translatesAutoresizingMaskIntoConstraints = false; return v }()
    let progressBar: UIProgressView = { let pv = UIProgressView(progressViewStyle: .default); pv.trackTintColor = UIColor.white.withAlphaComponent(0.3); pv.progressTintColor = .white; pv.translatesAutoresizingMaskIntoConstraints = false; return pv }()
    let questionContainer: UIView = { let v = UIView(); v.backgroundColor = .white; v.layer.cornerRadius = 25; v.translatesAutoresizingMaskIntoConstraints = false; return v }()
    let questionLabel: UILabel = { let l = UILabel(); l.font = UIFont.systemFont(ofSize: 18, weight: .medium); l.textColor = .black; l.numberOfLines = 0; l.translatesAutoresizingMaskIntoConstraints = false; return l }()
    let optionsContainer: UIView = { let v = UIView(); v.backgroundColor = .white; v.layer.cornerRadius = 25; v.clipsToBounds = true; v.translatesAutoresizingMaskIntoConstraints = false; return v }()
    let optionsStack: UIStackView = { let s = UIStackView(); s.axis = .vertical; s.distribution = .fill; s.alignment = .fill; s.translatesAutoresizingMaskIntoConstraints = false; return s }()
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // RESTORE SESSION (UPDATED FOR PATIENT ID)
        if let pid = patientID {
            let allAnswers = AssessmentSessionManager.shared.getTestAnswers(for: pid)
            if let saved = allAnswers["Cognitive Skills"] as? [Int: Int] {
                for (idx, optIdx) in saved {
                    if idx < questions.count { questions[idx].selectedOptionIndex = optIdx }
                }
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
        self.title = "Cognitive Skills"
        
        let back = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
        back.tintColor = .black
        navigationItem.leftBarButtonItem = back
    }
    
    func setupUI() {
        view.addSubview(gradientBackground); view.addSubview(progressBar); view.addSubview(questionContainer); questionContainer.addSubview(questionLabel); view.addSubview(optionsContainer); optionsContainer.addSubview(optionsStack); view.addSubview(nextButton)
        nextButton.addSubview(buttonSpinner)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            gradientBackground.topAnchor.constraint(equalTo: view.topAnchor), gradientBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor), gradientBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor), gradientBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), progressBar.heightAnchor.constraint(equalToConstant: 4), progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 13),
            questionContainer.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 30), questionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), questionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), questionContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            questionLabel.topAnchor.constraint(equalTo: questionContainer.topAnchor, constant: 20), questionLabel.bottomAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: -20), questionLabel.leadingAnchor.constraint(equalTo: questionContainer.leadingAnchor, constant: 20), questionLabel.trailingAnchor.constraint(equalTo: questionContainer.trailingAnchor, constant: -20),
            
            buttonSpinner.centerXAnchor.constraint(equalTo: nextButton.centerXAnchor),
            buttonSpinner.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor),
            
            optionsContainer.topAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: 20), optionsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), optionsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            optionsStack.topAnchor.constraint(equalTo: optionsContainer.topAnchor), optionsStack.bottomAnchor.constraint(equalTo: optionsContainer.bottomAnchor), optionsStack.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor), optionsStack.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20), nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), nextButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    private let buttonSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    func loadQuestion(at index: Int) {
        let q = questions[index]
        questionLabel.text = "\(q.id). \(q.text)"
        optionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (i, opt) in q.options.enumerated() {
            let rv = RadioOptionView()
            rv.optionLabel.text = opt; rv.tag = i; rv.isOn = (i == q.selectedOptionIndex)
            rv.showSeparator(i != q.options.count-1)
            rv.addTarget(self, action: #selector(optSelected(_:)), for: .touchUpInside)
            optionsStack.addArrangedSubview(rv)
        }
        
        let progress = Float(currentQuestionIndex) / Float(questions.count - 1)
        progressBar.setProgress(progress, animated: true)
        
        let isAns = q.selectedOptionIndex != nil
        nextButton.isEnabled = isAns; nextButton.alpha = isAns ? 1.0 : 0.5
        nextButton.setTitle(index == questions.count-1 ? "Submit" : "Next", for: .normal)
    }

    @objc func optSelected(_ sender: RadioOptionView) {
        optionsStack.arrangedSubviews.forEach { ($0 as? RadioOptionView)?.isOn = ($0 == sender) }
        questions[currentQuestionIndex].selectedOptionIndex = sender.tag
        
        // SAVE SESSION (UPDATED FOR PATIENT ID)
        if let pid = patientID {
            let allAnswers = AssessmentSessionManager.shared.getTestAnswers(for: pid)
            var savedMap = (allAnswers["Cognitive Skills"] as? [Int: Int]) ?? [:]
            savedMap[currentQuestionIndex] = sender.tag
            
            AssessmentSessionManager.shared.updateTestAnswer(for: pid, key: "Cognitive Skills", value: savedMap)
        }
        
        nextButton.isEnabled = true; nextButton.alpha = 1.0
    }

    @objc func backTapped() {
        if currentQuestionIndex > 0 { currentQuestionIndex -= 1; loadQuestion(at: currentQuestionIndex) }
        else { navigationController?.popViewController(animated: true) }
    }

    @objc func nextTapped() {
        if currentQuestionIndex < questions.count - 1 { currentQuestionIndex += 1; loadQuestion(at: currentQuestionIndex) }
        else { submit() }
    }
    private func setSubmitting(_ isSubmitting: Bool) {
        if isSubmitting {
            nextButton.isEnabled = false
            nextButton.setTitle("", for: .normal) // Hide text to show spinner clearly
            buttonSpinner.startAnimating()
        } else {
            nextButton.isEnabled = true
            nextButton.setTitle(currentQuestionIndex == questions.count - 1 ? "Submit" : "Next", for: .normal)
            buttonSpinner.stopAnimating()
        }
    }
    
    func submit() {
        guard let pid = patientID else { return }
        
        // Start Loading State
        setSubmitting(true)
        
        var res: [String: AnyCodable] = [:]
        for q in questions {
            if let idx = q.selectedOptionIndex {
                res["Q\(q.id)"] = AnyCodable(value: q.options[idx])
            } else {
                res["Q\(q.id)"] = AnyCodable(value: "Skipped")
            }
        }
        
        let log = AssessmentLog(patient_id: pid, assessment_type: "Cognitive Skills", assessment_data: res)
        
        Task {
            do {
                try await supabase.from("assessments").insert(log).execute()
                await MainActor.run {
                    // Success: Navigate back
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    // Error: Reset button so user can try again
                    setSubmitting(false)
                    let alert = UIAlertController(title: "Submission Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }
}
