import UIKit
import AVKit
import AVFoundation
import MobileCoreServices
import Storage
import Supabase
import QuickLook

class AssignmentDetailViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, QLPreviewControllerDataSource {
    
    // MARK: - Properties
    var currentAssignment: Assignment?
    var assignmentTitle: String?
    private var attachmentToPreview: URL?
    private var recordedVideoURLs: [URL] = []
    private var questionFields: [UITextField] = []
    
    // UI References
    private var recordButton: UIButton?
    private var completeButton: UIButton?
    private let scrollView = UIScrollView()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let resultsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        stack.layer.cornerRadius = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.isHidden = true
        return stack
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // RENAMED: This now fetches everything, not just the grade
        fetchSubmissionStatus()
    }
    
    // MARK: - Data Fetching (THE FIX IS HERE)
    private func fetchSubmissionStatus() {
        guard let id = currentAssignment?.id else { return }
        
        Task {
            do {
                let res: [AssignmentSubmission] = try await supabase
                    .from("assignment_submissions")
                    .select()
                    .eq("assignment_id", value: id)
                    .execute()
                    .value
                
                if let sub = res.first {
                    await MainActor.run {
                        // 1. Fill in the text answers
                        self.populateExistingAnswers(sub)
                        
                        // 2. Update UI for "Submitted" state
                        self.completeButton?.isHidden = true
                        self.completeButton?.isEnabled = false
                        
                        // 3. Update Video Button if video exists
                        if sub.video_url != nil {
                            self.recordButton?.setTitle("Video Submitted ✓", for: .disabled)
                            self.recordButton?.backgroundColor = .systemGray
                            self.recordButton?.isEnabled = false
                        }
                        
                        // 4. Show Grade if available
                        if let score = sub.score {
                            self.showResults(score: score, remarks: sub.remarks ?? "")
                        }
                    }
                }
            } catch {
                print("Error fetching submission: \(error)")
            }
        }
    }
    private func createStyledQuestionField(question: String, index: Int) -> UIView {
            let container = UIStackView()
            container.axis = .vertical
            container.spacing = 8
            
            // Label
            let label = UILabel()
            label.text = "\(index + 1). \(question)"
            label.font = .systemFont(ofSize: 16, weight: .semibold)
            label.textColor = .label // Ensure visible on gradient
            label.numberOfLines = 0
            
            // Input Container (White Box)
            let inputContainer = UIView()
            inputContainer.backgroundColor = .systemBackground
            inputContainer.layer.cornerRadius = 12
            // Shadow for depth
            inputContainer.layer.shadowColor = UIColor.label.cgColor
            inputContainer.layer.shadowOpacity = 0.05
            inputContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
            inputContainer.layer.shadowRadius = 4
            inputContainer.translatesAutoresizingMaskIntoConstraints = false
            inputContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true
            
            // Actual TextField
            let field = UITextField()
            field.placeholder = "Type your answer here..."
            field.font = .systemFont(ofSize: 16)
            field.translatesAutoresizingMaskIntoConstraints = false
            
            inputContainer.addSubview(field)
            
            // Padding Constraints for TextField
            NSLayoutConstraint.activate([
                field.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
                field.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
                field.topAnchor.constraint(equalTo: inputContainer.topAnchor),
                field.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor)
            ])
            
            questionFields.append(field) // Track for submission
            
            container.addArrangedSubview(label)
            container.addArrangedSubview(inputContainer)
            
            return container
        }
    private func populateExistingAnswers(_ sub: AssignmentSubmission) {
        for (index, answer) in sub.answers.enumerated() {
            if index < questionFields.count {
                let field = questionFields[index]
                field.text = answer
                field.isEnabled = false // Disable editing after submission
                field.textColor = .secondaryLabel
                field.backgroundColor = .systemGray6 // Visual cue that it's read-only
            }
        }
    }

    // MARK: - UI Implementation
    private func setupUI() {
        let bg = ParentGradientView()
        bg.frame = view.bounds
        view.addSubview(bg)

        self.title = assignmentTitle
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -50),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        addDetailComponents()
    }

    private func addDetailComponents() {
        guard let assignment = currentAssignment else { return }
        contentStack.addArrangedSubview(resultsStack)

        // Instructions
        if !assignment.instruction.isEmpty {
            let label = UILabel(); label.text = "Therapist Instructions"; label.font = .boldSystemFont(ofSize: 18)
            contentStack.addArrangedSubview(label)
            let text = UILabel(); text.text = assignment.instruction; text.numberOfLines = 0; text.textColor = .secondaryLabel
            contentStack.addArrangedSubview(text)
        }

        // Attachments
        if !assignment.attachmentUrls.isEmpty {
            let label = UILabel(); label.text = "Attachments"; label.font = .boldSystemFont(ofSize: 18)
            contentStack.addArrangedSubview(label)
            
            for (index, urlString) in assignment.attachmentUrls.enumerated() {
                let btn = UIButton(type: .system)
                btn.setTitle(" 📎 View Attachment \(index + 1)", for: .normal)
                btn.contentHorizontalAlignment = .leading
                btn.addAction(UIAction(handler: { [weak self] _ in self?.downloadAndPreview(urlString: urlString) }), for: .touchUpInside)
                contentStack.addArrangedSubview(btn)
            }
        }

        // Questions
        for (index, question) in assignment.quizQuestions.enumerated() {
            let qView = createStyledQuestionField(question: question, index: index)
                    contentStack.addArrangedSubview(qView)
        }

        // Action Buttons
        if assignment.type == "Video Submission" {
            let recBtn = createButton(title: "Record Video", color: .systemOrange)
            recBtn.addTarget(self, action: #selector(recordVideoTapped), for: .touchUpInside)
            self.recordButton = recBtn
            contentStack.addArrangedSubview(recBtn)
        }

        let completeBtn = createButton(title: "Mark as complete", color: .systemBlue)
        completeBtn.addTarget(self, action: #selector(handleComplete(sender:)), for: .touchUpInside)
        self.completeButton = completeBtn
        contentStack.addArrangedSubview(completeBtn)
    }

    // MARK: - Action Handlers
    @objc private func recordVideoTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.movie.identifier as String]
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            recordedVideoURLs = [videoURL]
            recordButton?.backgroundColor = .systemGreen
            recordButton?.setTitle("Video Recorded ✓", for: .normal)
        }
        dismiss(animated: true)
    }

    @objc private func handleComplete(sender: UIButton) {
        guard let assignment = currentAssignment, let pID = assignment.patient_id else { return }
        
        sender.isEnabled = false
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.center = CGPoint(x: sender.bounds.midX, y: sender.bounds.midY)
        sender.addSubview(spinner); spinner.startAnimating()

        let answers = questionFields.map { $0.text ?? "" }

        Task {
            do {
                var videoPath: String?
                if let videoURL = recordedVideoURLs.first {
                    let data = try Data(contentsOf: videoURL)
                    let path = "submissions/\(assignment.id?.uuidString ?? UUID().uuidString).mp4"
                    try await supabase.storage.from("assignment-videos").upload(path: path, file: data, options: FileOptions(contentType: "video/mp4"))
                    videoPath = path
                }

                let submission = AssignmentSubmission(id: UUID(), assignment_id: assignment.id ?? UUID(), patient_id: pID, answers: answers, video_url: videoPath, score: nil, remarks: nil)
                try await supabase.from("assignment_submissions").insert(submission).execute()
                
                await MainActor.run {
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run { sender.isEnabled = true; spinner.stopAnimating() }
            }
        }
    }

    private func showResults(score: Int, remarks: String) {
        resultsStack.isHidden = false
        resultsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let l1 = UILabel(); l1.text = "Score: \(score)/10"; l1.textColor = .systemGreen; resultsStack.addArrangedSubview(l1)
        let l2 = UILabel(); l2.text = "Feedback: \(remarks)"; l2.numberOfLines = 0; resultsStack.addArrangedSubview(l2)
    }

    private func downloadAndPreview(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        
        Task {
            do {
                let (tempUrl, response) = try await URLSession.shared.download(from: url)
                
                // 1. Get the extension from the server's MIME type (e.g., "image/jpeg" -> "jpg")
                let mimeType = response.mimeType ?? ""
                let ext = extensionFor(mimeType: mimeType) ?? url.pathExtension
                
                // 2. Fallback to "pdf" if no extension is found
                let finalExt = ext.isEmpty ? "pdf" : ext
                let fileName = "Attachment_\(UUID().uuidString).\(finalExt)"
                
                let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try? FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: tempUrl, to: destinationURL)
                
                await MainActor.run {
                    self.navigationItem.rightBarButtonItem = nil
                    self.attachmentToPreview = destinationURL
                    let ql = QLPreviewController()
                    ql.dataSource = self
                    self.present(ql, animated: true)
                }
            } catch {
                print("Download error: \(error)")
                await MainActor.run { self.navigationItem.rightBarButtonItem = nil }
            }
        }
    }

    // Helper to map MIME types to extensions
    private func extensionFor(mimeType: String) -> String? {
        let mapping: [String: String] = [
            "image/jpeg": "jpg",
            "image/jpg": "jpg",
            "image/png": "png",
            "application/pdf": "pdf",
            "application/msword": "doc",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
            "video/mp4": "mp4",
            "audio/mpeg": "mp3"
        ]
        return mapping[mimeType.lowercased()]
    }

    func numberOfPreviewItems(in c: QLPreviewController) -> Int { 1 }
    func previewController(_ c: QLPreviewController, previewItemAt i: Int) -> QLPreviewItem { attachmentToPreview! as QLPreviewItem }

    private func createButton(title: String, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal); btn.backgroundColor = color; btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 27.5; btn.heightAnchor.constraint(equalToConstant: 55).isActive = true
        return btn
    }
}
