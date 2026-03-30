import UIKit

protocol TermsViewControllerDelegate: AnyObject {
    func termsViewControllerDidAccept(_ controller: TermsViewController)
}

final class TermsViewController: UIViewController {

    // MARK: - Public API
    weak var delegate: TermsViewControllerDelegate?
    var termsFileName: String? = "TermsAndConditions"

    // MARK: - UI Elements
    private let textView = UITextView()
    private let manualNavBar = UINavigationBar()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureUI()
        loadTermsText()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if navigationController != nil {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    // MARK: - UI Setup
    private func configureUI() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 15)
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 14, bottom: 34, right: 14)
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        view.addSubview(textView)

        if navigationController == nil {
            // Standalone manual UINavigationBar when presented modally
            manualNavBar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(manualNavBar)

            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            manualNavBar.standardAppearance = appearance
            manualNavBar.scrollEdgeAppearance = appearance

            let navItem = UINavigationItem(title: "Terms & Conditions")
            navItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(backTapped))
            navItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .done, target: self, action: #selector(acceptTapped))
            manualNavBar.setItems([navItem], animated: false)

            NSLayoutConstraint.activate([
                manualNavBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                manualNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                manualNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                textView.topAnchor.constraint(equalTo: manualNavBar.bottomAnchor),
                textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        } else {
            // Use native navigation controller if one exists
            title = "Terms & Conditions"
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(backTapped))
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .done, target: self, action: #selector(acceptTapped))
            
            NSLayoutConstraint.activate([
                textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }

    // MARK: - Load terms text
    private func loadTermsText() {
        if let fname = termsFileName,
           let url = Bundle.main.url(forResource: fname, withExtension: "txt"),
           let s = try? String(contentsOf: url, encoding: .utf8) {
            textView.text = s
            return
        }

        textView.text = """
        1. Introduction & Acceptance of Terms

        • Purpose: States that by accessing or using the TheraSync apps (Pro, Connect, Kids), the user agrees to these terms.

        2. Eligibility and User Accounts

        • Purpose: Defines who can use the apps and the responsibilities of account holders.

        (Replace this fallback by adding TermsAndConditions.txt to the app bundle.)
        """
    }

    // MARK: - Actions
    @objc private func backTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @objc private func acceptTapped() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        delegate?.termsViewControllerDidAccept(self)
        dismiss(animated: true, completion: nil)
    }
}
