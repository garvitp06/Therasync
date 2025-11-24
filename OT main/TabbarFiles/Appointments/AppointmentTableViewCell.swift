//
// AppointmentCell.swift
// Trial
//
// Slight tweak: wider accent and more rounded left shape to match Figma.
// Keep your XIB content as is — only paste this file to update styling logic.
//

import UIKit

final class AppointmentTableViewCell: UITableViewCell {

    @IBOutlet weak var accentView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Accent bar on left — wider and rounded on both top and bottom left to match Figma
        accentView.backgroundColor = UIColor(named: "#F4A320")
        accentView.layer.cornerRadius = 12
        accentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        accentView.clipsToBounds = true

        // labels
        timeLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = UIColor(white: 0.5, alpha: 1)

        // contentView: give a subtle white background if you want individual row cards,
        // but we prefer transparent rows sitting on tableBackgroundCard, so keep clear.
        contentView.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        timeLabel.text = nil
        titleLabel.text = nil
        dateLabel.text = nil
    }

    func configure(time: String, title: String, date: String) {
        timeLabel.text = time
        titleLabel.text = title
        dateLabel.text = date
    }
}
