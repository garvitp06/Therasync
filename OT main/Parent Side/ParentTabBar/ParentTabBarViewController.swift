//
//  MainTabBarContainerViewController.swift
//  OT main
//
//  Created by Garvit Pareek on 17/11/2025.
//

import UIKit

class ParentTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.backgroundColor = .clear
        
        // Match the brand orange from ParentGradientView
        let brandOrange = UIColor(red: 255/255, green: 166/255, blue: 0/255, alpha: 1.0)
        self.tabBar.tintColor = brandOrange
        self.tabBar.unselectedItemTintColor = .systemGray
        
        // Use appearance API for better iOS 15+ stability
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Selected attributes
        appearance.stackedLayoutAppearance.selected.iconColor = brandOrange
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: brandOrange]
        
        // Normal (unselected) attributes
        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        
        self.tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            self.tabBar.scrollEdgeAppearance = appearance
        }
        
        // Set up all the view controllers for each tab
        viewControllers = [
            createTab(root: DashboardViewController(),
                      title: "Dashboard",
                      icon: "house.fill"),
                      
            createTab(root: ReportsViewController(),
                      title: "Reports",
                      icon: "doc.text.fill"),
 
            createTab(root: StudentProfileViewController(),
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
