//
//  RadioOptionView.swift
//  GrossMotorSkills
//
//  Created by Alishri Poddar on 27/11/25.
//



import UIKit

class RadioOptionView1: UIView {
    
    // Callbacks
    var onSelect: (() -> Void)?
    
    // UI Elements
    private let containerView = UIView()
    private let radioIcon = UIImageView()
    private let titleLabel = UILabel()
    private let separatorLine = UIView()
    
    // State
    var isSelectedOption: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    init(text: String, showSeparator: Bool = true) {
        super.init(frame: .zero)
        setupUI(text: text, showSeparator: showSeparator)
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(text: String, showSeparator: Bool) {
        // Layout
        addSubview(containerView)
        containerView.addSubview(radioIcon)
        containerView.addSubview(titleLabel)
        
        if showSeparator {
            addSubview(separatorLine)
        }
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        radioIcon.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        // Styling
        titleLabel.text = text
        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0
        
        separatorLine.backgroundColor = UIColor.systemGray5
        
        radioIcon.contentMode = .scaleAspectFit
        radioIcon.tintColor = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1) // Match top gradient color
        
        updateAppearance() // Set initial icon state
        
        // Build Constraints Array
        var constraints: [NSLayoutConstraint] = [
            // Container fills the view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56), // Minimum hit height
            
            // Radio Icon (Left)
            radioIcon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            radioIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            radioIcon.widthAnchor.constraint(equalToConstant: 24),
            radioIcon.heightAnchor.constraint(equalToConstant: 24),
            
            // Label (Right of icon)
            titleLabel.leadingAnchor.constraint(equalTo: radioIcon.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ]
        
        // Only add separator constraints if it was added to the view
        if showSeparator {
            constraints.append(contentsOf: [
                separatorLine.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), // Indented separator
                separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
                separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
                separatorLine.heightAnchor.constraint(equalToConstant: 1)
            ])
        }
        
        // Activate all valid constraints
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tap)
        containerView.isUserInteractionEnabled = true
    }
    
    @objc private func handleTap() {
        onSelect?()
    }
    
    private func updateAppearance() {
        if isSelectedOption {
            // CHANGED: Use 'circle.inset.filled' for standard Radio Button look
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            radioIcon.image = UIImage(systemName: "circle.inset.filled", withConfiguration: config)
            radioIcon.tintColor = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
        } else {
            // Empty Gray Circle
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .light)
            radioIcon.image = UIImage(systemName: "circle", withConfiguration: config)
            radioIcon.tintColor = .systemGray3
        }
    }
}
