import UIKit

class NoteCell: UITableViewCell {
    
    static let identifier = "NoteCell"
    
    // MARK: - UI Components
    private let cardView: UIView = {
        let view = UIView()
        // Using standard system secondary background for better dynamic support
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        
        // Adding a subtle shadow to give the "card" depth
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.08
        
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Accessor for the disclosure indicator (the little arrow >)
    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .systemGray3
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(cardView)
        cardView.addSubview(dateLabel)
        cardView.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            // Card Constraints
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Chevron Constraints
            chevronImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Date Label Constraints
            dateLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12)
        ])
    }
    
    // MARK: - Animation for Taps
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.1) {
            self.cardView.transform = highlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            self.cardView.backgroundColor = highlighted ? .systemGray5 : .secondarySystemGroupedBackground
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        // Keeps the shadow path updated for better performance and look
        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: cardView.layer.cornerRadius).cgPath
    }
    // MARK: - Configuration
    func configure(date: String) {
        dateLabel.text = date
        // Note: Using system colors (.label, .secondarySystemGroupedBackground)
        // handles Dark Mode automatically without extra code.
    }
    
    // Inside NoteCell.swift
    func configure(title: String, dateString: String) {
        // Parsing the ISO string to get just the time for the subtitle
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeZone = TimeZone(secondsFromGMT: 19800) // IST +5:30
            timeFormatter.dateFormat = "h:mm a"
            
            // You could add a subtitle label to your cell to show this
            // dateLabel.text = "\(title) • \(timeFormatter.string(from: date))"
            dateLabel.text = title
        } else {
            dateLabel.text = title
        }
    }
}
