import UIKit

protocol TermsViewControllerDelegate: AnyObject {
    func termsViewControllerDidAccept(_ controller: TermsViewController)
}

final class TermsViewController: UIViewController {

    // MARK: - Public API
    weak var delegate: TermsViewControllerDelegate?
    var termsFileName: String? = "TermsAndConditions"

    // MARK: - UI
    private let headerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Terms & Conditions"
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .close)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = .systemFont(ofSize: 15)
        tv.textColor = .label
        tv.backgroundColor = .systemBackground
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let acceptButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Accept & Continue", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 26
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let bottomBar: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupHierarchy()
        setupConstraints()
        loadTermsText()
        closeButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // If inside a nav controller, hide our custom header and use native bar
        if let nav = navigationController {
            headerView.isHidden = true
            divider.isHidden = true
            nav.setNavigationBarHidden(false, animated: animated)
            title = "Terms & Conditions"
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self, action: #selector(backTapped))
        }
    }

    // MARK: - Setup
    private func setupHierarchy() {
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        view.addSubview(divider)
        view.addSubview(textView)
        view.addSubview(bottomBar)
        bottomBar.addSubview(acceptButton)
    }

    private func setupConstraints() {
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: safe.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            // Divider
            divider.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            // Text view
            textView.topAnchor.constraint(equalTo: divider.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            // Bottom accept bar
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 100),

            acceptButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 24),
            acceptButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -24),
            acceptButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            acceptButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    // MARK: - Load Text
    private func loadTermsText() {
        if let fname = termsFileName,
           let url = Bundle.main.url(forResource: fname, withExtension: "txt"),
           let s = try? String(contentsOf: url, encoding: .utf8) {
            textView.attributedText = applyWarningFormatting(to: s)
            return
        }
        let fallbackText = """
        1. Introduction & Acceptance of Terms

        • Purpose: States that by accessing or using the TheraSync apps (Pro, Connect, Kids), the user agrees to these terms.

        2. Eligibility and User Accounts

        • Purpose: Defines who can use the apps and the responsibilities of account holders.

        (Replace this fallback by adding TermsAndConditions.txt to the app bundle.)
        """
        textView.attributedText = applyWarningFormatting(to: fallbackText)
    }

    private func applyWarningFormatting(to text: String) -> NSAttributedString {
        let attrString = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.label
        ])
        
        let warningText = "⚠️ WARNING: DATA CONTROLLER NOTICE\nThe Occupational Therapist (OT) is the Data Controller for all patient information. TheraSync acts solely as a Data Processor. We do not own, govern, or make independent decisions regarding your medical data."
        
        if let range = text.range(of: warningText) {
            let nsRange = NSRange(range, in: text)
            // Amber background
            attrString.addAttribute(.backgroundColor, value: UIColor.systemOrange.withAlphaComponent(0.2), range: nsRange)
            attrString.addAttribute(.foregroundColor, value: UIColor.label, range: nsRange)
            attrString.addAttribute(.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: nsRange)
        }
        
        return attrString
    }

    // MARK: - Actions
    @objc private func backTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func acceptTapped() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        delegate?.termsViewControllerDidAccept(self)
        dismiss(animated: true)
    }
}
