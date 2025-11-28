//
//  ViewController.swift
//  VCaller
//
//  Created by Mac on 27/10/25.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!

    private let usernameKey = "username"

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUsernameDisplay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUsernameDisplay()
    }

    private func updateUsernameDisplay() {
        if let name = UserDefaults.standard.string(forKey: usernameKey), !name.isEmpty {
            subtitleLabel.text = "Welcome, \(name)"
        } else {
            subtitleLabel.text = "Welcome"
        }
    }

    @IBAction func startButtonTapped(_ sender: UIButton) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "UsernameViewController") as? UsernameViewController else {
            assertionFailure("Storyboard ID not found")
            return
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func settingButtonTapped(_ sender: UIButton) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "SettingViewController") as? SettingViewController else {
            assertionFailure("Storyboard ID not found")
            return
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func profileButtonTapped(_ sender: UIButton) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController else {
            assertionFailure("Storyboard ID not found")
            return
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    // Connect your Logout button to this action
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        // Clear saved username
        UserDefaults.standard.removeObject(forKey: usernameKey)

        // Go back to Login screen
        switchToLogin()
    }

    private func switchToLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let login = storyboard.instantiateViewController(withIdentifier: "LoginViewController")

        if let scene = view.window?.windowScene,
           let sceneDelegate = scene.delegate as? SceneDelegate {
            sceneDelegate.setRoot(login, animated: true)
        } else {
            UIApplication.shared.windows.first?.rootViewController = login
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        let base = UIFont(descriptor: descriptor, size: pointSize)
        return UIFontMetrics.default.scaledFont(for: base)
    }
}
