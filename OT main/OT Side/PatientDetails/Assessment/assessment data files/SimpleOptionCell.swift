//
//  SimpleOptionCell.swift
//  AssesmentThera
//
//  Created by user@54 on 25/11/25.
//

import UIKit

final class SimpleOptionCell: UITableViewCell {
    static let identifier = "SimpleOptionCell"

    private let cellContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        v.layer.masksToBounds = true
        return v
    }()

    let optionLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = UIColor(white: 0.45, alpha: 1.0) // muted grey like your screenshots
        l.numberOfLines = 1
        return l
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
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.addSubview(cellContainer)
        cellContainer.addSubview(optionLabel)
        cellContainer.addSubview(separator)

        NSLayoutConstraint.activate([
            cellContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cellContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            cellContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cellContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            optionLabel.leadingAnchor.constraint(equalTo: cellContainer.leadingAnchor, constant: 18),
            optionLabel.trailingAnchor.constraint(equalTo: cellContainer.trailingAnchor, constant: -16),
            optionLabel.topAnchor.constraint(equalTo: cellContainer.topAnchor, constant: 14),
            optionLabel.bottomAnchor.constraint(equalTo: cellContainer.bottomAnchor, constant: -14),

            separator.leadingAnchor.constraint(equalTo: optionLabel.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: cellContainer.trailingAnchor, constant: -8),
            separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
            separator.bottomAnchor.constraint(equalTo: cellContainer.bottomAnchor)
        ])
    }

    func showSeparator(_ show: Bool) {
        separator.isHidden = !show
    }

    /// Round corners depending on row position
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
}

