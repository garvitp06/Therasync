import UIKit

final class PatientCell: UITableViewCell {

    static let identifier = "PatientCell"

    // MARK: - UI Components
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .black
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let detailLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1.0)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
        selectionStyle = .none
        backgroundColor = .white
        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(divider)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 48),
            avatarImageView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -44),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),

            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -44),
            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),

            divider.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            divider.heightAnchor.constraint(equalToConstant: 1.0),
            divider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
    }

    // MARK: - Configure Logic
    func configure(with patient: Patient) {
        nameLabel.text = patient.fullName
        
        // 1. Safe Age/Gender Calculation
        let age = patient.age
        let gender = patient.gender ?? "N/A"
        detailLabel.text = "Gender: \(gender)   Age: \(age)"
        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.tintColor = .systemGray4
        // --------------------------------------------

        // 2. Load Remote Image from URL
        if let urlString = patient.imageURL, let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        // Only update if the cell hasn't been reused for another patient yet
                        self?.avatarImageView.image = image
                    }
                }
            }.resume()
        } else if let localImg = patient.profileImage {
            avatarImageView.image = localImg
        }
    }

    func showDivider(_ show: Bool) {
        divider.isHidden = !show
    }
}
