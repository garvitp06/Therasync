import UIKit
import Supabase

class FineMotorSkillsViewController: UIViewController {

    var patientID: String?
    
    var questions: [Question] = [
        Question(id: 1, text: "Which object helps practice finger control?", options: ["Pencil", "Football", "Blanket", "Plate"], selectedOptionIndex: nil),
        Question(id: 2, text: "Which action needs good hand-eye coordination?", options: ["Buttoning shirt", "Running", "Listening", "Jumping"], selectedOptionIndex: nil),
        Question(id: 3, text: "What do you use to pick up beads?", options: ["Fingers", "Feet", "Elbow", "Knee"], selectedOptionIndex: nil),
        Question(id: 4, text: "Can you stack 5 blocks?", options: ["Easily", "With help", "Only 2-3", "No"], selectedOptionIndex: nil),
        Question(id: 5, text: "Can you draw a circle?", options: ["Yes", "Sort of", "No", "Scribble"], selectedOptionIndex: nil),
        Question(id: 6, text: "Can you use scissors to cut paper?", options: ["Yes, on line", "Yes, randomly", "With help", "No"], selectedOptionIndex: nil),
        Question(id: 7, text: "Can you zip up a jacket?", options: ["Yes", "With help", "No", "Never tried"], selectedOptionIndex: nil),
        Question(id: 8, text: "Can you open a water bottle cap?", options: ["Yes", "Too tight", "No", "Sometimes"], selectedOptionIndex: nil),
        Question(id: 9, text: "Do you struggle with handwriting?", options: ["Yes, messy", "No, neat", "Too slow", "Cannot write"], selectedOptionIndex: nil),
        Question(id: 10, text: "Can you tie shoelaces?", options: ["Yes", "Learning", "No", "Velcro only"], selectedOptionIndex: nil)
    ]
    var currentQuestionIndex = 0

    // MARK: - UI Elements
    private let backgroundGradient: GradientView = { let v = GradientView(); v.translatesAutoresizingMaskIntoConstraints = false; return v }()
    
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        pv.progressTintColor = .white
        return pv
    }()
    
    private let questionContainer: UIView = { let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; v.backgroundColor = .white; v.layer.cornerRadius = 18; return v }()
    private let questionLabel: UILabel = { let l = UILabel(); l.translatesAutoresizingMaskIntoConstraints = false; l.numberOfLines = 0; l.font = .systemFont(ofSize: 18, weight: .medium); l.textColor = .black; return l }()
    
    private let cardContainerView: UIView = { let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; v.backgroundColor = .white; v.layer.cornerRadius = 18; return v }()
    
    private let optionsTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.isScrollEnabled = false
        return tv
    }()
    
    private let nextButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Next", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .systemBlue
        b.layer.cornerRadius = 28
        b.isEnabled = false
        b.alpha = 0.5
        return b
    }()

    private var tableHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // RESTORE SESSION
        if let pid = patientID {
            let allAnswers = AssessmentSessionManager.shared.getTestAnswers(for: pid)
            if let saved = allAnswers["Fine Motor Skills"] as? [Int: Int] {
                for (idx, optIdx) in saved {
                    if idx < questions.count { questions[idx].selectedOptionIndex = optIdx }
                }
            }
        }
        
        setupNavBar()
        setupUI()
        
        optionsTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        loadQuestion(at: currentQuestionIndex)
    }
    
    deinit {
        optionsTableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            tableHeightConstraint?.constant = optionsTableView.contentSize.height
            view.layoutIfNeeded()
        }
    }
    
    override func loadView() {
        self.view = UIView()
    }
    
    private func setupNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        self.title = "Fine Motor Skills"
        let back = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
        back.tintColor = .black
        navigationItem.leftBarButtonItem = back
    }
    
    private func setupUI() {
        view.addSubview(backgroundGradient)
        view.addSubview(progressView)
        view.addSubview(questionContainer)
        questionContainer.addSubview(questionLabel)
        view.addSubview(cardContainerView)
        cardContainerView.addSubview(optionsTableView)
        view.addSubview(nextButton)
        nextButton.addSubview(buttonSpinner)
        
        optionsTableView.dataSource = self
        optionsTableView.delegate = self
        optionsTableView.register(RadioOptionCell.self, forCellReuseIdentifier: RadioOptionCell.identifier)
        
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        let safe = view.safeAreaLayoutGuide
        
        tableHeightConstraint = optionsTableView.heightAnchor.constraint(equalToConstant: 100)
        tableHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            backgroundGradient.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundGradient.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundGradient.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundGradient.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            buttonSpinner.centerXAnchor.constraint(equalTo: nextButton.centerXAnchor),
            buttonSpinner.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor), 
            
            progressView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            questionContainer.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            questionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            questionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            questionContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
            
            questionLabel.topAnchor.constraint(equalTo: questionContainer.topAnchor, constant: 16),
            questionLabel.bottomAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: -16),
            questionLabel.leadingAnchor.constraint(equalTo: questionContainer.leadingAnchor, constant: 16),
            questionLabel.trailingAnchor.constraint(equalTo: questionContainer.trailingAnchor, constant: -16),
            
            cardContainerView.topAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: 20),
            cardContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            // REMOVED height constraints, let it hug content
            
            optionsTableView.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 8),
            optionsTableView.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor, constant: -8),
            optionsTableView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            optionsTableView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nextButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private let buttonSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    private func loadQuestion(at index: Int) {
        guard index < questions.count else { return }
        let q = questions[index]
        questionLabel.text = "\(q.id). \(q.text)"
        optionsTableView.reloadData()
        
        let total = max(Float(questions.count - 1), 1.0)
        progressView.setProgress(Float(index) / total, animated: true)
        
        let isAnswered = q.selectedOptionIndex != nil
        nextButton.isEnabled = isAnswered
        nextButton.alpha = isAnswered ? 1.0 : 0.5
        nextButton.setTitle(index == questions.count - 1 ? "Submit" : "Next", for: .normal)
    }

    @objc private func backTapped() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            loadQuestion(at: currentQuestionIndex)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func nextTapped() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            loadQuestion(at: currentQuestionIndex)
        } else {
            submit()
        }
    }
    
    private func setSubmitting(_ isSubmitting: Bool) {
        if isSubmitting {
            nextButton.isEnabled = false
            nextButton.setTitle("", for: .normal) // Hide text to show spinner
            buttonSpinner.startAnimating()
        } else {
            nextButton.isEnabled = true
            nextButton.setTitle(currentQuestionIndex == questions.count - 1 ? "Submit" : "Next", for: .normal)
            buttonSpinner.stopAnimating()
        }
    }
    
    func submit() {
        guard let pid = patientID else { return }
        
        // 1. Start Loading State
        setSubmitting(true)
        
        var res: [String: AnyCodable] = [:]
        for q in questions {
            if let idx = q.selectedOptionIndex {
                res["Q\(q.id)"] = AnyCodable(value: q.options[idx])
            }
        }
        
        let log = AssessmentLog(patient_id: pid, assessment_type: "Fine Motor Skills", assessment_data: res)
        
        Task {
            do {
                try await supabase.from("assessments").insert(log).execute()
                await MainActor.run {
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    // 2. Stop Loading on Error
                    setSubmitting(false)
                    let alert = UIAlertController(title: "Error", message: "Failed to save assessment: \(error.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }
}

extension FineMotorSkillsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions[currentQuestionIndex].options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RadioOptionCell.identifier, for: indexPath) as! RadioOptionCell
        
        let question = questions[currentQuestionIndex]
        cell.optionLabel.text = question.options[indexPath.row]
        
        let isSel = question.selectedOptionIndex == indexPath.row
        cell.setSelectedState(isSel, animated: false)
        cell.showSeparator(indexPath.row != question.options.count - 1)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        questions[currentQuestionIndex].selectedOptionIndex = indexPath.row
        
        // SAVE SESSION
        if let pid = patientID {
            let allAnswers = AssessmentSessionManager.shared.getTestAnswers(for: pid)
            var savedMap = (allAnswers["Fine Motor Skills"] as? [Int: Int]) ?? [:]
            savedMap[currentQuestionIndex] = indexPath.row
            AssessmentSessionManager.shared.updateTestAnswer(for: pid, key: "Fine Motor Skills", value: savedMap)
        }
        
        tableView.reloadData()
        nextButton.isEnabled = true
        nextButton.alpha = 1.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
