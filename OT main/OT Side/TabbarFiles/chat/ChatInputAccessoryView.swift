import UIKit

// 1. Protocol Definition
protocol ChatInputAccessoryViewDelegate: AnyObject {
    func didTapSend(text: String)
}

// 2. Class Definition
class ChatInputAccessoryView: UIView, UITextViewDelegate {
    
    weak var delegate: ChatInputAccessoryViewDelegate?
    
    private let messageTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.isScrollEnabled = false
        tv.layer.cornerRadius = 20
        tv.layer.masksToBounds = true
        tv.backgroundColor = .systemGray6
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Message"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        btn.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .systemBlue
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        autoresizingMask = .flexibleHeight
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override var intrinsicContentSize: CGSize { return .zero }
    
    private func setupUI() {
        addSubview(separatorLine)
        addSubview(messageTextView)
        addSubview(sendButton)
        messageTextView.addSubview(placeholderLabel)
        
        messageTextView.delegate = self
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            separatorLine.topAnchor.constraint(equalTo: topAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            sendButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40),
            
            messageTextView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            messageTextView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
            messageTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            placeholderLabel.leadingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: 16),
            placeholderLabel.centerYAnchor.constraint(equalTo: messageTextView.centerYAnchor)
        ])
    }
    
    @objc private func handleSend() {
        guard let text = messageTextView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        delegate?.didTapSend(text: text)
        messageTextView.text = ""
        placeholderLabel.isHidden = false
        invalidateIntrinsicContentSize()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        invalidateIntrinsicContentSize()
    }
}
