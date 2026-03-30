import UIKit

class AppointmentTableViewCell: UITableViewCell {
    
    static let identifier = "AppointmentTableViewCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .systemBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with appointment: Appointment) {
        var content = defaultContentConfiguration()
        
        content.text = appointment.title
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeStr = timeFormatter.string(from: appointment.date)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let dateStr = dateFormatter.string(from: appointment.date)
        
        content.secondaryText = "\(dateStr) • \(timeStr)"
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
        content.secondaryTextProperties.color = .secondaryLabel
        
        content.image = UIImage(systemName: "calendar.badge.clock")
        content.imageProperties.tintColor = .systemBlue
        
        self.contentConfiguration = content
    }
}
