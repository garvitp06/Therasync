//
//  RadioOptionCell.swift
//  AssesmentThera
//
//  Created by user@54 on 21/11/25.
//

import UIKit

final class RadioOptionCell: UITableViewCell {
    static let identifier = "RadioOptionCell"

    // MARK: - Subviews
    private let outerCircle: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 14
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.systemGray4.cgColor
        v.backgroundColor = .clear
        return v
    }()

    private let innerDot: UIView = {
        let d = UIView()
        d.translatesAutoresizingMaskIntoConstraints = false
        d.layer.cornerRadius = 8
        d.backgroundColor = .systemBlue
        d.isHidden = true
        return d
    }()

    let optionLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 0
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.textColor = .label
        return lbl
    }()

    private let separator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .separator
        return v
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.outerCircle.layer.borderColor = (self.innerDot.isHidden ? UIColor.systemGray4 : UIColor.systemBlue).resolvedColor(with: self.traitCollection).cgColor
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        contentView.addSubview(outerCircle)
        outerCircle.addSubview(innerDot)
        contentView.addSubview(optionLabel)
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            outerCircle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            outerCircle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            outerCircle.widthAnchor.constraint(equalToConstant: 28),
            outerCircle.heightAnchor.constraint(equalToConstant: 28),

            innerDot.centerXAnchor.constraint(equalTo: outerCircle.centerXAnchor),
            innerDot.centerYAnchor.constraint(equalTo: outerCircle.centerYAnchor),
            innerDot.widthAnchor.constraint(equalToConstant: 16),
            innerDot.heightAnchor.constraint(equalToConstant: 16),

            optionLabel.leadingAnchor.constraint(equalTo: outerCircle.trailingAnchor, constant: 14),
            optionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            optionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            optionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),

            // separator inset from left so it doesn't touch the outer left card corner
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
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


    /// Hide separator for last cell (to keep bottom rounded card look)
    func showSeparator(_ show: Bool) {
        separator.isHidden = !show
    }
}
