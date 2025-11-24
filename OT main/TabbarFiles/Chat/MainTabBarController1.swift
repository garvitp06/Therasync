////
////  MainTabBarController.swift
////  Screens1
////
////  Created by user@54 on 16/11/25.
////
//
//import UIKit
//
//class MainTabBarController: UITabBarController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupViewControllers()
//        styleTabBar()
//    }
//
//    private func setupViewControllers() {
//        // Chat
//        let chatList = ChatListViewController(nibName: "ChatListViewController", bundle: nil)
//        chatList.title = "Chat"
//        let chatNav = UINavigationController(rootViewController: chatList)
//        chatNav.tabBarItem = UITabBarItem(title: "Chat", image: UIImage(systemName: "bubble.left.and.bubble.right"), tag: 2)
//
//        // Patients placeholder
//        let patients = UIViewController()
//        patients.view.backgroundColor = .systemBackground
//        patients.title = "Patients"
//        let patientsNav = UINavigationController(rootViewController: patients)
//        patientsNav.tabBarItem = UITabBarItem(title: "Patients", image: UIImage(systemName: "person.2"), tag: 1)
//
//        // Appointment placeholder
//        let appointment = UIViewController()
//        appointment.view.backgroundColor = .systemBackground
//        appointment.title = "Appointment"
//        let appointmentNav = UINavigationController(rootViewController: appointment)
//        appointmentNav.tabBarItem = UITabBarItem(title: "Appointment", image: UIImage(systemName: "calendar"), tag: 0)
//
//        // Profile placeholder
//        let profile = UIViewController()
//        profile.view.backgroundColor = .systemBackground
//        profile.title = "Profile"
//        let profileNav = UINavigationController(rootViewController: profile)
//        profileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.crop.circle"), tag: 3)
//
//        // order: Appointment, Patients, Chat, Profile
//        viewControllers = [appointmentNav, patientsNav, chatNav, profileNav]
//    }
//
//    private func styleTabBar() {
//        tabBar.isTranslucent = true
//        tabBar.backgroundImage = UIImage()
//        tabBar.shadowImage = UIImage()
//
//        // rounded background behind the items
//        let bg = UIView()
//        bg.backgroundColor = .systemBackground
//        bg.layer.cornerRadius = 22
//        bg.layer.masksToBounds = false
//        bg.layer.shadowColor = UIColor.black.cgColor
//        bg.layer.shadowOpacity = 0.08
//        bg.layer.shadowOffset = CGSize(width: 0, height: 6)
//        bg.layer.shadowRadius = 10
//        bg.translatesAutoresizingMaskIntoConstraints = false
//        tabBar.insertSubview(bg, at: 0)
//
//        NSLayoutConstraint.activate([
//            bg.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor, constant: 12),
//            bg.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor, constant: -12),
//            bg.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: 6),
//            bg.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: -6)
//        ])
//
//        let appearance = UITabBarAppearance()
//        appearance.configureWithTransparentBackground()
//        tabBar.standardAppearance = appearance
//        if #available(iOS 15.0, *) {
//            tabBar.scrollEdgeAppearance = appearance
//        }
//
//        tabBar.tintColor = UIColor.systemBlue
//        tabBar.unselectedItemTintColor = UIColor.gray
//    }
//}
