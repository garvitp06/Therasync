//
//  ParentNoteDetailViewController.swift
//  OT main
//
//  Created by Garvit Pareek on 18/01/2026.
//


import UIKit
import Supabase
// Dedicated delegate just for the Parent side
protocol ParentNoteDetailDelegate: AnyObject {
    func didUpdateParentNote(id: UUID, newTitle: String, newBody: String)
}

class ParentNoteDetailViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    weak var delegate: ParentNoteDetailDelegate?
    var noteID: UUID?
    var patientID: String?
    var noteContent: String?
    var fullDateString: String?
    
    private var containerBottomConstraint: NSLayoutConstraint?

    let titleTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 32, weight: .bold)
        tf.textColor = .label
        tf.placeholder = "Note Title"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let textContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 17)
        tv.backgroundColor = .clear
        tv.textColor = .label
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.delegate = self
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        configureData()
        setupPlaceholder()
        setupKeyboardObservers()
        setupTapGesture()
        titleTextField.addTarget(self, action: #selector(titleDidChange), for: .editingChanged)
    }

    private func setupLayout() {
        view.addSubview(titleTextField)
        view.addSubview(timeLabel)
        view.addSubview(textContainer)
        textContainer.addSubview(textView)
        
        containerBottomConstraint = textContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)

        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            timeLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 5),
            timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textContainer.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 20),
            textContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerBottomConstraint!,
            textView.topAnchor.constraint(equalTo: textContainer.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor, constant: -16)
        ])
    }

    private func configureData() {
        guard let fullString = fullDateString else { return }
        
        // Parse ISO8601 (2026-01-18T11:46:27...)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: fullString) {
            let displayFormatter = DateFormatter()
            displayFormatter.timeZone = TimeZone(secondsFromGMT: 19800) // IST
            displayFormatter.dateFormat = "d MMMM yyyy, h:mm a"
            timeLabel.text = "Created at \(displayFormatter.string(from: date))"
        } else {
            timeLabel.text = "Created at \(fullString)" // Fallback
        }
        
        // Load content
        if let content = noteContent, !content.isEmpty {
            textView.text = content
            textView.textColor = .label
        } else {
            setupPlaceholder()
        }
    }

    @objc private func titleDidChange() { autoSave() }
    func textViewDidChange(_ textView: UITextView) { if textView.textColor != .lightGray { autoSave() } }
    
    private func autoSave() {
        guard let id = noteID, let pID = patientID else { return }
        let title = titleTextField.text ?? ""
        let body = textView.textColor == .lightGray ? "" : textView.text ?? ""
        delegate?.didUpdateParentNote(id: id, newTitle: title, newBody: body)

        Task {
            do {
                let user = try await supabase.auth.session.user
                try await supabase.from("notes").upsert([
                    "id": id.uuidString,
                    "patient_id": pID,
                    "parent_uid": user.id.uuidString,
                    "title": title,
                    "content": body
                ]).execute()
            } catch { print("❌ Save Error: \(error)") }
        }
    }

    private func setupPlaceholder() {
        if textView.text.isEmpty {
            textView.text = "Start typing your note..."
            textView.textColor = .lightGray
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty { setupPlaceholder() }
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            containerBottomConstraint?.constant = -frame.cgRectValue.height + view.safeAreaInsets.bottom - 10
            UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        containerBottomConstraint?.constant = -20
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc private func handleTap() { view.endEditing(true) }
}
