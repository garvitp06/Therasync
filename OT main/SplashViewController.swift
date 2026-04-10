import UIKit
import Supabase

class SplashViewController: UIViewController {
    
    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "SplashLogo"))
        iv.contentMode = .scaleAspectFit
        iv.alpha = 0 // Start invisible for animation
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        animateAndNavigate()
    }

    private func animateAndNavigate() {
        UIView.animate(withDuration: 1.0, animations: {
            self.logoImageView.alpha = 1.0
        }) { _ in
            self.checkSession()
        }
    }
    
    private func setupLayout() {
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func checkSession() {
        Task {
            do {
                // Check if a session exists
                _ = try await supabase.auth.session
                
                // If it does, fetch the user role to know where to route
                let role = try await AuthService.shared.fetchUserRole()
                
                await MainActor.run {
                    if role == "1" {
                        self.switchToRoot(MainTabBarController())
                    } else if role == "0" {
                        self.checkParentLinkingAndRoute()
                    } else {
                        self.routeToLogin()
                    }
                }
            } catch {
                // If anything fails (no session, network error, etc.), go to login
                await MainActor.run {
                    self.routeToLogin()
                }
            }
        }
    }
    
    private func routeToLogin() {
        let loginVC = NewLoginViewController()
        let nav = UINavigationController(rootViewController: loginVC)
        nav.setNavigationBarHidden(true, animated: false)
        switchToRoot(nav)
    }
    
    private func checkParentLinkingAndRoute() {
        Task {
            do {
                let user = try await supabase.auth.user()
                
                let response = try await supabase
                    .from("profiles")
                    .select("linked_patient_id, linked_patient_id_2")
                    .eq("id", value: user.id)
                    .single()
                    .execute()
                
                let data = response.data
                let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                let linkedID1 = dict?["linked_patient_id"] as? String
                let linkedID2 = dict?["linked_patient_id_2"] as? String
                
                await MainActor.run {
                    let hasNoLinkedChildren = (linkedID1 == nil || linkedID1?.isEmpty == true) &&
                                              (linkedID2 == nil || linkedID2?.isEmpty == true)
                    
                    if hasNoLinkedChildren {
                        self.switchToRoot(UINavigationController(rootViewController: ParentEmptyStateViewController()))
                    } else {
                        let activeID = (linkedID1 != nil && !linkedID1!.isEmpty) ? linkedID1 : linkedID2
                        UserDefaults.standard.set(activeID, forKey: "LastSelectedChildID")
                        
                        self.switchToRoot(ParentTabBarViewController())
                    }
                }
            } catch {
                await MainActor.run {
                    self.switchToRoot(UINavigationController(rootViewController: ParentEmptyStateViewController()))
                }
            }
        }
    }
    
    private func switchToRoot(_ viewController: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        window.rootViewController = viewController
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil)
    }
}
