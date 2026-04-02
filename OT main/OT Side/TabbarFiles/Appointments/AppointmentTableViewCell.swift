import UIKit

// ✅ Renamed the protocol method to reflect the new behavior
protocol AppointmentCellDelegate: AnyObject {
    func didTapCell(for appointment: Appointment)
}

class AppointmentTableViewCell: UITableViewCell {
    
    static let identifier = "AppointmentTableViewCell"
    
    weak var delegate: AppointmentCellDelegate?
    private var appointment: Appointment?
    
    // MARK: - UI Elements
    
    /// Circle with initials or profile image
    private let avatarView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 22
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()
    
    private let initialsLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    /// Patient name (bold)
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    /// Appointment title (e.g. "Consultation")
    private let appointmentTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    /// Time label with clock icon
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    /// Status badge (Scheduled / Completed / Cancelled)
    private let statusBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textAlignment = .center
        l.layer.cornerRadius = 12
        l.layer.masksToBounds = true
        l.layer.borderWidth = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    /// Chevron button (Now just a visual indicator)
    private let chevronButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        b.tintColor = .tertiaryLabel
        b.translatesAutoresizingMaskIntoConstraints = false
        // ✅ Disabled interaction so the tap passes through to the cell
        b.isUserInteractionEnabled = false
        return b
    }()
    
    /// Vertical stack for name + title + time
    private let textStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 2
        sv.alignment = .leading
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .default // ✅ Changed back to default so users see a gray highlight when tapping
        self.backgroundColor = .systemBackground
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        contentView.addSubview(avatarView)
        avatarView.addSubview(initialsLabel)
        avatarView.addSubview(avatarImageView)
        
        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(appointmentTitleLabel)
        textStack.addArrangedSubview(timeLabel)
        contentView.addSubview(textStack)
        
        contentView.addSubview(statusBadge)
        contentView.addSubview(chevronButton)
        
        // ✅ Removed the chevron target action
        
        NSLayoutConstraint.activate([
            // Avatar
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 44),
            avatarView.heightAnchor.constraint(equalToConstant: 44),
            
            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),
            
            // Text stack
            textStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: statusBadge.leadingAnchor, constant: -8),
            
            // Chevron
            chevronButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            chevronButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronButton.widthAnchor.constraint(equalToConstant: 24),
            chevronButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Status badge
            statusBadge.trailingAnchor.constraint(equalTo: chevronButton.leadingAnchor, constant: -4),
            statusBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusBadge.heightAnchor.constraint(equalToConstant: 24),
            statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
        ])
        
        // Add padding inside the badge
        statusBadge.setContentHuggingPriority(.required, for: .horizontal)
    }

    /// Call this to hide the right chevron (e.g. for parent-side read-only cells)
    func hideChevron() {
        chevronButton.isHidden = true
    }
    
    // MARK: - Configure
    
    func configure(with appointment: Appointment) {
        self.appointment = appointment
        
        // --- Patient Name ---
        let patientName: String
        if let patient = appointment.patient {
            patientName = "\(patient.firstName) \(patient.lastName)"
        } else {
            patientName = "Patient"
        }
        nameLabel.text = patientName
        
        // --- Appointment Title ---
        appointmentTitleLabel.text = appointment.title
        
        // --- Date & Time ---
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "MMM d, yyyy • h:mm a"
        let dateTimeStr = dateTimeFormatter.string(from: appointment.date)
        
        let attachment = NSTextAttachment()
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 11, weight: .regular)
        attachment.image = UIImage(systemName: "calendar.badge.clock", withConfiguration: iconConfig)?
            .withTintColor(.tertiaryLabel, renderingMode: .alwaysOriginal)
        let dateTimeString = NSMutableAttributedString(attachment: attachment)
        dateTimeString.append(NSAttributedString(string: " \(dateTimeStr)"))
        timeLabel.attributedText = dateTimeString
        
        // --- Avatar ---
        setupAvatar(for: appointment)
        
        // --- Status Badge ---
        configureStatusBadge(appointment: appointment)
    }
    
    private func setupAvatar(for appointment: Appointment) {
        if let patient = appointment.patient,
           let urlString = patient.imageURL,
           let url = URL(string: urlString) {
            // Has a profile image — load it
            avatarImageView.isHidden = false
            initialsLabel.isHidden = true
            avatarView.backgroundColor = .clear
            loadImage(from: url)
        } else {
            // Show initials
            avatarImageView.isHidden = true
            initialsLabel.isHidden = false
            
            let initials: String
            if let patient = appointment.patient {
                let first = patient.firstName.prefix(1).uppercased()
                let last = patient.lastName.prefix(1).uppercased()
                initials = "\(first)\(last)"
            } else {
                initials = "?"
            }
            initialsLabel.text = initials
            avatarView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.7)
        }
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.avatarImageView.image = image
            }
        }.resume()
    }
    
    private func configureStatusBadge(appointment: Appointment) {
        let statusStr = appointment.status.lowercased()
        let isFuture = appointment.date >= Date()
        
        var displayStatus = "Upcoming" // Default for future
        var color: UIColor = .systemBlue
        
        if statusStr == "completed" {
            displayStatus = "Completed"
            color = .systemGreen
        } else if statusStr == "cancelled" {
            displayStatus = "Cancelled"
            color = .systemRed
        } else if statusStr == "rescheduled" {
            displayStatus = "Rescheduled"
            color = .systemOrange
        } else if statusStr == "scheduled" || statusStr == "confirmed" {
            if isFuture {
                displayStatus = "Upcoming"
                color = .systemBlue
            } else {
                displayStatus = "Pending"
                color = .systemGray
            }
        } else {
            // Fallback to literal status word if it's something unexpected
            displayStatus = appointment.status.capitalized
            color = .systemGray
        }

        statusBadge.text = "  \(displayStatus)  "
        statusBadge.textColor = color
        statusBadge.backgroundColor = color.withAlphaComponent(0.1)
        statusBadge.layer.borderColor = color.withAlphaComponent(0.3).cgColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        appointmentTitleLabel.text = nil
        timeLabel.attributedText = nil
        statusBadge.text = nil
        avatarImageView.image = nil
        avatarImageView.isHidden = true
        initialsLabel.isHidden = false
        appointment = nil
    }
}
