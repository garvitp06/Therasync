//
//  RadioOptionView.swift
//  PatientDifficulties
//
//  Created by Alishri Poddar on 26/11/25.
//

import UIKit

class RadioOptionView: UIControl {

    // MARK: - Subviews (Exact styling from your RadioOptionCell)
    private let outerCircle: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 14 // From your code
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.systemGray4.cgColor
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false // Let the parent view handle touches
        return v
    }()

    private let innerDot: UIView = {
        let d = UIView()
        d.translatesAutoresizingMaskIntoConstraints = false
        d.layer.cornerRadius = 8 // From your code
        d.backgroundColor = .systemBlue
        d.isHidden = true
        d.isUserInteractionEnabled = false
        return d
    }()

    let optionLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 0
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.textColor = .label
        lbl.isUserInteractionEnabled = false
        return lbl
    }()

    private let separator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        v.isUserInteractionEnabled = false
        return v
    }()
    
    // MARK: - Properties
    var isOn: Bool = false {
        didSet {
            setSelectedState(isOn, animated: true)
        }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        
        // Add Tap Gesture so the whole row is clickable
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        self.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Setup (Your exact constraints adapted for UIView)
    private func setupViews() {
        self.backgroundColor = .white // Background for the row
        
        addSubview(outerCircle)
        outerCircle.addSubview(innerDot)
        addSubview(optionLabel)
        addSubview(separator)

        NSLayoutConstraint.activate([
            // Outer Circle
            outerCircle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            outerCircle.centerYAnchor.constraint(equalTo: centerYAnchor),
            outerCircle.widthAnchor.constraint(equalToConstant: 28),
            outerCircle.heightAnchor.constraint(equalToConstant: 28),

            // Inner Dot
            innerDot.centerXAnchor.constraint(equalTo: outerCircle.centerXAnchor),
            innerDot.centerYAnchor.constraint(equalTo: outerCircle.centerYAnchor),
            innerDot.widthAnchor.constraint(equalToConstant: 16),
            innerDot.heightAnchor.constraint(equalToConstant: 16),

            // Label
            optionLabel.leadingAnchor.constraint(equalTo: outerCircle.trailingAnchor, constant: 14),
            optionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            optionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            optionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),

            // Separator
            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 1.0),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func didTapView() {
        sendActions(for: .touchUpInside)
    }

    // MARK: - API
    func setSelectedState(_ selected: Bool, animated: Bool = false) {
        let changes = {
            self.innerDot.isHidden = !selected
            self.outerCircle.layer.borderColor = (selected ? UIColor.systemBlue : UIColor.systemGray4).cgColor
        }
        if animated {
            UIView.animate(withDuration: 0.18, animations: changes)
        } else {
            changes()
        }
    }

    func showSeparator(_ show: Bool) {
        separator.isHidden = !show
    }
}
