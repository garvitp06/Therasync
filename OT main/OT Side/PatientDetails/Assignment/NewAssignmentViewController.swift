import UIKit
import PhotosUI
import UniformTypeIdentifiers
import Supabase
import Storage

protocol NewAssignmentDelegate: AnyObject {
    func didCreateAssignment()
}

class NewAssignmentViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    // MARK: - Properties
    var patientID: String?
    weak var delegate: NewAssignmentDelegate?
    private let maxAttachmentLimit = 5
    
    private var questionTextFields: [UITextField] = []
    private var localAttachmentURLs: [URL] = []
    
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
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 25
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        tf.leftViewMode = .always
        tf.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return tf
    }()
    
    private let instructionTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.backgroundColor = .white
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
        typeTextField.delegate = self
        instructionTextView.delegate = self
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
        
        let typeContainer = UIView()
        typeContainer.backgroundColor = .white
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
        
        mainStack.addArrangedSubview(titleTextField)
        mainStack.addArrangedSubview(instructionTextView)
        mainStack.addArrangedSubview(typeContainer)
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
    
    private func setupInteractions() {
        addQuestionButton.addTarget(self, action: #selector(didTapAddQuestion), for: .touchUpInside)
        attachmentButton.addTarget(self, action: #selector(didTapAttachments), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func didTapClose() { dismiss(animated: true) }

    @objc private func pickerDoneTapped() {
        let row = typePicker.selectedRow(inComponent: 0)
        typeTextField.text = typeOptions[row]
        typeTextField.textColor = .black
        let isQuiz = typeOptions[row] == "Quiz"
        questionsStack.isHidden = !isQuiz
        addQuestionButton.isHidden = !isQuiz
        view.endEditing(true)
    }

    @objc private func didTapAddQuestion() {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 10
        container.alignment = .center

        let tf = UITextField()
        tf.placeholder = "Enter question \(questionTextFields.count + 1)"
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 20
        tf.heightAnchor.constraint(equalToConstant: 45).isActive = true
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 45))
        tf.leftViewMode = .always
        
        let deleteBtn = UIButton(type: .system)
        deleteBtn.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        deleteBtn.tintColor = .systemRed
        
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

    @objc private func didTapAttachments() {
        let alert = UIAlertController(title: "Add Attachment", message: "You can select multiple files.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Photos or Videos", style: .default, handler: { _ in self.showPhotoPicker() }))
        alert.addAction(UIAlertAction(title: "Documents (PDF)", style: .default, handler: { _ in self.showDocumentPicker() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0 // 0 means multiple selection
        config.filter = .any(of: [.images, .videos])
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == typeTextField {
            return false // This disables the keyboard typing
        }
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
                    // Reset UI
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .done, target: self, action: #selector(self.didTapSave))
                    self.view.isUserInteractionEnabled = true
                    
                    // Show exact error reason
                    print("❌ Save Error: \(error)")
                    let alert = UIAlertController(title: "Upload Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Safe Filename Helper
    /// Removes ALL characters that aren't letters, numbers, dashes, underscores, or periods.
    private func sanitizeFileName(_ fileName: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_"))
        return fileName.components(separatedBy: allowedCharacters.inverted).joined(separator: "_")
    }

    private func uploadAttachments() async throws -> [String] {
        var urls: [String] = []
        for localUrl in localAttachmentURLs {
            // Because we already sanitized the filename when copying it to the temp directory,
            // localUrl.lastPathComponent is guaranteed to be Supabase-safe.
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
        card.backgroundColor = .white
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
                }) { _ in
                    container?.removeFromSuperview()
                }
            }
        }), for: .touchUpInside)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .black
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
        if results.count > remainingSlots {
            showLimitAlert()
            return
        }

        for result in results {
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.item.identifier) { [weak self] (url, error) in
                guard let self = self, let localUrl = url else { return }
                
                // Scrub the original file name of any weird characters/spaces BEFORE saving
                let safeOriginalName = self.sanitizeFileName(localUrl.lastPathComponent)
                let uniqueFileName = UUID().uuidString + "_" + safeOriginalName
                let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueFileName)
                
                do {
                    if FileManager.default.fileExists(atPath: tempUrl.path) {
                        try FileManager.default.removeItem(at: tempUrl)
                    }
                    try FileManager.default.copyItem(at: localUrl, to: tempUrl)
                    DispatchQueue.main.async {
                        self.addAttachmentRow(name: localUrl.lastPathComponent, iconName: "photo.fill", url: tempUrl)
                    }
                } catch {
                    print("Error copying file to temporary directory: \(error)")
                }
            }
        }
    }
    
    private func showLimitAlert() {
        let alert = UIAlertController(
            title: "Limit Exceeded",
            message: "You can only add up to \(maxAttachmentLimit) attachments per assignment.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let remainingSlots = maxAttachmentLimit - localAttachmentURLs.count
        if urls.count > remainingSlots {
            showLimitAlert()
            return
        }

        for url in urls {
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // Scrub the original file name of any weird characters/spaces BEFORE saving
            let safeOriginalName = self.sanitizeFileName(url.lastPathComponent)
            let uniqueFileName = UUID().uuidString + "_" + safeOriginalName
            let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueFileName)
            
            do {
                if FileManager.default.fileExists(atPath: tempUrl.path) {
                    try FileManager.default.removeItem(at: tempUrl)
                }
                try FileManager.default.copyItem(at: url, to: tempUrl)
                addAttachmentRow(name: url.lastPathComponent, iconName: "doc.fill", url: tempUrl)
            } catch {
                print("Error copying document to temporary directory: \(error)")
            }
        }
    }
}
