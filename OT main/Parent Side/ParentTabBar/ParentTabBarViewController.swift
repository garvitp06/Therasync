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
        self.tabBar.isTranslucent = true

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        appearance.stackedLayoutAppearance.selected.iconColor = brandOrange
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: brandOrange,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 11, weight: .regular)
        ]

        self.tabBar.standardAppearance = appearance
        self.tabBar.scrollEdgeAppearance = appearance
    }

    private func setupViewControllers() {
        viewControllers = [
            createTab(root: DashboardViewController(),  title: "Dashboard", icon: "house.fill"),
            createTab(root: ReportsViewController(),    title: "Reports",   icon: "doc.text.fill"),
            createTab(root: StudentProfileViewController(), title: "Profile", icon: "person.fill")
        ]
        self.selectedIndex = 0
    }

    private func createTab(root: UIViewController, title: String, icon: String) -> UINavigationController {
        root.tabBarItem.title = title
        root.tabBarItem.image = UIImage(systemName: icon)
        let nav = UINavigationController(rootViewController: root)
        // Register as delegate so we can control tab bar on EVERY device (including iPad)
        nav.delegate = self
        return nav
    }

    // MARK: - Tab Bar Visibility Helper
    /// Animates the tab bar in/out in sync with the nav controller transition.
    func setTabBar(hidden: Bool, animated: Bool, alongside coordinator: UIViewControllerTransitionCoordinator?) {
        guard tabBar.isHidden != hidden else { return }

        if let coordinator = coordinator, animated {
            coordinator.animate(alongsideTransition: { _ in
                self.tabBar.isHidden = hidden
                self.tabBar.alpha   = hidden ? 0 : 1
            }, completion: { _ in
                self.tabBar.alpha = 1       // always restore alpha
            })
        } else {
            tabBar.isHidden = hidden
        }
    }
}

// MARK: - UINavigationControllerDelegate
// This is the KEY fix for iPad. On iPad, `hidesBottomBarWhenPushed` is not
// always honoured by UIKit — especially when the root VC hides the nav bar.
// By implementing the delegate here we drive visibility explicitly on every device.
extension ParentTabBarViewController: UINavigationControllerDelegate {

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        let shouldHide = viewController.hidesBottomBarWhenPushed

        // Coordinate the hide/show with the push/pop animation
        let coordinator = viewController.transitionCoordinator
        setTabBar(hidden: shouldHide, animated: animated, alongside: coordinator)

        // If the transition is cancelled (e.g. interactive pop), restore correctly
        coordinator?.notifyWhenInteractionChanges { [weak self] ctx in
            if ctx.isCancelled {
                let currentVC = navigationController.topViewController
                let restore = currentVC?.hidesBottomBarWhenPushed ?? false
                self?.setTabBar(hidden: restore, animated: true, alongside: nil)
            }
        }
    }
}
