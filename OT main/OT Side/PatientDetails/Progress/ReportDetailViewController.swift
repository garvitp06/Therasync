import UIKit
import PDFKit

class ReportDetailViewController: UIViewController {
    
    // Data Variables
    var assessments: [AssessmentLogResponse] = []
    var submission: AssignmentSubmission?
    var patient: Patient?
    var reportDate: Date?
    
    // White Card to hold text (Paper look)
    private let textContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.15
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15)
        tv.isEditable = false
        tv.backgroundColor = .clear // Transparent so it sits on the white card
        tv.textColor = .black
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Use GradientView
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Report Details"
        setupNavBar()
        setupUI()
        generateDisplayText()
    }
    
    private func setupNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }
    
    private func setupUI() {
        view.addSubview(textContainer)
        textContainer.addSubview(textView)
        
        NSLayoutConstraint.activate([
            // Card Layout (Inset from edges)
            textContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Text View fills the card with padding
            textView.topAnchor.constraint(equalTo: textContainer.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor, constant: -16)
        ])
    }
    
    private func generateDisplayText() {
        guard let p = patient else { return }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let dateStr = reportDate != nil ? formatter.string(from: reportDate!) : "Unknown Date"
        
        var content = "CLINICAL PROGRESS REPORT\n"
        content += "Date: \(dateStr)\n"
        content += "Patient: \(p.fullName)\nID: \(p.patientID)\n"
        content += "---------------------------------\n\n"
        
        // 1. Loop through ALL Assessments
        if !assessments.isEmpty {
            for (index, assessment) in assessments.enumerated() {
                content += "[ ASSESSMENT \(index + 1): \(assessment.assessment_type.uppercased()) ]\n"
                if let data = assessment.assessment_data.value as? [String: Any] {
                    for (key, value) in data.sorted(by: { $0.key < $1.key }) {
                        content += "• \(key): \(value)\n"
                    }
                }
                content += "\n"
            }
        } else {
            content += "No clinical assessments recorded for this date.\n\n"
        }
        
        content += "---------------------------------\n\n"
        
        // 2. Add Assignment Data
        if let s = submission {
            content += "[ LATEST ASSIGNMENT SUBMISSION ]\n"
            content += "Score: \(s.score ?? 0)/10\n"
            content += "Remarks: \(s.remarks ?? "None")\n\n"
            content += "Answers:\n"
            for (index, answer) in (s.answers ?? []).enumerated() {
                content += "\(index + 1). \(answer)\n"
            }
        } else {
            content += "No assignment submission linked to this report.\n"
        }
        
        textView.text = content
    }

    // PDF Generation Logic (Called by List View too)
    func generateProfessionalPDF() -> Data {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595.2, height: 841.8))
        
        return pdfRenderer.pdfData { (context) in
            context.beginPage()
            let margin: CGFloat = 45
            let pageWidth = 595.2
            var currentY: CGFloat = margin
            
            // Header
            let titleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 22), .foregroundColor: UIColor.systemBlue]
            "TheraLink Clinical Report".draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttr)
            currentY += 40
            
            // Subheader
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            let dateStr = reportDate != nil ? formatter.string(from: reportDate!) : ""
            let dateAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.darkGray]
            "Date: \(dateStr)".draw(at: CGPoint(x: margin, y: currentY), withAttributes: dateAttr)
            currentY += 30
            
            // Draw Patient Details Box
            let infoRect = CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: 70)
            UIColor.systemGray6.setFill(); UIBezierPath(roundedRect: infoRect, cornerRadius: 8).fill()
            
            let boldFont: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 12)]
            let regFont: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            
            "Patient: \(patient?.fullName ?? "N/A")".draw(at: CGPoint(x: margin + 15, y: currentY + 15), withAttributes: boldFont)
            "ID: \(patient?.patientID ?? "N/A")".draw(at: CGPoint(x: margin + 15, y: currentY + 35), withAttributes: regFont)
            currentY += 100
            
            // Content Body
            let textToDraw = textView.text ?? ""
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6
            let textAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .paragraphStyle: paragraphStyle
            ]
            
            let textRect = CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: 600)
            textToDraw.draw(in: textRect, withAttributes: textAttr)
        }
    }
}
