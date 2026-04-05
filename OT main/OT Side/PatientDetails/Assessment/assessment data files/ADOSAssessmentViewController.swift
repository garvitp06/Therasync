//
//  ADOSAssessmentViewController.swift
//  AssesmentThera
//
//  Created by user@54 on 21/11/25.
//
import UIKit
import Supabase

final class ADOSAssessmentViewController: UIViewController {

    var patientID: String?
    private var currentIndex = 0
    private var selectedAnswers: [Int: Int] = [:]
    
    // MARK: - UI Elements
    private let backgroundGradient: GradientView = { let v = GradientView(); v.translatesAutoresizingMaskIntoConstraints = false; return v }()
    
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        pv.progressTintColor = .white
        return pv
    }()
    
    private let questionContainer: UIView = { let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; v.backgroundColor = .systemBackground; v.layer.cornerRadius = 18; return v }()
    private let questionLabel: UILabel = { let l = UILabel(); l.translatesAutoresizingMaskIntoConstraints = false; l.numberOfLines = 0; l.font = .systemFont(ofSize: 18); l.textColor = .label; return l }()
    private let cardContainerView: UIView = { let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; v.backgroundColor = .systemBackground; v.layer.cornerRadius = 18; return v }()
    private let optionsTableView: UITableView = { let tv = UITableView(frame: .zero, style: .plain); tv.translatesAutoresizingMaskIntoConstraints = false; tv.backgroundColor = .clear; tv.separatorStyle = .none; return tv }()
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
        
        // LOAD SESSION
        if let pid = patientID {
            // FIX: Use the new helper method to get answers safely
            let allAnswers = AssessmentSessionManager.shared.getTestAnswers(for: pid)
            if let saved = allAnswers["ADOS"] as? [Int: Int] {
                self.selectedAnswers = saved
            }
        }
        
        setupUI()
        setupNavBar()
        
        optionsTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        loadQuestion(animated: false)
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
    
    func setupNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        self.title = "ADOS"
        let back = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
        back.tintColor = .black
        navigationItem.leftBarButtonItem = back
    }

    private func loadQuestion(animated: Bool) {
        guard ADOSData.questions.indices.contains(currentIndex) else { return }
        let q = ADOSData.questions[currentIndex]
        questionLabel.text = "\(q.id). \(q.question)"
        optionsTableView.reloadData()
        
        let total = max(Float(ADOSData.questions.count - 1), 1.0)
        progressView.setProgress(Float(currentIndex) / total, animated: animated)
        
        let isAnswered = selectedAnswers[currentIndex] != nil
        nextButton.isEnabled = isAnswered
        nextButton.alpha = isAnswered ? 1.0 : 0.5
        nextButton.setTitle(currentIndex == ADOSData.questions.count - 1 ? "Submit" : "Next", for: .normal)
    }
    
    private let buttonSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    @objc private func backButtonTapped() {
        if currentIndex > 0 {
            currentIndex -= 1
            loadQuestion(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func nextTapped() {
        if currentIndex < ADOSData.questions.count - 1 {
            currentIndex += 1
            loadQuestion(animated: true)
        } else {
            submitData()
        }
    }
    
    private func setSubmitting(_ isSubmitting: Bool) {
        if isSubmitting {
            nextButton.isEnabled = false
            nextButton.setTitle("", for: .normal) // Hide text to show spinner
            buttonSpinner.startAnimating()
        } else {
            nextButton.isEnabled = true
            let title = currentIndex == ADOSData.questions.count - 1 ? "Submit" : "Next"
            nextButton.setTitle(title, for: .normal)
            buttonSpinner.stopAnimating()
        }
    }
    
    // MARK: - Updated Submission Logic
    private func submitData() {
        guard let validID = patientID else { return }
        
        // Start Loading
        setSubmitting(true)
        
        var results: [String: AnyCodable] = [:]
        for (idx, ans) in selectedAnswers {
            if idx < ADOSData.questions.count {
                results["Q\(ADOSData.questions[idx].id)"] = AnyCodable(value: ADOSData.questions[idx].options[ans])
            }
        }
        
        let log = AssessmentLog(patient_id: validID, assessment_type: "ADOS", assessment_data: results)
        
        Task {
            do {
                try await supabase.from("assessments").insert(log).execute()
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("AssessmentDidComplete"), object: nil, userInfo: ["assessmentName": "ADOS"])
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                print(error)
                await MainActor.run {
                    // Stop Loading on Error
                    setSubmitting(false)
                    let alert = UIAlertController(title: "Save Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }
}

extension ADOSAssessmentViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { ADOSData.questions[currentIndex].options.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RadioOptionCell.identifier, for: indexPath) as! RadioOptionCell
        cell.optionLabel.text = ADOSData.questions[currentIndex].options[indexPath.row]
        let isSel = selectedAnswers[currentIndex] == indexPath.row
        cell.setSelectedState(isSel, animated: false)
        cell.showSeparator(indexPath.row != ADOSData.questions[currentIndex].options.count - 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedAnswers[currentIndex] = indexPath.row
        
        // SAVE SESSION
        if let pid = patientID {
            // FIX: Use the new helper method to save answers safely
            AssessmentSessionManager.shared.updateTestAnswer(for: pid, key: "ADOS", value: selectedAnswers)
        }
        
        tableView.reloadData()
        nextButton.isEnabled = true
        nextButton.alpha = 1.0
    }
}
