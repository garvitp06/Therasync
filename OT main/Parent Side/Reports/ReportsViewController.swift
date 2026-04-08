import UIKit
import Supabase

// MARK: - 1. Local Data Model
struct ParentReportModel {
    let date: Date
    let assessments: [AssessmentLogResponse]
    let submission: AssignmentSubmission?
    
    var summaryText: String {
        var parts: [String] = []
        if !assessments.isEmpty {
            let types = assessments.map { $0.assessment_type }.joined(separator: ", ")
            parts.append(types)
        }
        if submission != nil {
            parts.append("Home Assignment")
        }
        return parts.isEmpty ? "No Activity" : parts.joined(separator: " + ")
    }
}

// MARK: - 2. View Controller
final class ReportsViewController: UIViewController {

    // MARK: - Properties
    private var linkedPatient: Patient?
    private var reportGroups: [ParentReportModel] = []
    private var isLoading = false
    
    // MARK: - UI Components
    private let backgroundView: ParentGradientView = {
        let v = ParentGradientView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .clear
        tv.separatorStyle = .singleLine
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 80, right: 0)
        return tv
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    private let emptyStateLabel: UILabel = {
            let l = UILabel()
            l.text = "No reports available yet."
            l.textColor = .label
            l.font = .systemFont(ofSize: 18, weight: .medium)
            l.textAlignment = .center
            l.numberOfLines = 0
            l.isHidden = true
            l.translatesAutoresizingMaskIntoConstraints = false
            return l
        }()

    // MARK: - Initializers
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Reports"
        navigationItem.largeTitleDisplayMode = .always
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = true
        tabBarController?.tabBar.isHidden = false

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .label

        tableView.setContentOffset(.zero, animated: false)

        // Always verify we are showing the RIGHT child when the view appears
        let savedIDNum = UserDefaults.standard.string(forKey: "LastSelectedChildID")
        if linkedPatient == nil || linkedPatient?.patientID != savedIDNum {
            findLinkedChildAndFetchReports()
        } else if !isLoading {
            // Already matched, but refresh content if not loading
            if let pid = linkedPatient?.patientID {
                Task { await fetchReports(for: pid) }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(activityIndicator)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ParentReportsCell.self, forCellReuseIdentifier: ParentReportsCell.identifier)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor, constant: -20)
        ])
        
        if #available(iOS 13.0, *) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                tableView.cellLayoutMarginsFollowReadableWidth = true
            }
        }
    }
    
    private func findLinkedChildAndFetchReports() {
        guard let user = supabase.auth.currentUser else { return }
        
        isLoading = true
        activityIndicator.startAnimating()
        
        Task {
            do {
                // NEW: Use the specifically selected child's ID from UserDefaults if available
                let savedIDNum = UserDefaults.standard.string(forKey: "LastSelectedChildID")

                let response = try await supabase
                    .from("patients")
                    .select()
                    .eq("parent_uid", value: user.id)
                    .execute()
                
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                decoder.dateDecodingStrategy = .formatted(formatter)
                
                let patients = try decoder.decode([Patient].self, from: response.data)
                
                // Prioritize matching the savedIDNum
                if let child = patients.first(where: { $0.patientID == savedIDNum }) ?? patients.first {
                    self.linkedPatient = child
                    await fetchReports(for: child.patientID)
                } else {
                    await showEmptyState(message: "No child profile linked to this account.")
                }
            } catch {
                print("❌ Find Child Error: \(error)")
                await showEmptyState(message: "Check your connection or RLS permissions.")
            }
        }
    }

    private func fetchReports(for patientID: String) async {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let assesResponse = try await supabase
                .from("assessments")
                .select()
                .eq("patient_id", value: patientID)
                .order("created_at", ascending: false)
                .execute()
                
            let asses = try decoder.decode([AssessmentLogResponse].self, from: assesResponse.data)
            
            let subsResponse = try await supabase
                .from("assignment_submissions")
                .select()
                .eq("patient_id", value: patientID)
                .order("submitted_at", ascending: false)
                .execute()
                
            let subs = try decoder.decode([AssignmentSubmission].self, from: subsResponse.data)
            
            let calendar = Calendar.current
            var allDates = Set<Date>()
            
            asses.forEach { allDates.insert(calendar.startOfDay(for: $0.created_at)) }
            subs.forEach { if let date = $0.submitted_at { allDates.insert(calendar.startOfDay(for: date)) } }
            
            let sortedDates = allDates.sorted(by: >)
            var finalReports: [ParentReportModel] = []
            
            for date in sortedDates {
                let dayAssessments = asses.filter { calendar.isDate($0.created_at, inSameDayAs: date) }
                let dayAssignment = subs.first {
                    guard let subDate = $0.submitted_at else { return false }
                    return calendar.isDate(subDate, inSameDayAs: date)
                }
                
                if !dayAssessments.isEmpty || dayAssignment != nil {
                    finalReports.append(ParentReportModel(
                        date: date,
                        assessments: dayAssessments,
                        submission: dayAssignment
                    ))
                }
            }
            
            await MainActor.run {
                self.reportGroups = finalReports
                self.isLoading = false
                self.activityIndicator.stopAnimating()
                
                let hasData = !finalReports.isEmpty
                self.tableView.isHidden = !hasData
                self.emptyStateLabel.isHidden = hasData
                self.tableView.reloadData()
            }
            
        } catch {
            print("❌ Fetch error: \(error)")
            await showEmptyState(message: "Failed to load clinical data.")
        }
    }
    @MainActor
    private func showEmptyState(message: String) {
        self.isLoading = false
        self.activityIndicator.stopAnimating()
        self.emptyStateLabel.text = message
        self.emptyStateLabel.isHidden = false
        self.tableView.isHidden = true
    }
}

// MARK: - 3. TableView Logic
extension ReportsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reportGroups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParentReportsCell.identifier, for: indexPath) as? ParentReportsCell else {
            return UITableViewCell()
        }
        
        let report = reportGroups[indexPath.row]
        cell.configure(with: report)
        cell.onTapDownload = { [weak self] in
            self?.generateAndSharePDF(for: report)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let report = reportGroups[indexPath.row]
        
        let detailVC = ReportDetailViewController()
        detailVC.isParentSide = true // Set theme flag
        detailVC.patient = self.linkedPatient
        detailVC.reportDate = report.date
        detailVC.assessments = report.assessments
        detailVC.submission = report.submission
        detailVC.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 92
    }
    
    private func generateAndSharePDF(for report: ParentReportModel) {
        let pdfGen = ReportDetailViewController()
        pdfGen.isParentSide = true // Set theme flag for drawing logic (color matching)
        pdfGen.patient = self.linkedPatient
        pdfGen.reportDate = report.date
        pdfGen.assessments = report.assessments
        pdfGen.submission = report.submission
        
        let pdfData = pdfGen.generateProfessionalPDF()
        
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: report.date)
        let fileName = "Report_\(linkedPatient?.firstName ?? "Child")_\(dateStr).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: tempURL)
            let shareSheet = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            // FIXED: Handle iPad presentation crash
            if let popover = shareSheet.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            present(shareSheet, animated: true)
        } catch {
            print("PDF Error: \(error)")
        }
    }
}

// MARK: - 4. Unique Custom Cell
class ParentReportsCell: UITableViewCell {
    static let identifier = "ParentReportsCell"
    var onTapDownload: (() -> Void)?
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 26
        v.layer.shadowColor = UIColor.label.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let iconContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        v.layer.cornerRadius = 10
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "doc.text.fill")
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let summaryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var downloadButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        btn.setImage(UIImage(systemName: "arrow.down.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .systemBlue
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(didTapDownload), for: .touchUpInside)
        return btn
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupLayout()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupLayout() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        containerView.addSubview(dateLabel)
        containerView.addSubview(summaryLabel)
        containerView.addSubview(downloadButton)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            iconContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            dateLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            dateLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -8),
            
            summaryLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            summaryLabel.leadingAnchor.constraint(equalTo: dateLabel.leadingAnchor),
            summaryLabel.trailingAnchor.constraint(equalTo: dateLabel.trailingAnchor),
            
            downloadButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            downloadButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: 44),
            downloadButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func configure(with report: ParentReportModel) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        dateLabel.text = formatter.string(from: report.date)
        summaryLabel.text = report.summaryText
    }
    
    @objc private func didTapDownload() {
        onTapDownload?()
    }
}
