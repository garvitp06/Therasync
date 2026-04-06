import UIKit
import Supabase

// MARK: - Data Model for Grouping
struct DailyReport {
    let date: Date
    let assessments: [AssessmentLogResponse]
    let latestAssignment: AssignmentSubmission?
}

class PatientProgressViewController: UIViewController {
    var patient: Patient?
    private var dailyReports: [DailyReport] = []
    
    // Transparent table to show GradientView behind it
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .clear
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "Complete assessment and assignment to show reports"
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.numberOfLines = 0
        l.textAlignment = .center
        l.textColor = .white.withAlphaComponent(0.9) // White text for gradient
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Use GradientView
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Progress Reports"
        setupNavBar()
        setupUI()
        fetchAndGroupData()
    }
    
    private func setupNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReportCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func fetchAndGroupData() {
        guard let pID = patient?.patientID else { return }
        
        Task {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                // 1. Fetch Data
                // Ensure your AssessmentLogResponse struct has 'created_at'
                let asses: [AssessmentLogResponse] = try await supabase
                    .from("assessments")
                    .select("id, assessment_type, assessment_data, created_at")
                    .eq("patient_id", value: pID)
                    .order("created_at", ascending: false)
                    .execute().value
                
                let subs: [AssignmentSubmission] = try await supabase
                    .from("assignment_submissions")
                    .select()
                    .eq("patient_id", value: pID)
                    .order("submitted_at", ascending: false)
                    .execute().value
                
                // 2. Group Assessments by Date
                var grouped: [Date: [AssessmentLogResponse]] = [:]
                let calendar = Calendar.current
                
                for item in asses {
                    let startOfDay = calendar.startOfDay(for: item.created_at)
                    var list = grouped[startOfDay] ?? []
                    list.append(item)
                    grouped[startOfDay] = list
                }
                
                // 3. Create Unified Reports
                var finalReports: [DailyReport] = []
                let sortedDates = grouped.keys.sorted(by: >)
                
                for date in sortedDates {
                    // Find assignment submitted on or before this day (within 24 hours)
                    let relevantAssignment = subs.first { ($0.submitted_at ?? Date()) <= date.addingTimeInterval(86400) }
                    
                    let report = DailyReport(
                        date: date,
                        assessments: grouped[date] ?? [],
                        latestAssignment: relevantAssignment
                    )
                    finalReports.append(report)
                }
                
                await MainActor.run {
                    self.dailyReports = finalReports
                    let hasData = !finalReports.isEmpty
                    self.tableView.isHidden = !hasData
                    self.emptyLabel.isHidden = hasData
                    self.tableView.reloadData()
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

extension PatientProgressViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dailyReports.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let report = dailyReports[indexPath.row]
        
        // Reuse or create a custom card cell
        let reuseID = "ReportCardCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseID)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: reuseID)
        }
        guard let cell = cell else { return UITableViewCell() }
        
        cell.backgroundColor = .systemBackground
        cell.layer.cornerRadius = 14
        cell.clipsToBounds = true
        cell.selectionStyle = .none
        
        // Date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        cell.textLabel?.text = formatter.string(from: report.date)
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cell.textLabel?.textColor = .label
        
        // Summary
        let assessmentNames = report.assessments.map { $0.assessment_type }.joined(separator: ", ")
        let assignmentText = report.latestAssignment != nil ? " + Assignment" : ""
        let summaryText = assessmentNames.isEmpty ? "Assignment" : "\(assessmentNames)\(assignmentText)"
        cell.detailTextLabel?.text = summaryText
        cell.detailTextLabel?.textColor = .systemGray
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        
        // Icon
        let iconView = UIImageView(image: UIImage(systemName: "doc.text.fill"))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        cell.imageView?.image = UIImage(systemName: "doc.text.fill")
        cell.imageView?.tintColor = .systemBlue
        
        // Download button
        let downloadBtn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        downloadBtn.setImage(UIImage(systemName: "arrow.down.circle.fill", withConfiguration: config), for: .normal)
        downloadBtn.tintColor = .systemBlue
        downloadBtn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        downloadBtn.tag = indexPath.row
        downloadBtn.addTarget(self, action: #selector(downloadPDFTapped(_:)), for: .touchUpInside)
        cell.accessoryView = downloadBtn
        
        return cell
    }
    
    @objc private func downloadPDFTapped(_ sender: UIButton) {
        let report = dailyReports[sender.tag]
        
        let pdfGenerator = ReportDetailViewController()
        pdfGenerator.patient = self.patient
        pdfGenerator.reportDate = report.date
        pdfGenerator.assessments = report.assessments
        pdfGenerator.submission = report.latestAssignment
        
        let pdfData = pdfGenerator.generateProfessionalPDF()
        
        // Filename: "Report_Garvit_2026-02-05.pdf"
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: report.date)
        let fileName = "Report_\(patient?.firstName ?? "Patient")_\(dateStr).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: tempURL)
            let vc = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            present(vc, animated: true)
        } catch {
            print("PDF Write Error: \(error)")
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let report = dailyReports[indexPath.row]
        let detailVC = ReportDetailViewController()
        
        detailVC.assessments = report.assessments
        detailVC.submission = report.latestAssignment
        detailVC.patient = patient
        detailVC.reportDate = report.date
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
