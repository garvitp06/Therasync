//
//  VolumeSettingsViewController.swift
//  OT main
//
//  Created by Garvit Pareek on 20/12/2025.
//
import UIKit
class VolumeSettingsViewController: UIViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Maximum Volume Limit"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        // Use dynamic color for label
        label.textColor = .dynamicLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Set the highest volume level allowed for game chimes and feedback sounds to prevent sensory overload."
        label.font = .systemFont(ofSize: 14)
        // Use secondary system label color (it automatically dims in dark mode)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let volumeSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.minimumTrackTintColor = UIColor(red: 0.24, green: 0.51, blue: 1.0, alpha: 1.0)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    // The card container
    private let container: UIView = {
        let view = UIView()
        // Use our global dynamic card color (White -> Grey)
        view.backgroundColor = .dynamicCard
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        title = "Audio Volume"
        
        // Load existing limit or default to 0.8
        let savedLimit = UserDefaults.standard.float(forKey: "MaxVolumeLimit")
        volumeSlider.value = savedLimit == 0 ? 0.8 : savedLimit
        
        volumeSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
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
    }

    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupUI() {
        // Gradient automatically handles its own Dark/Light swap
        let bg = ParentGradientView()
        bg.frame = view.bounds
        view.addSubview(bg)
        
        view.addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(descriptionLabel)
        container.addSubview(volumeSlider)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            container.bottomAnchor.constraint(equalTo: volumeSlider.bottomAnchor, constant: 30),
            
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            
            volumeSlider.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            volumeSlider.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            volumeSlider.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        UserDefaults.standard.set(sender.value, forKey: "MaxVolumeLimit")
    }
}
