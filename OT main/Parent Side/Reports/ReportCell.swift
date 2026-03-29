//
//  ReportCell.swift
//  OT main
//
//  Created by Garvit Pareek on 05/02/2026.
//


import UIKit

class ReportCell: UITableViewCell {
    static let identifier = "ReportCell"
    
    var onTapDownload: (() -> Void)?
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white.withAlphaComponent(0.9)
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let iconContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "doc.plaintext.fill")
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .black
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    let summaryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .darkGray
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var downloadButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        btn.setImage(UIImage(systemName: "arrow.down.doc.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .systemBlue
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(didTapDownload), for: .touchUpInside)
        return btn
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.selectionStyle = .none
        setupLayout()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Layout Setup
    private func setupLayout() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        containerView.addSubview(dateLabel)
        containerView.addSubview(summaryLabel)
        containerView.addSubview(downloadButton)
        
        NSLayoutConstraint.activate([
            // Container Padding
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Icon
            iconContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 48),
            iconContainer.heightAnchor.constraint(equalToConstant: 48),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Labels
            dateLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            dateLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -8),
            
            summaryLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            summaryLabel.leadingAnchor.constraint(equalTo: dateLabel.leadingAnchor),
            summaryLabel.trailingAnchor.constraint(equalTo: dateLabel.trailingAnchor),
            summaryLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -14),
            
            // Download Button
            downloadButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            downloadButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: 44),
            downloadButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Configuration
    func configure(with report: DailyReport) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        dateLabel.text = "Report - \(formatter.string(from: report.date))"
        
        let assessmentNames = report.assessments.map { $0.assessment_type }.joined(separator: ", ")
        let assignmentText = report.latestAssignment != nil ? " + Assignment" : ""
        
        if assessmentNames.isEmpty && assignmentText.isEmpty {
            summaryLabel.text = "No clinical activity recorded."
        } else {
            summaryLabel.text = "\(assessmentNames)\(assignmentText)"
        }
    }
    
    @objc private func didTapDownload() {
        onTapDownload?()
    }
}