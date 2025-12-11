//
//  SceneDelegate.swift
//  VCaller
//
//  Created by Mac on 27/10/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private let usernameKey = "username"

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        window.rootViewController = initialRootViewController()
        window.makeKeyAndVisible()
    }

    private func initialRootViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if let savedUsername = UserDefaults.standard.string(forKey: usernameKey), !savedUsername.isEmpty {
            // Already logged in → show Home flow
            if let initial = storyboard.instantiateInitialViewController() {
                return initial
            } else if let home = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController {
                return UINavigationController(rootViewController: home)
            }
        }

        // Not logged in → show Login
        let login = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        return login
    }

    // Public helper to swap roots (used after login/logout)
    func setRoot(_ vc: UIViewController, animated: Bool = true) {
        guard let window = self.window else { return }
        if animated {
            UIView.transition(with: window, duration: 0.3, options: [.transitionCrossDissolve], animations: {
                window.rootViewController = vc
            })
        } else {
            window.rootViewController = vc
        }
        window.makeKeyAndVisible()
    }
}
