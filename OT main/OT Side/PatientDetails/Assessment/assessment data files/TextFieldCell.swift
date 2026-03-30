//
//  TextFieldCell.swift
//  AssesmentThera
//
//  Created by user@54 on 25/11/25.
//

import UIKit

final class TextFieldCell: UITableViewCell, UITextFieldDelegate {
    static let identifier = "TextFieldCell"

    private let cellContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.masksToBounds = true
        return v
    }()

    let textField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .none
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.textColor = .label
        tf.clearButtonMode = .whileEditing
        return tf
    }()

    private let separator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setup()
        textField.delegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        textField.delegate = self
    }

    private func setup() {
        contentView.addSubview(cellContainer)
        cellContainer.addSubview(textField)
        cellContainer.addSubview(separator)

        NSLayoutConstraint.activate([
            cellContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cellContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            cellContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cellContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            textField.leadingAnchor.constraint(equalTo: cellContainer.leadingAnchor, constant: 18),
            textField.trailingAnchor.constraint(equalTo: cellContainer.trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: cellContainer.topAnchor, constant: 14),
            textField.bottomAnchor.constraint(equalTo: cellContainer.bottomAnchor, constant: -14),

            separator.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: cellContainer.trailingAnchor, constant: -8),
            separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
            separator.bottomAnchor.constraint(equalTo: cellContainer.bottomAnchor)
        ])
    }

    /// Set placeholder text
    func configure(placeholder: String, value: String?) {
        textField.placeholder = placeholder
        textField.text = value
    }

    func showSeparator(_ show: Bool) {
        separator.isHidden = !show
    }

    func setRoundedCorners(isFirst: Bool, isLast: Bool, cornerRadius: CGFloat = 14) {
        cellContainer.layer.cornerRadius = 0
        cellContainer.layer.maskedCorners = []

        if isFirst && isLast {
            cellContainer.layer.cornerRadius = cornerRadius
            cellContainer.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner
            ]
        } else if isFirst {
            cellContainer.layer.cornerRadius = cornerRadius
            cellContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast {
            cellContainer.layer.cornerRadius = cornerRadius
            cellContainer.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            cellContainer.layer.cornerRadius = 0
            cellContainer.layer.maskedCorners = []
        }
    }

    // expose first responder
    func becomeTextFieldFirstResponder() {
        textField.becomeFirstResponder()
    }
}
