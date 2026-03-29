import UIKit

class ChatCell: UITableViewCell {
    
    static let identifier = "ChatCell"
    
    // MARK: - UI Components
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 24
        iv.layer.masksToBounds = true
        iv.backgroundColor = .systemGray6
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = .systemGray3
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .systemGray
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray2
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let unreadBadgeContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.14, green: 0.80, blue: 0.38, alpha: 1.0)
        v.layer.cornerRadius = 11
        v.layer.masksToBounds = true
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let unreadCountLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 11, weight: .bold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Setup UI
    private func setupUI() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(unreadBadgeContainer)
        unreadBadgeContainer.addSubview(unreadCountLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 48),
            avatarImageView.heightAnchor.constraint(equalToConstant: 48),
            
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 2),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            unreadBadgeContainer.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 6),
            unreadBadgeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            unreadBadgeContainer.heightAnchor.constraint(equalToConstant: 22),
            unreadBadgeContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 22),
            
            unreadCountLabel.centerXAnchor.constraint(equalTo: unreadBadgeContainer.centerXAnchor),
            unreadCountLabel.centerYAnchor.constraint(equalTo: unreadBadgeContainer.centerYAnchor),
            unreadCountLabel.leadingAnchor.constraint(equalTo: unreadBadgeContainer.leadingAnchor, constant: 6),
            unreadCountLabel.trailingAnchor.constraint(equalTo: unreadBadgeContainer.trailingAnchor, constant: -6),
            
            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -90)
        ])
    }
    
    // MARK: - Configuration
    func configure(with chat: ChatSummary) {
        nameLabel.text = chat.name
        messageLabel.text = chat.message
        timeLabel.text = chat.time
        
        // 1. Reset for Cell Reuse
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .systemGray3
        
        // 2. Load Remote Image from URL (Assuming avatarURL exists in ChatSummary)
        if let urlString = chat.avatarURL, let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.avatarImageView.image = image
                    }
                }
            }.resume()
        } else if let localImage = chat.avatar {
            // Fallback to local UIImage if URL is missing
            avatarImageView.image = localImage
        }
        
        // 3. Handle Unread Logic
        if chat.unreadCount > 0 {
            unreadBadgeContainer.isHidden = false
            unreadCountLabel.text = "\(chat.unreadCount)"
            timeLabel.textColor = UIColor(red: 0.14, green: 0.80, blue: 0.38, alpha: 1.0)
            timeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
            messageLabel.textColor = .black
        } else {
            unreadBadgeContainer.isHidden = true
            timeLabel.textColor = .systemGray2
            timeLabel.font = .systemFont(ofSize: 12, weight: .regular)
            messageLabel.textColor = .systemGray
        }
    }
} 
