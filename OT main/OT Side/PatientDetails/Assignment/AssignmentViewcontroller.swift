import UIKit
import AVFoundation
import AVKit
import Supabase
import QuickLook

class AssignmentViewController: UIViewController, QLPreviewControllerDataSource {
    
    var assignment: Assignment?
    private var questionTextFields: [UITextField] = []
    private var submission: AssignmentSubmission?
    private var attachmentToPreview: URL?
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 40, right: 16)
        return stackView
    }()
    
    // --- NEW: Score Display Section ---
    private let scoreResultContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.9, green: 0.98, blue: 0.9, alpha: 1.0) // Light Green
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGreen.cgColor
        view.isHidden = true // Hidden by default
        return view
    }()
    
    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textColor = .systemGreen
        l.textAlignment = .center
        return l
    }()
    
    private let remarksLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .darkGray
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()
    // ----------------------------------
    
    private lazy var videoPlayerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let playIcon = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 40)))
        playIcon.tintColor = .white
        playIcon.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(playIcon)
        NSLayoutConstraint.activate([
            playIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 9.0/16.0)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(playPatientVideo))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    private lazy var downloadButton: UIButton = {
        return createButton(title: "Download Video", isFilled: false)
    }()
    
    private lazy var assignScoreButton: UIButton = {
        let btn = createButton(title: "Assign Score & Feedback", isFilled: true, backgroundColor: .systemBlue)
        btn.addTarget(self, action: #selector(didTapAssignScore), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle

    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchSubmissionData()
        
        // 1. Create the appearance object
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // 2. Set the Title to White
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        // 3. Set the Default Back Button (and all icons) to White
        navigationController?.navigationBar.tintColor = .white
        
        // 4. Apply to all possible states to prevent the "flicker" on swipe-down
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        self.tabBarController?.tabBar.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    // MARK: - Setup UI

    private func setupNavigationBar() {
        title = assignment?.title ?? "Assignment"
        
        // 1. Force white title for your blue background
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(mainStackView)
        
        let isVideoType = (assignment?.type == "Video Submission")
        
        if isVideoType {
            mainStackView.addArrangedSubview(videoPlayerView)
            mainStackView.addArrangedSubview(downloadButton)
            mainStackView.setCustomSpacing(32, after: downloadButton)
        }
        
        // Attachments Section
        if let urls = assignment?.attachmentUrls, !urls.isEmpty {
            let attachHeader = UILabel()
            attachHeader.text = "Attachments"
            attachHeader.font = .systemFont(ofSize: 18, weight: .bold)
            mainStackView.addArrangedSubview(attachHeader)
            
            for (index, urlString) in urls.enumerated() {
                var config = UIButton.Configuration.filled()
                config.baseBackgroundColor = .white
                config.baseForegroundColor = .systemBlue
                config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
                config.cornerStyle = .medium
                
                let btn = UIButton(configuration: config)
                btn.setTitle(" 📎 View Attachment \(index + 1)", for: .normal)
                btn.contentHorizontalAlignment = .leading
                
                btn.addAction(UIAction(handler: { [weak self, weak btn] _ in
                        guard let targetButton = btn else { return }
                        self?.downloadAndPreview(urlString: urlString, onButton: targetButton)
                    }), for: .touchUpInside)
                
                mainStackView.addArrangedSubview(btn)
            }
            mainStackView.setCustomSpacing(20, after: mainStackView.arrangedSubviews.last ?? UIView())
        }
        
        // Questions Section
        if let questions = assignment?.quizQuestions, !questions.isEmpty {
            for (index, questionText) in questions.enumerated() {
                let questionView = createQuestionView(title: "\(index + 1). \(questionText)", placeholder: "Patient's Answer")
                mainStackView.addArrangedSubview(questionView)
            }
        } else if !isVideoType {
            let label = UILabel()
            label.text = "No questions found for this assignment."
            label.textAlignment = .center
            label.textColor = .gray
            mainStackView.addArrangedSubview(label)
        }
        
        // Evaluation Section
        let feedbackHeader = UILabel()
        feedbackHeader.text = "Evaluation"
        feedbackHeader.font = .systemFont(ofSize: 20, weight: .bold)
        mainStackView.setCustomSpacing(20, after: mainStackView.arrangedSubviews.last ?? UIView())
        mainStackView.addArrangedSubview(feedbackHeader)
        
        // --- ADD SCORE RESULT VIEW ---
        setupScoreResultView()
        mainStackView.addArrangedSubview(scoreResultContainer)
        mainStackView.addArrangedSubview(assignScoreButton)
    }
    private func setButtonLoading(_ isLoading: Bool, button: UIButton, originalTitle: String) {
        if isLoading {
            button.isEnabled = false
            button.setTitle("", for: .normal)
            
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.color = .systemBlue
            spinner.tag = 999 // Tag to find and remove later
            spinner.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(spinner)
            
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: button.centerYAnchor)
            ])
            spinner.startAnimating()
        } else {
            button.isEnabled = true
            button.setTitle(originalTitle, for: .normal)
            button.viewWithTag(999)?.removeFromSuperview()
        }
    }
    private func setupScoreResultView() {
        let stack = UIStackView(arrangedSubviews: [scoreLabel, remarksLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        scoreResultContainer.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scoreResultContainer.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scoreResultContainer.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: scoreResultContainer.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scoreResultContainer.trailingAnchor, constant: -16)
        ])
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
    
    // MARK: - Data Fetching
    
    private func fetchSubmissionData() {
        guard let assignmentID = assignment?.id else { return }
        Task {
            do {
                let result: [AssignmentSubmission] = try await supabase
                    .from("assignment_submissions")
                    .select()
                    .eq("assignment_id", value: assignmentID)
                    .execute()
                    .value
                
                await MainActor.run {
                    if let sub = result.first {
                        self.submission = sub
                        self.populateSubmissionUI(sub)
                    }
                }
            } catch { print("❌ Error fetching submission: \(error)") }
        }
    }
    
    private func populateSubmissionUI(_ sub: AssignmentSubmission) {
        // 1. Fill Answers
        for (index, answer) in sub.answers.enumerated() {
            if index < questionTextFields.count {
                questionTextFields[index].text = answer
                questionTextFields[index].isEnabled = false
            }
        }
        
        // 2. Show Score if exists
        if let score = sub.score {
            scoreLabel.text = "Score: \(score)/10"
            remarksLabel.text = sub.remarks?.isEmpty == false ? sub.remarks : "No remarks provided."
            
            scoreResultContainer.isHidden = false
            assignScoreButton.setTitle("Edit Score", for: .normal) // Change button text
        } else {
            scoreResultContainer.isHidden = true
            assignScoreButton.setTitle("Assign Score & Feedback", for: .normal)
        }
    }

    // MARK: - Actions & Helpers
    
    private func createQuestionView(title: String, placeholder: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.numberOfLines = 0
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .darkGray
        
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.backgroundColor = .white
        textField.font = .systemFont(ofSize: 16)
        textField.layer.cornerRadius = 16
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        textField.isEnabled = false
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        questionTextFields.append(textField)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(textField)
        return stack
    }
    
    private func createButton(title: String, isFilled: Bool, backgroundColor: UIColor? = nil) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 25
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        if isFilled {
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = backgroundColor ?? .clear
            button.setTitleColor(.systemBlue, for: .normal)
            button.layer.borderColor = UIColor.systemBlue.cgColor
            button.layer.borderWidth = 2
        }
        return button
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func playPatientVideo() {
        guard let sub = submission, let videoPath = sub.video_url else {
            let alert = UIAlertController(title: "No Video", message: "The patient has not uploaded a video yet.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        Task {
            do {
                let signedURL = try await supabase.storage
                    .from("assignment-videos")
                    .createSignedURL(path: videoPath, expiresIn: 3600)
                
                await MainActor.run {
                    let player = AVPlayer(url: signedURL)
                    let playerVC = AVPlayerViewController()
                    playerVC.player = player
                    present(playerVC, animated: true) { player.play() }
                }
            } catch { print("❌ Playback Error: \(error)") }
        }
    }
    
    @objc private func didTapAssignScore() {
        let assignScoreVC = AssignScoreViewController()
        assignScoreVC.submissionID = submission?.id
        navigationController?.pushViewController(assignScoreVC, animated: true)
    }
    
    // QuickLook
    private func downloadAndPreview(urlString: String, onButton: UIButton) {
        guard let url = URL(string: urlString) else { return }
        let originalTitle = onButton.title(for: .normal) ?? ""
        
        // Start Loading on the Button
        setButtonLoading(true, button: onButton, originalTitle: originalTitle)
        
        Task {
            do {
                let (tempUrl, response) = try await URLSession.shared.download(from: url)
                let fileName = response.suggestedFilename ?? url.lastPathComponent
                let destinationUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                
                if FileManager.default.fileExists(atPath: destinationUrl.path) {
                    try FileManager.default.removeItem(at: destinationUrl)
                }
                try FileManager.default.moveItem(at: tempUrl, to: destinationUrl)
                
                await MainActor.run {
                    // Stop Loading
                    setButtonLoading(false, button: onButton, originalTitle: originalTitle)
                    
                    self.attachmentToPreview = destinationUrl
                    let ql = QLPreviewController()
                    ql.dataSource = self
                    ql.modalPresentationStyle = .fullScreen
                    self.present(ql, animated: true)
                }
            } catch {
                await MainActor.run {
                    setButtonLoading(false, button: onButton, originalTitle: originalTitle)
                    print("❌ Download Error: \(error)")
                }
            }
        }
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { return 1 }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return attachmentToPreview! as QLPreviewItem
    }
}
