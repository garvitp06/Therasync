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

            // 1. Initialize the window
            let window = UIWindow(windowScene: windowScene)
            
            // 2. Check the saved Dark Mode setting
            // If "Dark Mode" hasn't been set yet, this returns false (Light Mode)
            let isDarkMode = UserDefaults.standard.bool(forKey: "Dark Mode")
            
            // 3. Force the window to follow your app's setting, NOT the system setting
            window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            
            // 4. Setup your Root View Controller
            let splashVC = SplashViewController()
            window.rootViewController = splashVC
            
            // 5. Assign and make visible
            self.window = window
            window.makeKeyAndVisible()
        
    }
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

