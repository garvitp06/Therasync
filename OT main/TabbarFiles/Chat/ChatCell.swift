//
//  ChatCell.swift
//  Screens1
//
//  Created by user@54 on 17/11/25.
//

import UIKit

class ChatCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Avatar
        avatarImageView.layer.cornerRadius = 30
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = .clear

        // Ensure labels have clear backgrounds and correct system colors
        nameLabel.backgroundColor = .clear
        nameLabel.font = .systemFont(ofSize: 17)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail

        messageLabel.backgroundColor = .clear
        messageLabel.font = .systemFont(ofSize: 11)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 1
        messageLabel.lineBreakMode = .byTruncatingTail

        timeLabel.backgroundColor = .clear
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .secondaryLabel
        timeLabel.textAlignment = .right

        // Content view / cell background
        backgroundColor = .clear
        contentView.backgroundColor = .systemBackground
        selectionStyle = .none
    }

    func configure(with model: ChatSummary) {
        avatarImageView.image = model.avatar ?? UIImage(named: "avatar_placeholder")
        nameLabel.text = model.name
        messageLabel.text = model.message
        timeLabel.text = model.time
    }
}
