//
//  ChatInputAccessoryView.swift
//  Screens1
//
//  Created by user@54 on 16/11/25.
//

import UIKit

protocol ChatInputAccessoryViewDelegate: AnyObject {
    func sendButtonTapped(text: String)
}

class ChatInputAccessoryView: UIView {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!

    weak var delegate: ChatInputAccessoryViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .secondarySystemBackground

        textField.borderStyle = .none
        textField.placeholder = "Message"
        textField.returnKeyType = .send
        textField.enablesReturnKeyAutomatically = true
        textField.delegate = self

        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 36))
        textField.leftView = leftPadding
        textField.leftViewMode = .always
        textField.layer.cornerRadius = 16
        textField.clipsToBounds = true

        sendButton.layer.cornerRadius = 14
        sendButton.clipsToBounds = true
        sendButton.backgroundColor = tintColor
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
    }

    @objc private func sendTapped() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        delegate?.sendButtonTapped(text: text)
        textField.text = ""
    }

    static func loadFromNib() -> ChatInputAccessoryView {
        let nib = UINib(nibName: "ChatInputAccessoryView", bundle: nil)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? ChatInputAccessoryView else {
            fatalError("ChatInputAccessoryView.xib is not set up correctly!")
        }
        return view
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    // explicit helper used by controller
    func clearText() {
        textField.text = ""
    }
}

extension ChatInputAccessoryView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }
}

