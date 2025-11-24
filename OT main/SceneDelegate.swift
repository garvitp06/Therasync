//
//  SceneDelegate.swift
//  OT main
//
//  Created by Garvit Pareek on 06/11/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    class AppointmentViewController: UIViewController { /* ... */ }
    class ChatViewController: UIViewController { /* ... */ }
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
//        window = UIWindow(windowScene: windowScene)
//        
//        let mainTabBarController = MainTabBarController()
//            
//            // 2. Set it as the app's root view controller
//            window?.rootViewController = mainTabBarController
//            window?.makeKeyAndVisible()
            let loginVC = NewLoginViewController()
            
            // 2. --- CRITICAL STEP: Wrap it in a Navigation Controller ---
            // This gives the login screen the ability to "push" other screens.
            let navigationController = UINavigationController(rootViewController: loginVC)
            
            // 3. Hide the top bar for the login screen (optional, looks cleaner)
            navigationController.setNavigationBarHidden(true, animated: false)
            
            // 4. Set the Navigation Controller (NOT the loginVC) as the root
        window?.rootViewController = navigationController

        window?.makeKeyAndVisible()
        
        
        func sceneDidDisconnect(_ scene: UIScene) {
            // Called as the scene is being released by the system.
            // This occurs shortly after the scene enters the background, or when its session is discarded.
            // Release any resources associated with this scene that can be re-created the next time the scene connects.
            // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        }
        
        func sceneDidBecomeActive(_ scene: UIScene) {
            // Called when the scene has moved from an inactive state to an active state.
            // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        }
        
        func sceneWillResignActive(_ scene: UIScene) {
            // Called when the scene will move from an active state to an inactive state.
            // This may occur due to temporary interruptions (ex. an incoming phone call).
        }
        
        func sceneWillEnterForeground(_ scene: UIScene) {
            // Called as the scene transitions from the background to the foreground.
            // Use this method to undo the changes made on entering the background.
        }
        
        func sceneDidEnterBackground(_ scene: UIScene) {
            // Called as the scene transitions from the foreground to the background.
            // Use this method to save data, release shared resources, and store enough scene-specific state information
            // to restore the scene back to its current state.
        }
        
        
    }
}
