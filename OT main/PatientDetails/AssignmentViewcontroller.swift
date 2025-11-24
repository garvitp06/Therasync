//
//  AssignmentViewController.swift
//  Assignment
//
//  Created by Alishri Poddar on 17/11/25.
//

import UIKit

class AssignmentViewController: UIViewController {

    // MARK: - UI Components
    
    // Main scroll view
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    // Content view inside the scroll view
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20 // Space between elements
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 40, right: 16)
        return stackView
    }()
    
    // Video Player Placeholder
    private let videoPlayerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        
        let playIcon = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 40)))
        playIcon.tintColor = .black
        playIcon.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(playIcon)
        NSLayoutConstraint.activate([
            playIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            // Give the view a height based on aspect ratio
            view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 9.0/16.0)
        ])
        
        return view
    }()
    
    // Buttons
    private let patientVideoButton: UIButton = {
        let button = createButton(title: "Patient's Video Submission", isFilled: true)
        return button
    }()
    
    private let downloadButton: UIButton = {
        let button = createButton(title: "Download Video", isFilled: false)
        return button
    }()
    
    // Bottom Action Buttons
    private let submitFeedbackButton: UIButton = {
        let button = createButton(title: "Submit Feedback", isFilled: false, backgroundColor: .white)
        return button
    }()
    
    private let assignScoreButton: UIButton = {
        let button = createButton(title: "Assign Score", isFilled: false, backgroundColor: .white)
        return button
    }()

    // MARK: - View Lifecycle

    override func loadView() {
        // Set GradientView as the main view
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupViews()
        setupLayout()
    }

    // MARK: - Setup Functions

    private func setupNavigationBar() {
        // Set the title
        title = "Assignment 1"
        
        // Make navigation bar transparent to show gradient behind it
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        
        // Create Left Bar Button (Back)
        let backButtonImage = UIImage(systemName: "chevron.left")
        
        // Style the back button as a blue circle
        let buttonView = UIButton(type: .system)
        buttonView.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        buttonView.setImage(backButtonImage, for: .normal)
        buttonView.tintColor = .white
        buttonView.backgroundColor = .systemGray
        buttonView.layer.cornerRadius = 18 // height / 2
        buttonView.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: buttonView)
        
        NSLayoutConstraint.activate([
            buttonView.widthAnchor.constraint(equalToConstant: 36),
            buttonView.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(mainStackView)
        
        // Add components to the main stack view
        mainStackView.addArrangedSubview(videoPlayerView)
        mainStackView.addArrangedSubview(patientVideoButton)
        mainStackView.addArrangedSubview(downloadButton)
        
        // Create a separator or just add spacing
        mainStackView.setCustomSpacing(32, after: downloadButton)
        
        // Add Questions
        mainStackView.addArrangedSubview(createQuestionView(title: "1. Question 1", placeholder: "Answer"))
        mainStackView.addArrangedSubview(createQuestionView(title: "2. Question 2", placeholder: "Answer"))
        mainStackView.addArrangedSubview(createQuestionView(title: "3. Question 3", placeholder: "Answer"))
        
        // Add the new "OTs Feedback" section right after Question 3
        mainStackView.addArrangedSubview(createQuestionView(title: "4. OTs Feedback", placeholder: "Answer"))
        
        // Add Bottom Buttons
        let bottomButtonStack = UIStackView(arrangedSubviews: [submitFeedbackButton, assignScoreButton])
        bottomButtonStack.axis = .horizontal
        bottomButtonStack.spacing = 16
        bottomButtonStack.distribution = .fillEqually
        
        mainStackView.addArrangedSubview(bottomButtonStack)
        mainStackView.setCustomSpacing(32, after: mainStackView.arrangedSubviews[mainStackView.arrangedSubviews.count - 2]) // Add space before bottom buttons
    }

    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: view.topAnchor), // Edge-to-edge for gradient
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // MainStackView constraints
            mainStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            mainStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor) // Key for vertical scrolling
        ])
    }

    // MARK: - View Creation Helpers

    /// Helper to create question blocks
    private func createQuestionView(title: String, placeholder: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .darkGray // Adjust as needed for gradient
        
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.backgroundColor = .white
        textField.font = .systemFont(ofSize: 16)
        textField.layer.cornerRadius = 16
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // Add padding to the text field
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = paddingView
        textField.rightViewMode = .always
        
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(textField)
        
        return stack
    }
    
    /// Helper to create standardized buttons
    private static func createButton(title: String, isFilled: Bool, backgroundColor: UIColor? = nil) -> UIButton {
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

    // MARK: - Actions

    @objc private func backButtonTapped() {
        print("Back button tapped")
        navigationController?.popViewController(animated: true)
    }
}
