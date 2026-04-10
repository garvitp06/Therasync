//
//  SupportTicketViewController.swift
//  OT main
//
//  Created by Garvit Pareek on 20/12/2025.
//
import UIKit
import PhotosUI
class SupportTicketViewController: UIViewController, PHPickerViewControllerDelegate {
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Describe the issue you're experiencing:"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .dynamicLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .dynamicCard
        tv.textColor = .dynamicLabel
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 12
        tv.font = .systemFont(ofSize: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let attachmentView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = .dynamicCard
        iv.image = UIImage(systemName: "photo.badge.plus")
        iv.tintColor = .systemGray
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // MARK: - Initializer
    init() {
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        title = "Support Ticket"
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(pickImage))
        attachmentView.addGestureRecognizer(tap)
        
        

        updateLayerColors()
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
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        let backBtn = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(handleBack))
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: .done, target: self, action: #selector(submitTicket))
    }

    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    private func updateLayerColors() {
        let isDark = UserDefaults.standard.bool(forKey: "Dark Mode")
        textView.layer.borderColor = isDark ? UIColor.secondaryLabel.cgColor : UIColor.systemGray4.cgColor
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayerColors()
    }
    
    private func setupUI() {
        let bg = ParentGradientView()
        bg.frame = view.bounds
        view.addSubview(bg)
        
        view.addSubview(descriptionLabel)
        view.addSubview(textView)
        view.addSubview(attachmentView)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            textView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 150),
            
            attachmentView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            attachmentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            attachmentView.widthAnchor.constraint(equalToConstant: 100),
            attachmentView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    @objc private func pickImage() {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        results.first?.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            DispatchQueue.main.async {
                self?.attachmentView.image = image as? UIImage
            }
        }
    }
    
    @objc private func submitTicket() {
        let alert = UIAlertController(title: "Ticket Submitted", message: "Thank you. Our technical team will review this and get back to you via email.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true)
    }
}
