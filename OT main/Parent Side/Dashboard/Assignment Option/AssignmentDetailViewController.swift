import UIKit
import AVKit
import AVFoundation
import MobileCoreServices
import Storage
import Supabase
import QuickLook
// MARK: - Frosted Card
private class FrostedCardView: UIView {
    private let blur: UIVisualEffectView
    private let overlay: UIView
    init(cornerRadius: CGFloat = 18) {
        blur    = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
        overlay = UIView()
        super.init(frame: .zero)
        layer.cornerRadius  = cornerRadius
        layer.masksToBounds = true
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowRadius  = 12
        layer.shadowOffset  = CGSize(width: 0, height: 4)
        blur.translatesAutoresizingMaskIntoConstraints    = false
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.white.withAlphaComponent(0.55)
        addSubview(blur)
        addSubview(overlay)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
            overlay.topAnchor.constraint(equalTo: topAnchor),
            overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func embed(_ view: UIView, insets: UIEdgeInsets = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
    }
}
// MARK: - AssignmentDetailViewController
class AssignmentDetailViewController: UIViewController,
    UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    QLPreviewControllerDataSource {
    // MARK: - Properties
    var currentAssignment: Assignment?
    var assignmentTitle: String?
    private var attachmentToPreview: URL?
    private var recordedVideoURLs: [URL] = []
    private var questionFields: [UITextField] = []
    // Button references (need to mutate after fetch)
    private var recordButton: UIButton?
    private var completeButton: UIButton?
    // MARK: - Palette (adapts to dark/light automatically)
    private enum Accent {
        /// Warm amber – matches the parent gradient top colour
        static let amber    = UIColor(r: 255, g: 166, b: 0)
        static let amberDim = UIColor(r: 230, g: 115, b: 0)
        static let cardLabel: UIColor = UIColor(white: 0.12, alpha: 1)
        static let cardSub:   UIColor = UIColor(white: 0.40, alpha: 1)
    }
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()
    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis    = .vertical
        sv.spacing = 14
        sv.isLayoutMarginsRelativeArrangement = true
        sv.layoutMargins = UIEdgeInsets(top: 16, left: 18, bottom: 48, right: 18)
        return sv
    }()
    // Score result card
    private let scoreCard = FrostedCardView(cornerRadius: 18)
    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        l.textColor = UIColor(r: 46, g: 200, b: 90)
        l.textAlignment = .center
        return l
    }()
    private let remarksLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 15)
        l.textColor = Accent.cardSub
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()
    // MARK: - Initializers
    init() {
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.hidesBottomBarWhenPushed = true
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        buildBackground()
        buildLayout()
        buildScoreCard()
        addDetailComponents()
        fetchSubmissionStatus()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        applyNavBar()
    }
    // MARK: - Background & Nav
    private func buildBackground() {
        let bg = ParentGradientView()
        bg.frame = view.bounds
        bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(bg)
        view.sendSubviewToBack(bg)
    }
    private func applyNavBar() {
        title = assignmentTitle
        let dark = traitCollection.userInterfaceStyle == .dark
        let fg: UIColor = dark ? .white : UIColor(white: 0.10, alpha: 1)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: fg,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navigationController?.navigationBar.tintColor = fg
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance    = appearance
    }
    // MARK: - Layout
    private func buildLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    // MARK: - Score Card Builder
    private func buildScoreCard() {
        scoreCard.isHidden = true
        // Green tint overlay
        let tint = UIView()
        tint.translatesAutoresizingMaskIntoConstraints = false
        tint.backgroundColor = UIColor(r: 46, g: 200, b: 90, a: 0.08)
        scoreCard.addSubview(tint)
        NSLayoutConstraint.activate([
            tint.topAnchor.constraint(equalTo: scoreCard.topAnchor),
            tint.leadingAnchor.constraint(equalTo: scoreCard.leadingAnchor),
            tint.trailingAnchor.constraint(equalTo: scoreCard.trailingAnchor),
            tint.bottomAnchor.constraint(equalTo: scoreCard.bottomAnchor)
        ])
        let star = UIImageView(image: UIImage(systemName: "star.fill",
                                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)))
        star.tintColor = UIColor(r: 46, g: 200, b: 90)
        let topRow = UIStackView(arrangedSubviews: [star, scoreLabel])
        topRow.axis      = .horizontal
        topRow.spacing   = 8
        topRow.alignment = .center
        let outerStack = UIStackView(arrangedSubviews: [topRow, remarksLabel])
        outerStack.axis      = .vertical
        outerStack.spacing   = 6
        outerStack.alignment = .center
        scoreCard.embed(outerStack, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        scoreCard.layer.borderWidth = 1
        scoreCard.layer.borderColor = UIColor(r: 46, g: 200, b: 90, a: 0.30).cgColor
    }
    // MARK: - Detail Components
    private func addDetailComponents() {
        guard let assignment = currentAssignment else { return }
        // Score card goes first (hidden until loaded)
        contentStack.addArrangedSubview(scoreCard)
        // ── Instructions ──
        if !assignment.instruction.isEmpty {
            contentStack.addArrangedSubview(sectionHeader("Therapist Instructions"))
            let card = FrostedCardView(cornerRadius: 16)
            let label = UILabel()
            label.text          = assignment.instruction
            label.numberOfLines = 0
            label.font          = UIFont.systemFont(ofSize: 15)
            label.textColor     = Accent.cardLabel
            card.embed(label, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
            contentStack.addArrangedSubview(card)
            contentStack.setCustomSpacing(20, after: card)
        }
        // ── Attachments ──
        if !assignment.attachmentUrls.isEmpty {
            contentStack.addArrangedSubview(sectionHeader("Attachments"))
            for (i, urlString) in assignment.attachmentUrls.enumerated() {
                contentStack.addArrangedSubview(attachmentButton(title: "View Attachment \(i + 1)", urlString: urlString))
            }
            contentStack.setCustomSpacing(20, after: contentStack.arrangedSubviews.last ?? UIView())
        }
        // ── Questions ──
        if !assignment.quizQuestions.isEmpty {
            contentStack.addArrangedSubview(sectionHeader("Questions"))
            for (i, q) in assignment.quizQuestions.enumerated() {
                contentStack.addArrangedSubview(questionCard(number: i + 1, text: q))
            }
            contentStack.setCustomSpacing(24, after: contentStack.arrangedSubviews.last ?? UIView())
        }
        // ── Action Buttons ──
        if assignment.type == "Video Submission" {
            let recBtn = makeActionButton(title: "Record Video", icon: "video.fill", filled: true, color: Accent.amberDim)
            recBtn.addTarget(self, action: #selector(recordVideoTapped), for: .touchUpInside)
            self.recordButton = recBtn
            contentStack.addArrangedSubview(recBtn)
        }
        let doneBtn = makeActionButton(title: "Mark as Complete", icon: "checkmark.circle.fill", filled: true, color: Accent.amber)
        doneBtn.addTarget(self, action: #selector(handleComplete(sender:)), for: .touchUpInside)
        self.completeButton = doneBtn
        contentStack.addArrangedSubview(doneBtn)
    }
    // MARK: - Factory Helpers
    /// Adaptive uppercase section header — dark on orange (light), white on navy (dark).
    private func sectionHeader(_ text: String) -> UILabel {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        l.textColor = UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.70)
                : UIColor(white: 0.18, alpha: 0.70)
        }
        let attr = NSAttributedString(string: text.uppercased(), attributes: [
            .kern: 1.5,
            .font: l.font as Any,
            .foregroundColor: l.textColor as Any
        ])
        l.attributedText = attr
        return l
    }
    private func questionCard(number: Int, text: String) -> UIView {
        let card  = FrostedCardView(cornerRadius: 16)
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis    = .vertical
        stack.spacing = 10
        // Number chip
        let chip = UILabel()
        chip.text            = "Q\(number)"
        chip.font            = UIFont.systemFont(ofSize: 11, weight: .bold)
        chip.textColor       = Accent.amberDim
        chip.backgroundColor = Accent.amber.withAlphaComponent(0.15)
        chip.textAlignment   = .center
        chip.layer.cornerRadius = 8
        chip.clipsToBounds   = true
        chip.widthAnchor.constraint(equalToConstant: 32).isActive = true
        chip.heightAnchor.constraint(equalToConstant: 22).isActive = true
        let chipRow = UIStackView(arrangedSubviews: [chip, UIView()])
        chipRow.axis = .horizontal
        let questionLabel = UILabel()
        questionLabel.text          = text
        questionLabel.numberOfLines = 0
        questionLabel.font          = UIFont.systemFont(ofSize: 15, weight: .semibold)
        questionLabel.textColor     = Accent.cardLabel
        let field = UITextField()
        field.placeholder       = "Type your answer here…"
        field.font              = UIFont.systemFont(ofSize: 15)
        field.textColor         = Accent.cardLabel
        field.backgroundColor   = UIColor(white: 0.96, alpha: 1)
        field.layer.cornerRadius   = 12
        field.layer.borderWidth    = 1
        field.layer.borderColor    = UIColor(white: 0.88, alpha: 1).cgColor
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        field.translatesAutoresizingMaskIntoConstraints = false
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 48))
        field.leftView     = pad
        field.leftViewMode = .always
        questionFields.append(field)
        stack.addArrangedSubview(chipRow)
        stack.addArrangedSubview(questionLabel)
        stack.addArrangedSubview(field)
        card.embed(stack, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        return card
    }
    private func attachmentButton(title: String, urlString: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "paperclip.circle.fill",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
        config.imagePadding   = 10
        config.imagePlacement = .leading
        config.baseForegroundColor = Accent.amberDim
        config.contentInsets  = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        let btn = UIButton(configuration: config)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btn.contentHorizontalAlignment = .leading
        btn.backgroundColor    = UIColor.white.withAlphaComponent(0.80)
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth  = 1
        btn.layer.borderColor  = UIColor.white.withAlphaComponent(0.40).cgColor
        btn.heightAnchor.constraint(equalToConstant: 52).isActive = true
        btn.addAction(UIAction { [weak self] _ in
            self?.downloadAndPreview(urlString: urlString)
        }, for: .touchUpInside)
        return btn
    }
    private func makeActionButton(title: String, icon: String, filled: Bool, color: UIColor) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor  = color
        config.baseForegroundColor  = .white
        config.image = UIImage(systemName: icon,
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
        config.imagePadding   = 8
        config.imagePlacement = .leading
        config.contentInsets  = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        config.cornerStyle    = .large
        let btn = UIButton(configuration: config)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        btn.heightAnchor.constraint(equalToConstant: 54).isActive = true
        btn.layer.shadowColor   = color.cgColor
        btn.layer.shadowOpacity = 0.35
        btn.layer.shadowRadius  = 12
        btn.layer.shadowOffset  = CGSize(width: 0, height: 6)
        // Ensure config title
        var updatedConfig = btn.configuration
        updatedConfig?.title = title
        btn.configuration = updatedConfig
        btn.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        btn.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return btn
    }
    // MARK: - Button Animation
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, delay: 0, options: .curveEaseIn) {
            sender.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            sender.alpha = 0.88
        }
    }
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 4) {
            sender.transform = .identity
            sender.alpha = 1
        }
    }
    // MARK: - Data Fetching
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
                        self.populateExistingAnswers(sub)
                        self.lockSubmittedUI(sub: sub)
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
    private func populateExistingAnswers(_ sub: AssignmentSubmission) {
        for (i, answer) in sub.answers.enumerated() {
            guard i < questionFields.count else { continue }
            let field = questionFields[i]
            field.text            = answer
            field.isEnabled       = false
            field.textColor       = Accent.cardSub
            field.backgroundColor = UIColor(white: 0.93, alpha: 1)
        }
    }
    private func lockSubmittedUI(sub: AssignmentSubmission) {
        // Hide complete button
        UIView.animate(withDuration: 0.20) {
            self.completeButton?.isHidden = true
        }
        completeButton?.isEnabled = false
        // Update video button if video was submitted
        if sub.video_url != nil {
            var config = recordButton?.configuration
            config?.title = "Video Submitted ✓"
            config?.baseBackgroundColor = .systemGray3
            recordButton?.configuration = config
            recordButton?.isEnabled = false
        }
    }
    // MARK: - Show Results
    private func showResults(score: Int, remarks: String) {
        scoreLabel.text  = "\(score) / 10"
        remarksLabel.text = remarks.isEmpty ? "No remarks provided." : remarks
        UIView.animate(withDuration: 0.30, delay: 0, options: .curveEaseOut) {
            self.scoreCard.isHidden = false
            self.scoreCard.alpha    = 1
        }
    }
    // MARK: - Actions
    @objc private func recordVideoTapped() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            openCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { self.openCamera() }
                }
            }
        case .denied, .restricted:
            let alert = UIAlertController(
                title: "Camera Access Required",
                message: "Therasync needs camera access to record assignment videos. Please enable it in Settings.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            present(alert, animated: true)
        @unknown default:
            openCamera()
        }
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.sourceType  = .camera
        picker.mediaTypes  = [UTType.movie.identifier as String]
        picker.delegate    = self
        present(picker, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            recordedVideoURLs = [videoURL]
            var config = recordButton?.configuration
            config?.title = "Video Recorded ✓"
            config?.baseBackgroundColor = UIColor(r: 46, g: 200, b: 90)
            recordButton?.configuration = config
        }
        dismiss(animated: true)
    }
    @objc private func handleComplete(sender: UIButton) {
        guard let assignment = currentAssignment, let pID = assignment.patient_id else { return }
        sender.isEnabled = false
        var config = sender.configuration
        config?.showsActivityIndicator = true
        config?.title = ""
        sender.configuration = config
        let answers = questionFields.map { $0.text ?? "" }
        Task {
            do {
                var videoPath: String?
                if let videoURL = recordedVideoURLs.first {
                    let data = try Data(contentsOf: videoURL)
                    let path = "submissions/\(assignment.id?.uuidString ?? UUID().uuidString).mp4"
                    try await supabase.storage.from("assignment-videos")
                        .upload(path: path, file: data, options: FileOptions(contentType: "video/mp4"))
                    videoPath = path
                }
                let submission = AssignmentSubmission(
                    id: UUID(),
                    assignment_id: assignment.id ?? UUID(),
                    patient_id: pID,
                    answers: answers,
                    video_url: videoPath,
                    score: nil,
                    remarks: nil
                )
                try await supabase.from("assignment_submissions").insert(submission).execute()
                await MainActor.run {
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    sender.isEnabled = true
                    var cfg = sender.configuration
                    cfg?.showsActivityIndicator = false
                    cfg?.title = "Mark as Complete"
                    sender.configuration = cfg
                }
            }
        }
    }
    // MARK: - QuickLook
    private func downloadAndPreview(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        Task {
            do {
                let (tempUrl, response) = try await URLSession.shared.download(from: url)
                let mimeType  = response.mimeType ?? ""
                let ext       = extensionFor(mimeType: mimeType) ?? url.pathExtension
                let finalExt  = ext.isEmpty ? "pdf" : ext
                let fileName  = "Attachment_\(UUID().uuidString).\(finalExt)"
                let destURL   = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try? FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.moveItem(at: tempUrl, to: destURL)
                await MainActor.run {
                    self.navigationItem.rightBarButtonItem = nil
                    self.attachmentToPreview = destURL
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
    private func extensionFor(mimeType: String) -> String? {
        let map: [String: String] = [
            "image/jpeg": "jpg", "image/jpg": "jpg", "image/png": "png",
            "application/pdf": "pdf", "application/msword": "doc",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
            "video/mp4": "mp4", "audio/mpeg": "mp3"
        ]
        return map[mimeType.lowercased()]
    }
    func numberOfPreviewItems(in c: QLPreviewController) -> Int { 1 }
    func previewController(_ c: QLPreviewController, previewItemAt i: Int) -> QLPreviewItem {
        attachmentToPreview! as QLPreviewItem
    }
}
