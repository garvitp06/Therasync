import UIKit

final class QuickAccessCard: UIControl {

    init(title: String, count: String?, systemIcon: String, color: UIColor) {
        super.init(frame: .zero)
        
        // Use the custom 'darker' helper to adjust background for Dark Mode
        self.backgroundColor = UIColor { trait in
            let isManualDark = UserDefaults.standard.bool(forKey: "Dark Mode")
            return isManualDark ? color.darker(by: 20) : color
        }
        
        layer.cornerRadius = 20

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: systemIcon)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let countLabel = UILabel()
        countLabel.text = count
        countLabel.textColor = .white
        countLabel.font = .systemFont(ofSize: 18, weight: .bold)
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        [iconImageView, titleLabel, countLabel].forEach { addSubview($0) }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 80),

            // Icon positioning (Top Left)
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            // Title positioning (Bottom Left)
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            // Count positioning (Top Right)
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            countLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UIColor Extension (Fixes the "No darker" error)
extension UIColor {
    func darker(by percentage: CGFloat = 20.0) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return UIColor(red: max(r - percentage/100, 0),
                           green: max(g - percentage/100, 0),
                           blue: max(b - percentage/100, 0),
                           alpha: a)
        }
        return self
    }
}
