//
//  MainTabBarContainerViewController.swift
//  OT main
//
//  Created by Garvit Pareek on 17/11/2025.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This is the standard, non-transparent tab bar background
        self.tabBar.backgroundColor = .clear
        
        // This is the blue color for the selected icon
        self.tabBar.tintColor = .systemBlue
        
        // Set up all the view controllers for each tab
        viewControllers = [
            createTab(root: AppointmentViewController(),
                      title: "Appointment",
                      icon: "calendar"),
                      
            createTab(root: PatientListViewController(),
                      title: "Patients",
                      icon: "figure"),
                      
            createTab(root: ChatListViewController(),
                      title: "Chat",
                      icon: "message"),
                      
            createTab(root: ProfileListViewController(),
                      title: "Profile",
                      icon: "person.fill")
        ]
        self.selectedIndex = 0
    }

    private func createTab(root: UIViewController, title: String, icon: String) -> UINavigationController {
        
        // 1. Set the tab bar item properties ON THE ROOT VC
        root.tabBarItem.title = title
        root.tabBarItem.image = UIImage(systemName: icon)
        
        // 2. Wrap the root VC in a navigation controller
        // This is essential for navigation (like pushing ProfileViewController)
        let navController = UINavigationController(rootViewController: root)
        return navController
    }
}
