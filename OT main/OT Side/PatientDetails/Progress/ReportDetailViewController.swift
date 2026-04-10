import UIKit
import PDFKit

class ReportDetailViewController: UIViewController {
    
    var isParentSide: Bool = false
    
    // Data Variables
    var assessments: [AssessmentLogResponse] = []
    var submission: AssignmentSubmission?
    var patient: Patient?
    var reportDate: Date?
    
    private let textContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
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
        tv.isEditable = false
        tv.isSelectable = false
        tv.backgroundColor = .clear
        tv.textColor = .label
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    // MARK: - Initializers
    init() {
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.hidesBottomBarWhenPushed = true
    }

    // MARK: - Lifecycle
    override func loadView() {
        if isParentSide {
            self.view = ParentGradientView()
        } else {
            self.view = GradientView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Report Details"
        setupUI()
        textView.attributedText = buildAttributedReport()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func setupNavBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Conditional coloring
        let mainColor: UIColor = isParentSide ? .label : .white
        appearance.titleTextAttributes = [.foregroundColor: mainColor]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = mainColor
        
        if isParentSide {
            let backBtn = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(handleBack))
            navigationItem.leftBarButtonItem = backBtn
        }
    }
    
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupUI() {
        view.addSubview(textContainer)
        textContainer.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            textView.topAnchor.constraint(equalTo: textContainer.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Build Attributed String for on-screen display
    private func buildAttributedReport() -> NSAttributedString {
        guard let p = patient else { return NSAttributedString(string: "No patient data.") }
        let full = NSMutableAttributedString()
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let dateStr = reportDate.map { formatter.string(from: $0) } ?? "Unknown Date"
        
        let themeColor: UIColor = isParentSide ? .systemOrange : .systemBlue
        
        // Title
        full.append(styled("CLINICAL PROGRESS REPORT\n", font: .boldSystemFont(ofSize: 20), color: themeColor))
        full.append(styled("TheraSync · \(dateStr)\n\n", font: .systemFont(ofSize: 13), color: .systemGray))
        
        // Patient info box (simulated)
        full.append(styled("PATIENT INFORMATION\n", font: .boldSystemFont(ofSize: 13), color: .systemGray))
        full.append(divider())
        full.append(styled("Name:  ", font: .boldSystemFont(ofSize: 15), color: .black))
        full.append(styled("\(p.fullName)\n", font: .systemFont(ofSize: 15), color: .darkGray))
        full.append(styled("ID:       ", font: .boldSystemFont(ofSize: 15), color: .black))
        full.append(styled("\(p.patientID)\n\n", font: .systemFont(ofSize: 15), color: .darkGray))
        
        // Assessments
        full.append(styled("CLINICAL ASSESSMENTS\n", font: .boldSystemFont(ofSize: 13), color: .systemGray))
        full.append(divider())
        
        if assessments.isEmpty {
            full.append(styled("No assessments recorded for this date.\n\n", font: .italicSystemFont(ofSize: 14), color: .systemGray))
        } else {
            for (i, a) in assessments.enumerated() {
                full.append(styled("Assessment \(i + 1): \(a.assessment_type.uppercased())\n", font: .boldSystemFont(ofSize: 15), color: .black))
                if let data = a.assessment_data.value as? [String: Any] {
                    for (key, value) in data.sorted(by: { $0.key < $1.key }) {
                        full.append(styled("  • \(key):  \(value)\n", font: .systemFont(ofSize: 14), color: .darkGray))
                    }
                }
                full.append(styled("\n", font: .systemFont(ofSize: 8), color: .clear))
            }
        }
        
        // Assignment
        full.append(styled("ASSIGNMENT SUBMISSION\n", font: .boldSystemFont(ofSize: 13), color: .systemGray))
        full.append(divider())
        
        if let s = submission {
            full.append(styled("Score:    ", font: .boldSystemFont(ofSize: 15), color: .black))
            full.append(styled("\(s.score ?? 0)/10\n", font: .systemFont(ofSize: 15), color: .darkGray))
            full.append(styled("Remarks: ", font: .boldSystemFont(ofSize: 15), color: .black))
            full.append(styled("\(s.remarks ?? "None")\n\n", font: .systemFont(ofSize: 15), color: .darkGray))
            let answers = s.answers
            if !answers.isEmpty {
                full.append(styled("Answers:\n", font: .boldSystemFont(ofSize: 14), color: .black))
                for (i, ans) in answers.enumerated() {
                    full.append(styled("  \(i + 1). \(ans)\n", font: .systemFont(ofSize: 14), color: .darkGray))
                }
            }
        } else {
            full.append(styled("No assignment submission for this date.\n", font: .italicSystemFont(ofSize: 14), color: .systemGray))
        }
        
        return full
    }
    
    private func styled(_ text: String, font: UIFont, color: UIColor) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
    }
    
    private func divider() -> NSAttributedString {
        NSAttributedString(string: "────────────────────────────\n", attributes: [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.systemGray4
        ])
    }

    // MARK: - PDF Generation (self-contained — does NOT depend on textView.text)
    func generateProfessionalPDF() -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { ctx in
            ctx.beginPage()
            
            let margin: CGFloat = 50
            let contentWidth = pageRect.width - margin * 2
            var y = margin
            
            let brandColor = isParentSide ? UIColor.systemOrange : UIColor(red: 0.18, green: 0.48, blue: 0.96, alpha: 1)
            
            // ── Header Band ──────────────────────────────────────────────
            let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 80)
            brandColor.setFill()
            UIBezierPath(rect: headerRect).fill()
            
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor.white
            ]
            "TheraSync — Clinical Progress Report".draw(at: CGPoint(x: margin, y: 28), withAttributes: titleAttr)
            y = 100
            
            // ── Date & Patient Info ───────────────────────────────────────
            let formatter = DateFormatter(); formatter.dateStyle = .long
            let dateStr = reportDate.map { formatter.string(from: $0) } ?? "Unknown"
            
            let subAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.systemGray]
            "Generated: \(dateStr)".draw(at: CGPoint(x: margin, y: y), withAttributes: subAttr)
            y += 24
            
            // Patient box
            let boxRect = CGRect(x: margin, y: y, width: contentWidth, height: 56)
            let boxBg = isParentSide ? UIColor.systemOrange.withAlphaComponent(0.05) : UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1)
            boxBg.setFill()
            UIBezierPath(roundedRect: boxRect, cornerRadius: 6).fill()
            brandColor.withAlphaComponent(0.3).setStroke()
            UIBezierPath(roundedRect: boxRect, cornerRadius: 6).stroke()
            
            let boldAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: UIColor.black]
            let normAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.darkGray]
            
            "Patient:".draw(at: CGPoint(x: margin + 12, y: y + 10), withAttributes: boldAttr)
            (patient?.fullName ?? "N/A").draw(at: CGPoint(x: margin + 70, y: y + 10), withAttributes: normAttr)
            "Patient ID:".draw(at: CGPoint(x: margin + 12, y: y + 30), withAttributes: boldAttr)
            (patient?.patientID ?? "N/A").draw(at: CGPoint(x: margin + 70, y: y + 30), withAttributes: normAttr)
            y += 76
            
            // ── Section: Assessments ──────────────────────────────────────
            y = drawSectionHeader("CLINICAL ASSESSMENTS", at: y, margin: margin, width: contentWidth)
            
            if assessments.isEmpty {
                y = drawBodyLine("No assessments recorded for this date.", at: y, margin: margin, italic: true, width: contentWidth)
            } else {
                for (i, a) in assessments.enumerated() {
                    y = drawBodyLine("Assessment \(i + 1): \(a.assessment_type.uppercased())", at: y, margin: margin, bold: true, width: contentWidth)
                    if let data = a.assessment_data.value as? [String: Any] {
                        for (key, value) in data.sorted(by: { $0.key < $1.key }) {
                            // Check if we need a new page
                            if y > pageRect.height - 80 {
                                ctx.beginPage()
                                y = margin
                            }
                            y = drawBodyLine("  • \(key): \(value)", at: y, margin: margin, width: contentWidth)
                        }
                    }
                    y += 6
                }
            }
            y += 10
            
            // ── Section: Assignment ───────────────────────────────────────
            if y > pageRect.height - 120 { ctx.beginPage(); y = margin }
            y = drawSectionHeader("ASSIGNMENT SUBMISSION", at: y, margin: margin, width: contentWidth)
            
            if let s = submission {
                y = drawKeyValue("Score:", value: "\(s.score ?? 0)/10", at: y, margin: margin, width: contentWidth)
                y = drawKeyValue("Remarks:", value: s.remarks ?? "None", at: y, margin: margin, width: contentWidth)
                let answers = s.answers
                if !answers.isEmpty {
                    y += 4
                    y = drawBodyLine("Answers:", at: y, margin: margin, bold: true, width: contentWidth)
                    for (i, ans) in answers.enumerated() {
                        if y > pageRect.height - 60 { ctx.beginPage(); y = margin }
                        y = drawBodyLine("  \(i + 1). \(ans)", at: y, margin: margin, width: contentWidth)
                    }
                }
            } else {
                y = drawBodyLine("No assignment submission for this date.", at: y, margin: margin, italic: true, width: contentWidth)
            }
            
            // ── Footer ────────────────────────────────────────────────────
            let footerY = pageRect.height - 36
            UIColor.systemGray5.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: footerY, width: pageRect.width, height: 36)).fill()
            let footAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.systemGray]
            "TheraSync · Confidential Clinical Record · \(dateStr)".draw(at: CGPoint(x: margin, y: footerY + 12), withAttributes: footAttr)
        }
    }
    
    // MARK: - PDF Drawing Helpers
    @discardableResult
    private func drawSectionHeader(_ title: String, at y: CGFloat, margin: CGFloat, width: CGFloat) -> CGFloat {
        let brandColor = isParentSide ? UIColor.systemOrange : UIColor(red: 0.18, green: 0.48, blue: 0.96, alpha: 1)
        let rect = CGRect(x: margin, y: y, width: width, height: 22)
        brandColor.withAlphaComponent(0.12).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 4).fill()
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: brandColor
        ]
        title.draw(at: CGPoint(x: margin + 8, y: y + 6), withAttributes: attr)
        return y + 30
    }
    
    @discardableResult
    private func drawBodyLine(_ text: String, at y: CGFloat, margin: CGFloat, bold: Bool = false, italic: Bool = false, width: CGFloat) -> CGFloat {
        let font: UIFont = bold ? .boldSystemFont(ofSize: 11) : (italic ? .italicSystemFont(ofSize: 11) : .systemFont(ofSize: 11))
        let color: UIColor = italic ? .systemGray : .darkGray
        let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let boundingRect = (text as NSString).boundingRect(with: CGSize(width: width, height: 1000), options: .usesLineFragmentOrigin, attributes: attr, context: nil)
        text.draw(in: CGRect(x: margin, y: y, width: width, height: boundingRect.height + 4), withAttributes: attr)
        return y + boundingRect.height + 6
    }
    
    @discardableResult
    private func drawKeyValue(_ key: String, value: String, at y: CGFloat, margin: CGFloat, width: CGFloat) -> CGFloat {
        let boldAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: UIColor.black]
        let normAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.darkGray]
        key.draw(at: CGPoint(x: margin, y: y), withAttributes: boldAttr)
        value.draw(at: CGPoint(x: margin + 70, y: y), withAttributes: normAttr)
        return y + 18
    }
}
