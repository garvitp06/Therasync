////
////  SplashViewController.swift
////  OT main
////
////  Created by Garvit Pareek on 17/02/2026.
////
//
//import UIKit
//
//class SplashViewController: UIViewController {
//    
//    private let logoImageView: UIImageView = {
//        let iv = UIImageView(image: UIImage(named: "SplashLogo"))
//        iv.contentMode = .scaleAspectFit
//        iv.alpha = 0 // Start invisible for animation
//        iv.translatesAutoresizingMaskIntoConstraints = false
//        return iv
//    }()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//        setupLayout()
//        animateAndNavigate()
//    }
//
//    private func animateAndNavigate() {
//        UIView.animate(withDuration: 1.0, animations: {
//            self.logoImageView.alpha = 1.0
//        }) { _ in
//            // Move to Login or Dashboard after 1 second
//            self.showMainApp() 
//        }
//    }
//    
//    private func setupLayout() {
//        view.addSubview(logoImageView)
//        NSLayoutConstraint.activate([
//            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            logoImageView.widthAnchor.constraint(equalToConstant: 200),
//            logoImageView.heightAnchor.constraint(equalToConstant: 200)
//        ])
//    }
//}
