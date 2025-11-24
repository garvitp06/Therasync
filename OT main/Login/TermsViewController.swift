//
//  TermsViewController.swift
//  Terms
//
//  Created by user@54 on 21/11/25.
//


import UIKit

protocol TermsViewControllerDelegate: AnyObject {
    func termsViewControllerDidAccept(_ controller: TermsViewController)
}

final class TermsViewController: UIViewController {

    // MARK: - Public API
    weak var delegate: TermsViewControllerDelegate?
    /// If you add a TermsAndConditions.txt to the app bundle, set this to "TermsAndConditions".
    /// If nil, a short fallback sample is shown.
    var termsFileName: String? = "TermsAndConditions"

    // MARK: - UI Elements
    private let headerContainer = UIView()
    private let headerBackground = UIView() // solid header (no blur)
    private let backButton = UIButton(type: .system)
    private let acceptButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let separator = UIView()
    private let textView = UITextView()

    // Gesture handling for interactive dismissal
    private var panStartTransform: CGAffineTransform = .identity

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureUI()
        loadTermsText()
        configureInteractiveDismiss()
    }

    // MARK: - UI Setup
    private func configureUI() {
        // Header container
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerContainer)

        // Header solid background
        headerBackground.translatesAutoresizingMaskIntoConstraints = false
        headerBackground.backgroundColor = UIColor(red: 0.20, green: 0.55, blue: 0.98, alpha: 1) // TheraSync blue
        headerContainer.addSubview(headerBackground)

        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Terms & Conditions"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        headerContainer.addSubview(titleLabel)

        // Back button (chevron.left)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = UIColor(white: 1.0, alpha: 0.15)
        backButton.layer.cornerRadius = 22 // circle with 40x40
        backButton.layer.masksToBounds = true
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        headerContainer.addSubview(backButton)

        // Accept button (checkmark)
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        acceptButton.tintColor = .white
        acceptButton.backgroundColor = UIColor(white: 1.0, alpha: 0.15)
        acceptButton.layer.cornerRadius = 22
        acceptButton.layer.masksToBounds = true
        acceptButton.accessibilityLabel = "Accept"
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        headerContainer.addSubview(acceptButton)

        // Separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor(white: 0.9, alpha: 1)
        headerContainer.addSubview(separator)

        // Text view
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 15)
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 14, bottom: 34, right: 14)
        textView.backgroundColor = .clear
        view.addSubview(textView)

        // Subtle shadows for buttons
        [backButton, acceptButton].forEach {
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOpacity = 0.12
            $0.layer.shadowRadius = 2
            $0.layer.shadowOffset = CGSize(width: 0, height: 1)
        }

        // Layout constraints
        NSLayoutConstraint.activate([
            // Header container pinned to the very top of the view (we use safe area inside for vertical centering)
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: 120),

            // Header background fills the header container
            headerBackground.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            headerBackground.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerBackground.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            headerBackground.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),

            // Back button (40x40)
            backButton.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: headerContainer.safeAreaLayoutGuide.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            // Accept button (40x40)
            acceptButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -12),
            acceptButton.centerYAnchor.constraint(equalTo: headerContainer.safeAreaLayoutGuide.centerYAnchor),
            acceptButton.widthAnchor.constraint(equalToConstant: 44),
            acceptButton.heightAnchor.constraint(equalToConstant: 44),

            // Title label centered (use safeArea center to respect notch)
            titleLabel.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerContainer.safeAreaLayoutGuide.centerYAnchor),

            // Separator bottom of header
            separator.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),

            // Text view below header
            textView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Load terms text
    private func loadTermsText() {
        if let fname = termsFileName,
           let url = Bundle.main.url(forResource: fname, withExtension: "txt"),
           let s = try? String(contentsOf: url, encoding: .utf8) {
            textView.text = s
            return
        }

        // Fallback short sample text (safe to embed)
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
        // If inside a navigation controller and not the root, pop; otherwise dismiss
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @objc private func acceptTapped() {
        // Haptic feedback and notify delegate
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        delegate?.termsViewControllerDidAccept(self)
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Interactive dismiss (swipe down)
    private func configureInteractiveDismiss() {
        // Add a pan recognizer that allows drag-down-to-dismiss
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)

        // Allow normal iOS modal swipe-to-dismiss behavior too
        isModalInPresentation = false
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        let translation = g.translation(in: view)
        let velocity = g.velocity(in: view)

        switch g.state {
        case .began:
            panStartTransform = view.transform
        case .changed:
            if translation.y > 0 {
                view.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended, .cancelled:
            // If dragged far enough or flicked downward, dismiss; otherwise snap back
            if translation.y > 160 || velocity.y > 1200 {
                UIView.animate(withDuration: 0.18, animations: {
                    self.view.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
                }, completion: { _ in
                    self.dismiss(animated: false, completion: nil)
                })
            } else {
                UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                    self.view.transform = .identity
                }, completion: nil)
            }
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension TermsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only begin for vertical pans
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let v = pan.velocity(in: view)
            return abs(v.y) > abs(v.x)
        }
        return true
    }
}
