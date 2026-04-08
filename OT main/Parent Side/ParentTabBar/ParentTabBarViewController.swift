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
        
        setupTabBarAppearance()
        setupViewControllers()
    }

    private func setupTabBarAppearance() {
        let brandOrange = UIColor(red: 255/255, green: 166/255, blue: 0/255, alpha: 1.0)
        self.tabBar.tintColor = brandOrange
        self.tabBar.unselectedItemTintColor = .systemGray
        
        // Match background: enable translucency
        self.tabBar.isTranslucent = true
        
        let appearance = UITabBarAppearance()
        // Use transparent background so our ParentGradientView shows through
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear 
        appearance.shadowColor = nil
        appearance.shadowImage = nil
        
        // Selected attributes
        appearance.stackedLayoutAppearance.selected.iconColor = brandOrange
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: brandOrange,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        
        // Normal (unselected) attributes
        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 11, weight: .regular)
        ]
        
        self.tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            self.tabBar.scrollEdgeAppearance = appearance
        }
    }

    private func setupViewControllers() {
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
        root.tabBarItem.title = title
        root.tabBarItem.image = UIImage(systemName: icon)
        let navController = UINavigationController(rootViewController: root)
        return navController
    }
}
