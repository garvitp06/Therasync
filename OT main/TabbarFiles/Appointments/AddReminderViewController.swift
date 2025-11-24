//
//  AddReminderViewController.swift
//  Trial
//
//  Created by user@54 on 14/11/25.
//

import UIKit

// 1. Protocol Definition
protocol AddReminderDelegate: AnyObject {
    func didAddAppointment(title: String, subtitle: String, date: Date, time: Date)
}

final class AddReminderViewController: UIViewController {

    // MARK: - Outlets
    // IMPORTANT: Check these connections in your XIB file!
    @IBOutlet weak var topContainerView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var nameHeaderLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var subtitleTextField: UITextField!
    
    @IBOutlet weak var dateTimeHeaderLabel: UILabel!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var datePicker: UIDatePicker!

    // 2. Delegate Variable
    weak var delegate: AddReminderDelegate?

    // MARK: - Init
    init() {
        // Ensure "AddReminderViewController.xib" exists in your project folder
        super.init(nibName: "AddReminderViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ AddReminderViewController loaded")
        view.backgroundColor = .white
        setupHeader()
        setupInputs()
        setupPickers()
        setupActions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Safety check for optional outlet to prevent crash if not connected
        if let topContainer = topContainerView {
            if #available(iOS 11.0, *) {
                topContainer.layer.cornerRadius = 24
                topContainer.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                topContainer.clipsToBounds = true
            }
        }
    }

    // MARK: - Setup
    private func setupHeader() {
        // Safety checks
        guard let closeBtn = closeButton, let doneBtn = doneButton else {
            print("❌ Error: Buttons not connected in XIB")
            return
        }
        
        closeBtn.layer.cornerRadius = closeBtn.frame.height / 2
        closeBtn.clipsToBounds = true
        
        doneBtn.layer.cornerRadius = doneBtn.frame.height / 2
        doneBtn.clipsToBounds = true
        
        titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
    }

    private func setupInputs() {
        nameHeaderLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        
        titleTextField?.placeholder = "Title"
        titleTextField?.borderStyle = .roundedRect
        
        subtitleTextField?.placeholder = "Sub Heading"
        subtitleTextField?.borderStyle = .roundedRect
    }

    private func setupPickers() {
        dateTimeHeaderLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        
        datePicker?.datePickerMode = .date
        datePicker?.preferredDatePickerStyle = .compact
        
        timePicker?.datePickerMode = .time
        timePicker?.preferredDatePickerStyle = .compact
    }

    private func setupActions() {
        closeButton?.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        doneButton?.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        print("❌ Close Tapped")
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        print("🔵 Done Tapped")
        
        // Guard against nil outlets
        guard let titleTF = titleTextField, let dateP = datePicker, let timeP = timePicker else {
            print("❌ Error: Input fields not connected in XIB")
            return
        }

        let title = titleTF.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let subtitle = subtitleTextField?.text?.trimmingCharacters(in: .whitespaces) ?? ""
        
        if title.isEmpty {
            print("⚠️ Title is empty")
            let alert = UIAlertController(title: nil, message: "Please enter a title", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        print("🚀 Sending data to delegate: \(title)")
        // 3. Pass data back
        delegate?.didAddAppointment(title: title, subtitle: subtitle, date: dateP.date, time: timeP.date)
        
        dismiss(animated: true)
    }
}
