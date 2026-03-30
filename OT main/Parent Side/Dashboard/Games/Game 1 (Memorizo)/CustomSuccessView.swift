//
//  CustomSuccessView.swift
//  OT main
//
//  Created by Garvit Pareek on 10/01/2026.
//


import UIKit

class CustomSuccessView: UIView {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .dynamicCard // Your theme-aware card color
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Congratulations! 🎉"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .dynamicLabel // Your theme-aware text color
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "You've mastered Memorizo Level 7!"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .dynamicLabel // Your theme-aware text color
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var finishButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Awesome!", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.24, green: 0.51, blue: 1.0, alpha: 1.0) // Your brand blue
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(finishTapped), for: .touchUpInside)
        return button
    }()
    
    // Closure to be called when the finish button is tapped
    var onFinish: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTheme), name: NSNotification.Name("AppThemeChanged"), object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupView() {
        // Overlay background (darkens the view behind the pop-up)
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(finishButton)

        NSLayoutConstraint.activate([
            // Center the container view in the middle of the screen
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8), // 80% width
            containerView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 0.5), // Max 50% height

            // Layout labels and button inside the container
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            finishButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 30),
            finishButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            finishButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            finishButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30) // Pin to bottom
        ])
    }
    
    @objc private func refreshTheme() {
        // When theme changes, re-apply colors
        containerView.backgroundColor = .dynamicCard
        titleLabel.textColor = .dynamicLabel
        messageLabel.textColor = .dynamicLabel
    }

    @objc private func finishTapped() {
        onFinish?() // Call the closure defined by the presenting view controller
    }
}