//
//  ReportIssueViewController.swift
//  OT main
//
//  Created by Garvit Pareek on 17/01/2026.
//


//
//  ReportIssueViewController.swift
//  OT main
//
//  Created by Alishri Poddar
//



import UIKit

class ReportIssueViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Back to standard GradientView
    private let backgroundView: GradientView = {
        let view = GradientView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Describe the issue you're experiencing:"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        // Back to standard dynamicLabel
        label.textColor = .dynamicLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.layer.cornerRadius = 12
        tv.font = .systemFont(ofSize: 16)
        // Back to standard dynamicCard & dynamicLabel
        tv.backgroundColor = .dynamicCard
        tv.textColor = .dynamicLabel
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private lazy var addPhotoButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .dynamicCard
        btn.layer.cornerRadius = 12
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
        btn.setImage(UIImage(systemName: "photo.badge.plus", withConfiguration: config), for: .normal)
        btn.tintColor = .systemGray
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        return btn
    }()
    
    private let imagesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // This function is now available via the extension in OTSettingsViewController (or globally)
        applyOTNavigationStyling(title: "Report Issue")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: .done, target: self, action: #selector(submitTapped))
        navigationItem.rightBarButtonItem?.tintColor = .white
    }
    
    private func setupUI() {
        view.addSubview(backgroundView)
        view.addSubview(instructionLabel)
        view.addSubview(descriptionTextView)
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(imagesStackView)
        view.addSubview(addPhotoButton)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descriptionTextView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 10),
            descriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 150),
            
            addPhotoButton.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 20),
            addPhotoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addPhotoButton.widthAnchor.constraint(equalToConstant: 80),
            addPhotoButton.heightAnchor.constraint(equalToConstant: 80),
            
            scrollView.topAnchor.constraint(equalTo: addPhotoButton.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: addPhotoButton.trailingAnchor, constant: 15),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalToConstant: 80),
            
            imagesStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imagesStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imagesStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imagesStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imagesStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    @objc func addPhotoTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    @objc func submitTapped() {
        let alert = UIAlertController(title: "Submitted", message: "Thank you for your report.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            let iv = UIImageView(image: image)
            iv.contentMode = .scaleAspectFill
            iv.layer.cornerRadius = 8
            iv.clipsToBounds = true
            iv.widthAnchor.constraint(equalToConstant: 80).isActive = true
            imagesStackView.addArrangedSubview(iv)
        }
        picker.dismiss(animated: true)
    }
}
