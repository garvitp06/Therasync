import UIKit
import AVFoundation
import AVKit
import Supabase
import QuickLook
// MARK: - Frosted Card Helper
/// A UIView subclass that renders a white, blurred "frosted glass" card.
private class FrostedCardView: UIView {
    private let blur: UIVisualEffectView
    private let inner: UIView
    init(cornerRadius: CGFloat = 20) {
        blur  = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
        inner = UIView()
        super.init(frame: .zero)
        layer.cornerRadius  = cornerRadius
        layer.masksToBounds = true
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowRadius  = 12
        layer.shadowOffset  = CGSize(width: 0, height: 4)
        blur.translatesAutoresizingMaskIntoConstraints  = false
        inner.translatesAutoresizingMaskIntoConstraints = false
        inner.backgroundColor = UIColor.white.withAlphaComponent(0.55)
        addSubview(blur)
        addSubview(inner)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
            inner.topAnchor.constraint(equalTo: topAnchor),
            inner.leadingAnchor.constraint(equalTo: leadingAnchor),
            inner.trailingAnchor.constraint(equalTo: trailingAnchor),
            inner.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    /// Embed any view inside the card with padding.
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
// MARK: - Section Header Helper
private func makeSectionHeader(_ text: String) -> UILabel {
    let l = UILabel()
    l.text = text
    l.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
    l.textColor = UIColor.white.withAlphaComponent(0.75)
    l.textTransform(to: text.uppercased())
    return l
}
private extension UILabel {
    func textTransform(to text: String) { self.text = text }
}
// MARK: - AssignmentViewController
class AssignmentViewController: UIViewController, QLPreviewControllerDataSource {
    var assignment: Assignment?
    private var questionTextFields: [UITextField] = []
    private var submission: AssignmentSubmission?
    private var attachmentToPreview: URL?
    // MARK: Palette
    private enum Color {
        static let primary      = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1.0) // #007AFF
        static let cardBorder   = UIColor.white.withAlphaComponent(0.35)
        static let labelOnCard  = UIColor(white: 0.15, alpha: 1)
        static let subOnCard    = UIColor(white: 0.40, alpha: 1)
        static let placeholderOnCard = UIColor(white: 0.60, alpha: 1)
    }
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()
    private let mainStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis    = .vertical
        sv.spacing = 14
        sv.isLayoutMarginsRelativeArrangement = true
        sv.layoutMargins = UIEdgeInsets(top: 16, left: 18, bottom: 48, right: 18)
        return sv
    }()
    // MARK: Score Result Card
    private let scoreResultCard: FrostedCardView = {
        let c = FrostedCardView(cornerRadius: 18)
        c.isHidden = true
        return c
    }()
    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        l.textColor = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1) // emerald green
        l.textAlignment = .center
        return l
    }()
    private let remarksLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        l.textColor = Color.subOnCard
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()
    // MARK: Video Player
    private lazy var videoPlayerCard: FrostedCardView = {
        let card = FrostedCardView(cornerRadius: 18)
        // Ratio container
        let ratio = UIView()
        ratio.translatesAutoresizingMaskIntoConstraints = false
        ratio.backgroundColor = UIColor(white: 0.08, alpha: 1)
        ratio.layer.cornerRadius = 18
        ratio.clipsToBounds = true
        // Play button circle
        let circle = UIView()
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.backgroundColor = UIColor.white.withAlphaComponent(0.20)
        circle.layer.cornerRadius = 36
        let playImg = UIImageView(image: UIImage(systemName: "play.fill",
                                                  withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)))
        playImg.tintColor = .white
        playImg.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(playImg)
        ratio.addSubview(circle)
        card.addSubview(ratio)
        NSLayoutConstraint.activate([
            ratio.topAnchor.constraint(equalTo: card.topAnchor),
            ratio.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            ratio.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            ratio.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            ratio.heightAnchor.constraint(equalTo: ratio.widthAnchor, multiplier: 9.0 / 16.0),
            circle.widthAnchor.constraint(equalToConstant: 72),
            circle.heightAnchor.constraint(equalToConstant: 72),
            circle.centerXAnchor.constraint(equalTo: ratio.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: ratio.centerYAnchor),
            playImg.centerXAnchor.constraint(equalTo: circle.centerXAnchor, constant: 3),
            playImg.centerYAnchor.constraint(equalTo: circle.centerYAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(playPatientVideo))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
        return card
    }()
    private lazy var downloadButton: UIButton = makePrimaryButton(title: "Download Video", filled: false)
    private lazy var assignScoreButton: UIButton = {
        let btn = makePrimaryButton(title: "Assign Score & Feedback", filled: true)
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
        buildLayout()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchSubmissionData()
        applyNavBarAppearance()
        tabBarController?.tabBar.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    // MARK: - Navigation Bar
    private func setupNavigationBar() {
        title = assignment?.title ?? "Assignment"
        applyNavBarAppearance()
    }
    private func applyNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance    = appearance
    }
    // MARK: - Build Layout
    private func buildLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(mainStackView)
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            mainStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        populateStackView()
    }
    private func populateStackView() {
        let isVideoType = (assignment?.type == "Video Submission")
        // ── Video Section ──────────────────────────────────────────
        if isVideoType {
            mainStackView.addArrangedSubview(sectionHeader("Patient Video"))
            mainStackView.addArrangedSubview(videoPlayerCard)
            mainStackView.addArrangedSubview(downloadButton)
            mainStackView.setCustomSpacing(24, after: downloadButton)
        }
        // ── Attachments Section ────────────────────────────────────
        if let urls = assignment?.attachmentUrls, !urls.isEmpty {
            mainStackView.addArrangedSubview(sectionHeader("Attachments"))
            for (index, urlString) in urls.enumerated() {
                mainStackView.addArrangedSubview(attachmentButton(title: "View Attachment \(index + 1)", urlString: urlString))
            }
            mainStackView.setCustomSpacing(24, after: mainStackView.arrangedSubviews.last ?? UIView())
        }
        // ── Questions Section ──────────────────────────────────────
        if let questions = assignment?.quizQuestions, !questions.isEmpty {
            mainStackView.addArrangedSubview(sectionHeader("Questions"))
            for (index, questionText) in questions.enumerated() {
                mainStackView.addArrangedSubview(questionCard(number: index + 1, text: questionText))
            }
            mainStackView.setCustomSpacing(24, after: mainStackView.arrangedSubviews.last ?? UIView())
        } else if !isVideoType {
            let card = FrostedCardView(cornerRadius: 16)
            let lbl  = UILabel()
            lbl.text      = "No questions for this assignment."
            lbl.font      = UIFont.systemFont(ofSize: 15)
            lbl.textColor = Color.subOnCard
            lbl.textAlignment = .center
            card.embed(lbl, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
            mainStackView.addArrangedSubview(card)
            mainStackView.setCustomSpacing(24, after: card)
        }
        // ── Evaluation Section ─────────────────────────────────────
        mainStackView.addArrangedSubview(sectionHeader("Evaluation"))
        // Score result card (hidden until data loads)
        buildScoreResultCard()
        mainStackView.addArrangedSubview(scoreResultCard)
        mainStackView.addArrangedSubview(assignScoreButton)
    }
    // MARK: - Factory Helpers
    /// White all-caps section header label with modest opacity (sits on gradient).
    private func sectionHeader(_ text: String) -> UILabel {
        let l = UILabel()
        l.text      = text.uppercased()
        l.font      = UIFont.systemFont(ofSize: 11, weight: .bold)
        l.textColor = UIColor.white.withAlphaComponent(0.70)
        l.letterSpacing(1.5)
        return l
    }
    /// Frosted card wrapping a numbered question + disabled answer field.
    private func questionCard(number: Int, text: String) -> UIView {
        let card  = FrostedCardView(cornerRadius: 16)
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis    = .vertical
        stack.spacing = 10
        // Question number chip
        let chip = UILabel()
        chip.text            = "Q\(number)"
        chip.font            = UIFont.systemFont(ofSize: 11, weight: .bold)
        chip.textColor       = Color.primary
        chip.backgroundColor = Color.primary.withAlphaComponent(0.12)
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
        questionLabel.textColor     = Color.labelOnCard
        // Answer field (read-only by default)
        let field = UITextField()
        field.placeholder       = "Patient's Answer"
        field.font              = UIFont.systemFont(ofSize: 15)
        field.textColor         = Color.labelOnCard
        field.backgroundColor   = UIColor(white: 0.96, alpha: 1)
        field.layer.cornerRadius   = 12
        field.layer.borderWidth    = 1
        field.layer.borderColor    = UIColor(white: 0.88, alpha: 1).cgColor
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        field.isEnabled         = false
        field.translatesAutoresizingMaskIntoConstraints = false
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 48))
        field.leftView     = pad
        field.leftViewMode = .always
        questionTextFields.append(field)
        stack.addArrangedSubview(chipRow)
        stack.addArrangedSubview(questionLabel)
        stack.addArrangedSubview(field)
        card.embed(stack, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        return card
    }
    /// Frosted attachment button.
    private func attachmentButton(title: String, urlString: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image          = UIImage(systemName: "paperclip.circle.fill",
                                         withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
        config.imagePadding   = 10
        config.imagePlacement = .leading
        config.baseForegroundColor = Color.primary
        config.contentInsets  = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        let btn = UIButton(configuration: config)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btn.contentHorizontalAlignment = .leading
        btn.backgroundColor   = UIColor.white.withAlphaComponent(0.80)
        btn.layer.cornerRadius   = 14
        btn.layer.borderWidth    = 1
        btn.layer.borderColor    = UIColor.white.withAlphaComponent(0.40).cgColor
        btn.heightAnchor.constraint(equalToConstant: 52).isActive = true
        btn.addAction(UIAction { [weak self, weak btn] _ in
            guard let b = btn else { return }
            self?.downloadAndPreview(urlString: urlString, onButton: b)
        }, for: .touchUpInside)
        return btn
    }
    /// Primary action button – filled (blue) or outlined (white ghost).
    private func makePrimaryButton(title: String, filled: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 16
        button.heightAnchor.constraint(equalToConstant: 54).isActive = true
        if filled {
            button.backgroundColor = Color.primary
            button.setTitleColor(.white, for: .normal)
            // Subtle shadow
            button.layer.shadowColor   = Color.primary.cgColor
            button.layer.shadowOpacity = 0.40
            button.layer.shadowRadius  = 12
            button.layer.shadowOffset  = CGSize(width: 0, height: 6)
        } else {
            button.backgroundColor = UIColor.white.withAlphaComponent(0.20)
            button.setTitleColor(.white, for: .normal)
            button.layer.borderColor = UIColor.white.withAlphaComponent(0.60).cgColor
            button.layer.borderWidth = 1.5
        }
        // Highlight animation
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)),   for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return button
    }
    private func buildScoreResultCard() {
        // Green tinted frosted card
        let greenTint = UIView()
        greenTint.translatesAutoresizingMaskIntoConstraints = false
        greenTint.backgroundColor = UIColor(red: 0.18, green: 0.78, blue: 0.35, alpha: 0.08)
        scoreResultCard.addSubview(greenTint)
        NSLayoutConstraint.activate([
            greenTint.topAnchor.constraint(equalTo: scoreResultCard.topAnchor),
            greenTint.leadingAnchor.constraint(equalTo: scoreResultCard.leadingAnchor),
            greenTint.trailingAnchor.constraint(equalTo: scoreResultCard.trailingAnchor),
            greenTint.bottomAnchor.constraint(equalTo: scoreResultCard.bottomAnchor)
        ])
        // Star icon
        let star = UIImageView(image: UIImage(systemName: "star.fill",
                                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)))
        star.tintColor = UIColor(red: 0.18, green: 0.78, blue: 0.35, alpha: 1)
        let innerStack = UIStackView(arrangedSubviews: [star, scoreLabel])
        innerStack.axis    = .horizontal
        innerStack.spacing = 8
        innerStack.alignment = .center
        let outerStack = UIStackView(arrangedSubviews: [innerStack, remarksLabel])
        outerStack.axis      = .vertical
        outerStack.spacing   = 6
        outerStack.alignment = .center
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        scoreResultCard.embed(outerStack, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        scoreResultCard.layer.borderWidth = 1
        scoreResultCard.layer.borderColor = UIColor(red: 0.18, green: 0.78, blue: 0.35, alpha: 0.30).cgColor
    }
    // MARK: - Button Animation
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, delay: 0, options: .curveEaseIn) {
            sender.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            sender.alpha = 0.88
        }
    }
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.20, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 4) {
            sender.transform = .identity
            sender.alpha = 1
        }
    }
    // MARK: - Loading State
    private func setButtonLoading(_ isLoading: Bool, button: UIButton, originalTitle: String) {
        if isLoading {
            button.isEnabled = false
            button.setTitle("", for: .normal)
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.color = .white
            spinner.tag   = 999
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
        // Fill answers
        for (index, answer) in sub.answers.enumerated() {
            guard index < questionTextFields.count else { continue }
            questionTextFields[index].text      = answer
            questionTextFields[index].isEnabled = false
        }
        // Score
        if let score = sub.score {
            scoreLabel.text  = "\(score) / 10"
            remarksLabel.text = sub.remarks?.isEmpty == false ? sub.remarks : "No remarks provided."
            UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut) {
                self.scoreResultCard.isHidden = false
                self.scoreResultCard.alpha    = 1
            }
            assignScoreButton.setTitle("Edit Score & Feedback", for: .normal)
        } else {
            scoreResultCard.isHidden = true
            assignScoreButton.setTitle("Assign Score & Feedback", for: .normal)
        }
    }
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    @objc private func playPatientVideo() {
        guard let sub = submission, let videoPath = sub.video_url else {
            let alert = UIAlertController(title: "No Video",
                                          message: "The patient has not uploaded a video yet.",
                                          preferredStyle: .alert)
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
                    let player   = AVPlayer(url: signedURL)
                    let playerVC = AVPlayerViewController()
                    playerVC.player = player
                    present(playerVC, animated: true) { player.play() }
                }
            } catch { print("❌ Playback Error: \(error)") }
        }
    }
    @objc private func didTapAssignScore() {
        let vc = AssignScoreViewController()
        vc.submissionID = submission?.id
        navigationController?.pushViewController(vc, animated: true)
    }
    // MARK: - QuickLook
    private func downloadAndPreview(urlString: String, onButton: UIButton) {
        guard let url = URL(string: urlString) else { return }
        let originalTitle = onButton.title(for: .normal) ?? ""
        setButtonLoading(true, button: onButton, originalTitle: originalTitle)
        Task {
            do {
                let (tempUrl, response) = try await URLSession.shared.download(from: url)
                let fileName       = response.suggestedFilename ?? url.lastPathComponent
                let destinationUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: destinationUrl.path) {
                    try FileManager.default.removeItem(at: destinationUrl)
                }
                try FileManager.default.moveItem(at: tempUrl, to: destinationUrl)
                await MainActor.run {
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
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return attachmentToPreview! as QLPreviewItem
    }
}
// MARK: - UILabel Letter Spacing
private extension UILabel {
    func letterSpacing(_ value: CGFloat) {
        guard let text = text else { return }
        let attr = NSAttributedString(string: text, attributes: [
            .kern: value,
            .font: font as Any,
            .foregroundColor: textColor as Any
        ])
        attributedText = attr
    }
}
