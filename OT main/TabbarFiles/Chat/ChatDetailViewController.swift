//
//  ChatDetailViewController.swift
//  Screens1
//
//  Created by user@54 on 16/11/25.
//

import UIKit

struct ChatMessage {
    let text: String
    let isIncoming: Bool
}

class ChatDetailViewController: UIViewController {

    var titleName: String?

    private var messages: [ChatMessage] = [
        ChatMessage(text: "Hello!", isIncoming: true),
        ChatMessage(text: "Hi, how can I help you today?", isIncoming: false),
        ChatMessage(text: "Can you check the file I sent?", isIncoming: true),
        ChatMessage(text: "Sure, I’ll check it.", isIncoming: false)
    ]

    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()

    private let tableView = UITableView()
    private let inputContainer = UIView()
    private let tf = UITextField()
    private let sendBtn = UIButton(type: .system)

    override var inputAccessoryView: UIView? { inputContainer }
    override var canBecomeFirstResponder: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        navigationController?.navigationBar.isHidden = true

        setupHeader()
        setupTable()
        setupInputBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        inputContainer.frame.size.height = 56
    }

    // MARK: Header
    private func setupHeader() {
        headerView.backgroundColor = UIColor(red: 0.15, green: 0.52, blue: 1, alpha: 1)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 110)
        ])

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.layer.cornerRadius = 22
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        backButton.addTarget(self, action: #selector(backTap), for: .touchUpInside)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        titleLabel.text = titleName ?? "Chat"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor)
        ])
    }

    @objc private func backTap() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: Table
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(IncomingBubble.self, forCellReuseIdentifier: "Incoming")
        tableView.register(OutgoingBubble.self, forCellReuseIdentifier: "Outgoing")

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: Input Bar
    private func setupInputBar() {
        inputContainer.backgroundColor = .secondarySystemBackground

        tf.placeholder = "Message"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false

        sendBtn.setTitle("Send", for: .normal)
        sendBtn.addTarget(self, action: #selector(sendMsg), for: .touchUpInside)
        sendBtn.translatesAutoresizingMaskIntoConstraints = false

        inputContainer.addSubview(tf)
        inputContainer.addSubview(sendBtn)

        NSLayoutConstraint.activate([
            tf.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            tf.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendBtn.leadingAnchor.constraint(equalTo: tf.trailingAnchor, constant: 12),
            sendBtn.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            sendBtn.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            tf.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    @objc private func sendMsg() {
        guard let t = tf.text, !t.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        messages.append(ChatMessage(text: t, isIncoming: false))
        tf.text = ""
        tableView.reloadData()

        let index = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: index, at: .bottom, animated: true)
    }
}

// MARK: - DataSource
extension ChatDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let msg = messages[indexPath.row]

        if msg.isIncoming {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Incoming", for: indexPath) as! IncomingBubble
            cell.setText(msg.text)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Outgoing", for: indexPath) as! OutgoingBubble
            cell.setText(msg.text)
            return cell
        }
    }
}

class IncomingBubble: UITableViewCell {
    private let bubble = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    func setup() {
        backgroundColor = .clear
        bubble.numberOfLines = 0
        bubble.textColor = .black
        bubble.backgroundColor = UIColor(white: 0.92, alpha: 1)
        bubble.layer.cornerRadius = 14
        bubble.layer.masksToBounds = true
        bubble.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubble)

        NSLayoutConstraint.activate([
            bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -120),
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func setText(_ t: String) { bubble.text = "  \(t)  " }
}

class OutgoingBubble: UITableViewCell {
    private let bubble = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    func setup() {
        backgroundColor = .clear
        bubble.numberOfLines = 0
        bubble.textColor = .white
        bubble.backgroundColor = UIColor.systemBlue
        bubble.layer.cornerRadius = 14
        bubble.layer.masksToBounds = true
        bubble.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubble)

        NSLayoutConstraint.activate([
            bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 120),
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func setText(_ t: String) { bubble.text = "  \(t)  " }
}
