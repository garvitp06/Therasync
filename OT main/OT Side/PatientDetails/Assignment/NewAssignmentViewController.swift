import UIKit
import PhotosUI
import UniformTypeIdentifiers
import Supabase
import Storage

// MARK: - Assessment Summary Model
// Uses raw JSONSerialization to avoid Codable issues with mixed-type assessment_data
private struct AssessmentSummary {
    let assessment_type: String
    let assessment_data: [String: Any]
    
    /// Parse directly from the raw Supabase JSON response array
    static func decodeArray(from data: Data) -> [AssessmentSummary] {
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("⚠️ AssessmentSummary: Could not parse response as array")
            return []
        }
        return raw.compactMap { dict in
            guard let type = dict["assessment_type"] as? String,
                  let dataField = dict["assessment_data"] as? [String: Any] else { return nil }
            return AssessmentSummary(assessment_type: type, assessment_data: dataField)
        }
    }
}

// MARK: - AI Recommendation State
private enum AIRecommendationState {
    case idle
    case loading
    case loaded(questions: [String])
    case noData        // Patient has no assessments yet
    case failed(String)
}

protocol NewAssignmentDelegate: AnyObject {
    func didCreateAssignment()
}

class NewAssignmentViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    // MARK: - Properties
    var patientID: String?
    var patientName: String?          // Optional: pass patient name for better UX
    weak var delegate: NewAssignmentDelegate?
    private let maxAttachmentLimit = 5
    
    private var questionTextFields: [UITextField] = []
    private var localAttachmentURLs: [URL] = []
    private var aiRecommendationState: AIRecommendationState = .idle
    private var suggestedQuestions: [String] = []
    private var activeField: UIView?
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Assignment Title"
        tf.backgroundColor = .systemBackground
        tf.layer.cornerRadius = 25
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        tf.leftViewMode = .always
        tf.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return tf
    }()
    
    private let instructionTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.backgroundColor = .systemBackground
        tv.layer.cornerRadius = 25
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.text = "Assignment Instruction"
        tv.textColor = .lightGray
        tv.heightAnchor.constraint(equalToConstant: 120).isActive = true
        return tv
    }()
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private let typeTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Select Type"
        tf.textColor = .lightGray
        tf.tintColor = .clear
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let typePicker = UIPickerView()
    private let typeOptions = ["Quiz", "Video Submission"]
    
    // MARK: - AI Suggestions Card
    private let aiSuggestionsCard: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.systemBlue.cgColor
        v.layer.shadowOpacity = 0.12
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 12
        v.isHidden = true
        v.clipsToBounds = false
        return v
    }()
    
    private let aiCardHeader: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        return v
    }()
    
    private let aiCardGradient: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor(red: 0.29, green: 0.46, blue: 1.0, alpha: 1).cgColor,
            UIColor(red: 0.54, green: 0.28, blue: 0.97, alpha: 1).cgColor
        ]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint = CGPoint(x: 1, y: 1)
        return g
    }()
    
    private let aiSparkIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "sparkles"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.widthAnchor.constraint(equalToConstant: 22).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 22).isActive = true
        return iv
    }()
    
    private let aiHeaderTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "AI Suggested Questions"
        l.font = .systemFont(ofSize: 15, weight: .bold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let aiHeaderSubtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "AI suggestions — always verify clinical suitability"
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let aiRefreshButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        b.tintColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        b.widthAnchor.constraint(equalToConstant: 32).isActive = true
        b.heightAnchor.constraint(equalToConstant: 32).isActive = true
        return b
    }()
    
    private let aiBodyView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return v
    }()
    
    private let aiLoadingStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 10
        s.translatesAutoresizingMaskIntoConstraints = false
        s.isHidden = true
        return s
    }()
    
    private let aiLoadingSpinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.color = .systemBlue
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    private let aiLoadingLabel: UILabel = {
        let l = UILabel()
        l.text = "Analysing patient's reports..."
        l.font = .systemFont(ofSize: 14)
        l.textColor = .systemGray
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let aiQuestionsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        s.translatesAutoresizingMaskIntoConstraints = false
        s.isHidden = true
        return s
    }()
    
    private let aiErrorLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .systemRed
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()
    
    // MARK: - Manual Questions Section
    private let questionsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.isHidden = true
        return stack
    }()
    
    private let addQuestionButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Add Question"
        config.image = UIImage(systemName: "plus.circle.fill")
        config.imagePadding = 8
        let btn = UIButton(configuration: config)
        btn.isHidden = true
        return btn
    }()
    
    private let attachmentButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Add Attachments"
        config.image = UIImage(systemName: "paperclip")
        config.imagePadding = 8
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .systemBlue
        config.background.cornerRadius = 25
        let btn = UIButton(configuration: config)
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }()
    
    private let attachmentsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()
    
    private let mainStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 15
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupNavBar()
        setupLayout()
        setupPickers()
        setupInteractions()
        setupKeyboardHandling()
        titleTextField.delegate = self
        typeTextField.delegate = self
        instructionTextView.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Fetch patient assessments on load
        if let pid = patientID {
            fetchPatientAssessments(for: pid)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        aiCardGradient.frame = aiCardHeader.bounds
    }

    private func setupNavBar() {
        self.title = "New Assignment"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(didTapClose))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .done, target: self, action: #selector(didTapSave))
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mainStack)
        
        // Type picker container
        let typeContainer = UIView()
        typeContainer.backgroundColor = .systemBackground
        typeContainer.layer.cornerRadius = 25
        typeContainer.heightAnchor.constraint(equalToConstant: 55).isActive = true
        typeContainer.addSubview(typeTextField)

        let chevronIcon = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronIcon.tintColor = .systemGray2
        chevronIcon.contentMode = .scaleAspectFit
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        chevronIcon.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        rightView.addSubview(chevronIcon)
        typeTextField.rightView = rightView
        typeTextField.rightViewMode = .always
        
        // Build AI Suggestions Card
        setupAISuggestionsCard()
        
        mainStack.addArrangedSubview(titleTextField)
        mainStack.addArrangedSubview(instructionTextView)
        mainStack.addArrangedSubview(typeContainer)
        mainStack.addArrangedSubview(aiSuggestionsCard)    // <-- AI card here
        mainStack.addArrangedSubview(questionsStack)
        mainStack.addArrangedSubview(addQuestionButton)
        mainStack.addArrangedSubview(attachmentButton)
        mainStack.addArrangedSubview(attachmentsStack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            typeTextField.leadingAnchor.constraint(equalTo: typeContainer.leadingAnchor, constant: 16),
            typeTextField.trailingAnchor.constraint(equalTo: typeContainer.trailingAnchor, constant: -8),
            typeTextField.centerYAnchor.constraint(equalTo: typeContainer.centerYAnchor)
        ])
    }
    
    // MARK: - AI Card Setup
    private func setupAISuggestionsCard() {
        aiSuggestionsCard.translatesAutoresizingMaskIntoConstraints = false
        
        // --- Header ---
        aiCardHeader.layer.insertSublayer(aiCardGradient, at: 0)
        
        let headerTextStack = UIStackView(arrangedSubviews: [aiHeaderTitleLabel, aiHeaderSubtitleLabel])
        headerTextStack.axis = .vertical
        headerTextStack.spacing = 2
        headerTextStack.translatesAutoresizingMaskIntoConstraints = false
        
        let headerRow = UIStackView(arrangedSubviews: [aiSparkIcon, headerTextStack, aiRefreshButton])
        headerRow.axis = .horizontal
        headerRow.spacing = 10
        headerRow.alignment = .center
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        
        aiCardHeader.addSubview(headerRow)
        
        // --- Loading ---
        aiLoadingStack.addArrangedSubview(aiLoadingSpinner)
        aiLoadingStack.addArrangedSubview(aiLoadingLabel)
        
        // --- Body ---
        aiBodyView.addSubview(aiLoadingStack)
        aiBodyView.addSubview(aiQuestionsStack)
        aiBodyView.addSubview(aiErrorLabel)
        
        // --- Assemble Card ---
        aiSuggestionsCard.addSubview(aiCardHeader)
        aiSuggestionsCard.addSubview(aiBodyView)
        
        NSLayoutConstraint.activate([
            aiCardHeader.topAnchor.constraint(equalTo: aiSuggestionsCard.topAnchor),
            aiCardHeader.leadingAnchor.constraint(equalTo: aiSuggestionsCard.leadingAnchor),
            aiCardHeader.trailingAnchor.constraint(equalTo: aiSuggestionsCard.trailingAnchor),
            aiCardHeader.heightAnchor.constraint(equalToConstant: 64),
            
            headerRow.leadingAnchor.constraint(equalTo: aiCardHeader.leadingAnchor, constant: 16),
            headerRow.trailingAnchor.constraint(equalTo: aiCardHeader.trailingAnchor, constant: -16),
            headerRow.centerYAnchor.constraint(equalTo: aiCardHeader.centerYAnchor),
            
            aiBodyView.topAnchor.constraint(equalTo: aiCardHeader.bottomAnchor),
            aiBodyView.leadingAnchor.constraint(equalTo: aiSuggestionsCard.leadingAnchor),
            aiBodyView.trailingAnchor.constraint(equalTo: aiSuggestionsCard.trailingAnchor),
            aiBodyView.bottomAnchor.constraint(equalTo: aiSuggestionsCard.bottomAnchor),
            
            aiLoadingStack.centerXAnchor.constraint(equalTo: aiBodyView.centerXAnchor),
            aiLoadingStack.topAnchor.constraint(equalTo: aiBodyView.topAnchor, constant: 20),
            aiLoadingStack.bottomAnchor.constraint(equalTo: aiBodyView.bottomAnchor, constant: -20),
            
            aiQuestionsStack.topAnchor.constraint(equalTo: aiBodyView.topAnchor),
            aiQuestionsStack.leadingAnchor.constraint(equalTo: aiBodyView.leadingAnchor),
            aiQuestionsStack.trailingAnchor.constraint(equalTo: aiBodyView.trailingAnchor),
            aiQuestionsStack.bottomAnchor.constraint(equalTo: aiBodyView.bottomAnchor),
            
            aiErrorLabel.centerXAnchor.constraint(equalTo: aiBodyView.centerXAnchor),
            aiErrorLabel.topAnchor.constraint(equalTo: aiBodyView.topAnchor, constant: 20),
            aiErrorLabel.bottomAnchor.constraint(equalTo: aiBodyView.bottomAnchor, constant: -20),
            aiErrorLabel.leadingAnchor.constraint(equalTo: aiBodyView.leadingAnchor, constant: 16),
            aiErrorLabel.trailingAnchor.constraint(equalTo: aiBodyView.trailingAnchor, constant: -16),
        ])
        
        aiRefreshButton.addTarget(self, action: #selector(didTapRefreshAI), for: .touchUpInside)
    }
    
    // MARK: - AI Card State Rendering
    private func renderAIState(_ state: AIRecommendationState) {
        // Only show card when Quiz is selected
        let isQuiz = typeTextField.text == "Quiz"
        
        switch state {
        case .idle, .noData:
            // No assessments: card stays hidden entirely
            aiSuggestionsCard.isHidden = true
            
        case .loading:
            if isQuiz {
                aiSuggestionsCard.isHidden = false
                aiLoadingStack.isHidden = false
                aiQuestionsStack.isHidden = true
                aiErrorLabel.isHidden = true
                aiLoadingSpinner.startAnimating()
                aiRefreshButton.isEnabled = false
            }
            
        case .loaded(let questions):
            if isQuiz {
                aiSuggestionsCard.isHidden = false
                aiLoadingStack.isHidden = true
                aiErrorLabel.isHidden = true
                aiLoadingSpinner.stopAnimating()
                aiRefreshButton.isEnabled = true
                
                // Clear and rebuild question rows
                aiQuestionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
                aiQuestionsStack.isHidden = false
                
                for (i, q) in questions.enumerated() {
                    let row = buildAISuggestionRow(question: q, isLast: i == questions.count - 1)
                    aiQuestionsStack.addArrangedSubview(row)
                }
            }
            
        case .failed(let msg):
            if isQuiz {
                aiSuggestionsCard.isHidden = false
                aiLoadingStack.isHidden = true
                aiQuestionsStack.isHidden = true
                aiLoadingSpinner.stopAnimating()
                aiRefreshButton.isEnabled = true
                aiErrorLabel.isHidden = false
                aiErrorLabel.text = "⚠️ \(msg)"
            }
        }
        
        // Animate layout update
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func buildAISuggestionRow(question: String, isLast: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        
        let label = UILabel()
        label.text = question
        label.font = .systemFont(ofSize: 14.5, weight: .regular)
        label.textColor = UIColor(white: 0.2, alpha: 1)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let addBtn = UIButton(type: .system)
        addBtn.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addBtn.tintColor = .systemBlue
        addBtn.translatesAutoresizingMaskIntoConstraints = false
        addBtn.widthAnchor.constraint(equalToConstant: 28).isActive = true
        addBtn.heightAnchor.constraint(equalToConstant: 28).isActive = true
        
        // Pass question text via closure
        addBtn.addAction(UIAction { [weak self] _ in
            self?.addSuggestedQuestionToQuiz(question)
            // Visual feedback: dim the row
            UIView.animate(withDuration: 0.2) {
                container.alpha = 0.4
                addBtn.isEnabled = false
            }
        }, for: .touchUpInside)
        
        container.addSubview(label)
        container.addSubview(addBtn)
        
        NSLayoutConstraint.activate([
            addBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            addBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            addBtn.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 14),
            addBtn.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -14),
            
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: addBtn.leadingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
        ])
        
        if !isLast {
            let sep = UIView()
            sep.backgroundColor = UIColor.systemGray5
            sep.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(sep)
            NSLayoutConstraint.activate([
                sep.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                sep.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                sep.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                sep.heightAnchor.constraint(equalToConstant: 0.5)
            ])
        }
        
        return container
    }
    
    private func addSuggestedQuestionToQuiz(_ question: String) {
        // Ensure questions are visible
        questionsStack.isHidden = false
        addQuestionButton.isHidden = false
        
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 10
        container.alignment = .center

        let tf = UITextField()
        tf.text = question
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 20
        tf.heightAnchor.constraint(equalToConstant: 45).isActive = true
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 45))
        tf.leftViewMode = .always
        tf.delegate = self
        
        let deleteBtn = UIButton(type: .system)
        deleteBtn.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        deleteBtn.tintColor = .systemRed
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false
        deleteBtn.widthAnchor.constraint(equalToConstant: 30).isActive = true
        deleteBtn.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        deleteBtn.addAction(UIAction(handler: { [weak self, weak container] _ in
            self?.confirmDeletion(title: "Delete Question", message: "Are you sure you want to remove this question?") {
                guard let container = container else { return }
                if let index = self?.questionTextFields.firstIndex(of: tf) {
                    self?.questionTextFields.remove(at: index)
                }
                container.removeFromSuperview()
            }
        }), for: .touchUpInside)

        container.addArrangedSubview(tf)
        container.addArrangedSubview(deleteBtn)
        
        questionTextFields.append(tf)
        questionsStack.addArrangedSubview(container)
        
        // Scroll to newly added question
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.scrollView.scrollToBottom(animated: true)
        }
    }

    private func setupPickers() {
        typePicker.delegate = self
        typePicker.dataSource = self
        typeTextField.isUserInteractionEnabled = true
        typeTextField.inputView = typePicker
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(pickerDoneTapped))
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = 16
        toolbar.setItems([flexibleSpace, doneButton, fixedSpace], animated: false)
        typeTextField.inputAccessoryView = toolbar
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardSize = keyboardFrame.cgRectValue.size
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets

        if let activeField = activeField {
            let rect = activeField.convert(activeField.bounds, to: scrollView)
            scrollView.scrollRectToVisible(rect, animated: true)
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        activeField = nil
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupInteractions() {
        addQuestionButton.addTarget(self, action: #selector(didTapAddQuestion), for: .touchUpInside)
        attachmentButton.addTarget(self, action: #selector(didTapAttachments), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func didTapClose() { dismiss(animated: true) }

    @objc private func pickerDoneTapped() {
        let row = typePicker.selectedRow(inComponent: 0)
        typeTextField.text = typeOptions[row]
        typeTextField.textColor = .label
        let isQuiz = typeOptions[row] == "Quiz"
        questionsStack.isHidden = !isQuiz
        addQuestionButton.isHidden = !isQuiz
        view.endEditing(true)
        
        // Show/hide AI card based on current state when Quiz is selected
        renderAIState(aiRecommendationState)
    }

    @objc private func didTapAddQuestion() {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 10
        container.alignment = .center

        let tf = UITextField()
        tf.placeholder = "Enter question \(questionTextFields.count + 1)"
        tf.backgroundColor = .systemBackground
        tf.layer.cornerRadius = 20
        tf.heightAnchor.constraint(equalToConstant: 45).isActive = true
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 45))
        tf.leftViewMode = .always
        tf.delegate = self
        
        let deleteBtn = UIButton(type: .system)
        deleteBtn.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        deleteBtn.tintColor = .systemRed
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false
        deleteBtn.widthAnchor.constraint(equalToConstant: 30).isActive = true
        deleteBtn.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        deleteBtn.addAction(UIAction(handler: { [weak self, weak container] _ in
            self?.confirmDeletion(title: "Delete Question", message: "Are you sure you want to remove this question?") {
                guard let container = container else { return }
                if let index = self?.questionTextFields.firstIndex(of: tf) {
                    self?.questionTextFields.remove(at: index)
                }
                container.removeFromSuperview()
            }
        }), for: .touchUpInside)

        container.addArrangedSubview(tf)
        container.addArrangedSubview(deleteBtn)
        
        questionTextFields.append(tf)
        questionsStack.addArrangedSubview(container)
    }

    @objc private func didTapRefreshAI() {
        guard let pid = patientID else { return }
        fetchPatientAssessments(for: pid)
    }

    @objc private func didTapAttachments() {
        let alert = UIAlertController(title: "Add Attachment", message: "You can select multiple files.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Photos or Videos", style: .default, handler: { _ in self.showPhotoPicker() }))
        alert.addAction(UIAlertAction(title: "Documents (PDF)", style: .default, handler: { _ in self.showDocumentPicker() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        config.filter = .any(of: [.images, .videos])
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == typeTextField { return false }
        return true
    }
    
    private func showDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .image])
        picker.delegate = self
        picker.allowsMultipleSelection = true
        present(picker, animated: true)
    }
    
    private func confirmDeletion(title: String, message: String, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in completion() }))
        present(alert, animated: true)
    }

    @objc private func didTapSave() {
        let questions = questionTextFields.compactMap { $0.text }.filter { !$0.isEmpty }
        guard let title = titleTextField.text, !title.isEmpty, let pID = patientID, let type = typeTextField.text, !type.isEmpty else {
            let alert = UIAlertController(title: "Required", message: "Please fill in all required fields (Title, Type).", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        view.isUserInteractionEnabled = false

        Task {
            do {
                let remoteUrls = try await uploadAttachments()
                let assignment = Assignment(
                    title: title,
                    instruction: instructionTextView.text == "Assignment Instruction" ? "" : instructionTextView.text,
                    dueDate: datePicker.date,
                    type: type,
                    quizQuestions: questions,
                    attachmentUrls: remoteUrls,
                    patient_id: pID
                )
                
                try await supabase.from("assignments").insert(assignment).execute()
                
                await MainActor.run {
                    self.delegate?.didCreateAssignment()
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .done, target: self, action: #selector(self.didTapSave))
                    self.view.isUserInteractionEnabled = true
                    let alert = UIAlertController(title: "Upload Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Safe Filename Helper
    private func sanitizeFileName(_ fileName: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_"))
        return fileName.components(separatedBy: allowedCharacters.inverted).joined(separator: "_")
    }

    private func uploadAttachments() async throws -> [String] {
        var urls: [String] = []
        for localUrl in localAttachmentURLs {
            let fileName = localUrl.lastPathComponent
            let data = try Data(contentsOf: localUrl)
            try await supabase.storage.from("assignment-attachments").upload(path: fileName, file: data, options: FileOptions(contentType: "application/octet-stream"))
            let publicUrl = try supabase.storage.from("assignment-attachments").getPublicURL(path: fileName)
            urls.append(publicUrl.absoluteString)
        }
        return urls
    }

    private func addAttachmentRow(name: String, iconName: String, url: URL) {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 10
        container.alignment = .center
        
        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 15
        card.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = .systemGreen
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = name
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle
        label.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(icon)
        card.addSubview(label)
        
        let deleteBtn = UIButton(type: .system)
        deleteBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteBtn.tintColor = .systemGray2
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false
        deleteBtn.setContentHuggingPriority(.required, for: .horizontal)
        deleteBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            deleteBtn.widthAnchor.constraint(equalToConstant: 30),
            deleteBtn.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        container.addArrangedSubview(card)
        container.addArrangedSubview(deleteBtn)
        attachmentsStack.addArrangedSubview(container)
        localAttachmentURLs.append(url)
        
        deleteBtn.addAction(UIAction(handler: { [weak self, weak container] _ in
            self?.confirmDeletion(title: "Remove Attachment", message: "Remove '\(name)'?") {
                if let index = self?.localAttachmentURLs.firstIndex(where: { $0.absoluteString == url.absoluteString }) {
                    self?.localAttachmentURLs.remove(at: index)
                }
                UIView.animate(withDuration: 0.2, animations: {
                    container?.alpha = 0
                    container?.isHidden = true
                }) { _ in container?.removeFromSuperview() }
            }
        }), for: .touchUpInside)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        activeField = textView
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        activeField = nil
        if textView.text.isEmpty {
            textView.text = "Assignment Instruction"
            textView.textColor = .lightGray
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
    }
}

// MARK: - AI Integration
extension NewAssignmentViewController {
    
    /// Step 1: Fetch all assessment records for this patient from Supabase
    private func fetchPatientAssessments(for patientID: String) {
        aiRecommendationState = .loading
        renderAIState(.loading)
        
        Task {
            do {
                let response = try await supabase
                    .from("assessments")
                    .select("assessment_type, assessment_data, created_at")
                    .eq("patient_id", value: patientID)
                    .order("created_at", ascending: false)
                    .execute()
                
                // Use our custom JSONSerialization-based parser
                // to safely handle mixed-type assessment_data values
                let assessments = AssessmentSummary.decodeArray(from: response.data)
                print("✅ Fetched \(assessments.count) assessment(s) for patient \(patientID)")
                
                if assessments.isEmpty {
                    await MainActor.run {
                        self.aiRecommendationState = .noData
                        self.renderAIState(.noData)
                    }
                } else {
                    let summaryText = buildAssessmentSummary(from: assessments)
                    print("📋 Summary built (\(summaryText.count) chars)")
                    await generateAIQuestions(from: summaryText)
                }
            } catch {
                print("❌ Supabase fetch error: \(error)")
                await MainActor.run {
                    self.aiRecommendationState = .failed("Could not load assessment data.")
                    self.renderAIState(self.aiRecommendationState)
                }
            }
        }
    }
    
    /// Converts raw assessment records into a compact text block for the AI prompt
    private func buildAssessmentSummary(from assessments: [AssessmentSummary]) -> String {
        var lines: [String] = ["Patient Assessment Summary:"]
        var seen = Set<String>()
        
        for a in assessments {
            if seen.contains(a.assessment_type) { continue }
            seen.insert(a.assessment_type)
            lines.append("\n[\(a.assessment_type)]")
            
            for (key, value) in a.assessment_data {
                // Safely convert any value type to String
                let v: String
                if let s = value as? String { v = s }
                else if let n = value as? NSNumber { v = n.stringValue }
                else { v = "\(value)" }
                
                guard !v.isEmpty, v != "<null>" else { continue }
                let truncated = v.count > 100 ? String(v.prefix(100)) + "…" : v
                lines.append("  \(key): \(truncated)")
            }
        }
        return lines.joined(separator: "\n")
    }
    
    /// Step 2: Call the Gemini API and parse out recommended questions
    private func generateAIQuestions(from summary: String) async {
        // ── Guard: API key must be present ───────────────────────────
        let apiKey = APIConfig.geminiAPIKey
        guard !apiKey.isEmpty else {
            print("❌ API key is empty — add GEMINI_API_KEY to Info.plist")
            await MainActor.run {
                self.aiRecommendationState = .failed("API key not configured.\nAdd your key to Info.plist.")
                self.renderAIState(self.aiRecommendationState)
            }
            return
        }
        
        let systemPrompt = """
        You are an expert Occupational Therapist (OT) assistant. You will receive a summary of a patient's assessment data. Your job is to suggest 6 concise, clinically relevant quiz questions that an OT can assign to this patient to track their progress. Questions must be specific to the patient's documented difficulties and strengths. Return ONLY a valid JSON array of 6 strings.
        """
        
        let userMessage = """
        Based on the following patient assessment data, suggest 6 targeted quiz questions for an occupational therapy assignment:

        \(summary)
        """
        
        // Build the Gemini API Request Body
        let body: [String: Any] = [
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": [
                ["parts": [["text": userMessage]]]
            ],
            "generationConfig": [
                "responseMimeType": "application/json"
            ]
        ]
        
        do {
            // Using the current free gemini model via Supabase Edge Function
            let proxyURL = "\(supabaseURL)/functions/v1/gemini-proxy"
            guard let url = URL(string: proxyURL) else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // Supabase anon key for Edge Function auth
            request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            print("📡 Calling Gemini API...")
            let (data, httpResponse) = try await URLSession.shared.data(for: request)
            
            // ── Check HTTP status ─────────────────────────────────────
            if let http = httpResponse as? HTTPURLResponse {
                print("📡 Gemini API status: \(http.statusCode)")
                if http.statusCode != 200 {
                    let errBody = String(data: data, encoding: .utf8) ?? "no body"
                    print("❌ Gemini API error body: \(errBody)")
                    let msg = "API error (\(http.statusCode)).\nTap ↺ to retry."
                    
                    await MainActor.run {
                        self.aiRecommendationState = .failed(msg)
                        self.renderAIState(self.aiRecommendationState)
                    }
                    return
                }
            }
            
            // ── Parse Gemini response ────────────────────────────────────────
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let rawText = firstPart["text"] as? String else {
                print("❌ Could not parse Gemini response JSON")
                throw NSError(domain: "AIError", code: -1)
            }
            
            print("📝 Gemini raw response: \(rawText)")
            
            guard let jsonData = rawText.data(using: String.Encoding.utf8),
                  let questions = try? JSONDecoder().decode([String].self, from: jsonData),
                  !questions.isEmpty else {
                print("❌ Could not parse questions array from response")
                throw NSError(domain: "AIError", code: -2)
            }
            
            print("✅ Got \(questions.count) AI questions")
            await MainActor.run {
                self.aiRecommendationState = .loaded(questions: questions)
                self.renderAIState(self.aiRecommendationState)
            }
            
        } catch {
            print("❌ generateAIQuestions error: \(error)")
            await MainActor.run {
                self.aiRecommendationState = .failed("Failed to generate suggestions.\nTap ↺ to retry.")
                self.renderAIState(self.aiRecommendationState)
            }
        }
    }
}

// MARK: - Delegates
extension NewAssignmentViewController: UIPickerViewDelegate, UIPickerViewDataSource, PHPickerViewControllerDelegate, UIDocumentPickerDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { typeOptions.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { typeOptions[row] }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let remainingSlots = maxAttachmentLimit - localAttachmentURLs.count
        if results.count > remainingSlots { showLimitAlert(); return }

        for result in results {
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.item.identifier) { [weak self] (url, error) in
                guard let self = self, let localUrl = url else { return }
                let safeOriginalName = self.sanitizeFileName(localUrl.lastPathComponent)
                let uniqueFileName = UUID().uuidString + "_" + safeOriginalName
                let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueFileName)
                do {
                    if FileManager.default.fileExists(atPath: tempUrl.path) { try FileManager.default.removeItem(at: tempUrl) }
                    try FileManager.default.copyItem(at: localUrl, to: tempUrl)
                    DispatchQueue.main.async { self.addAttachmentRow(name: localUrl.lastPathComponent, iconName: "photo.fill", url: tempUrl) }
                } catch { print("Error copying file: \(error)") }
            }
        }
    }
    
    private func showLimitAlert() {
        let alert = UIAlertController(title: "Limit Exceeded", message: "You can only add up to \(maxAttachmentLimit) attachments per assignment.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let remainingSlots = maxAttachmentLimit - localAttachmentURLs.count
        if urls.count > remainingSlots { showLimitAlert(); return }
        for url in urls {
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
            let safeOriginalName = self.sanitizeFileName(url.lastPathComponent)
            let uniqueFileName = UUID().uuidString + "_" + safeOriginalName
            let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueFileName)
            do {
                if FileManager.default.fileExists(atPath: tempUrl.path) { try FileManager.default.removeItem(at: tempUrl) }
                try FileManager.default.copyItem(at: url, to: tempUrl)
                addAttachmentRow(name: url.lastPathComponent, iconName: "doc.fill", url: tempUrl)
            } catch { print("Error copying document: \(error)") }
        }
    }
}

// MARK: - UIScrollView Helper
private extension UIScrollView {
    func scrollToBottom(animated: Bool) {
        let bottom = CGPoint(x: 0, y: max(0, contentSize.height - bounds.height + contentInset.bottom))
        setContentOffset(bottom, animated: animated)
    }
}

// MARK: - API Config
// ⚠️ IMPORTANT: Never hard-code your API key in production.
// Move this to a .xcconfig / secrets file, or better yet, proxy through your backend.
enum APIConfig {
    static let geminiAPIKey: String = {
        // Read from Info.plist: add GEMINI_API_KEY to your .xcconfig and Info.plist
        Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? ""
    }()
}
