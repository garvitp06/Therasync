import UIKit

class patientcellList: UITableViewCell {

    static let identifier = "PatientCell"
    
    // MARK: - UI Elements
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .center // Center the symbol
        imageView.layer.cornerRadius = 30 // 60 / 2
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.tintColor = .systemGray4
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCellUI()
        self.accessoryType = .disclosureIndicator
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupCellUI() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(detailsLabel)
        
        NSLayoutConstraint.activate([
            // Profile Image Constraints
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Name Label Constraints
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 8),
            
            // Details Label Constraints
            detailsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailsLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            detailsLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
        ])
    }
    
    // MARK: - Public Configuration
    
    public func configure(with patient: Patient) {
        nameLabel.text = patient.firstName+" "+patient.lastName
        detailsLabel.text = "Gender: \(patient.gender)  Age: \(patient.age)"
        
        // Set a large generic person icon
        let config = UIImage.SymbolConfiguration(pointSize: 30)
        profileImageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        detailsLabel.text = nil
        profileImageView.image = nil
    }
}
