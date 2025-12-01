//
//  ProfileViewController.swift
//  VCaller
//
//  Created by Mac on 28/10/25.
//

import UIKit

class ProfileViewController: UIViewController {

    // Outlets to display profile info
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var pronounsLabel: UILabel!

    private let usernameKey = "username"
    private let regionKey = "region"
    private let birthdayKey = "birthday"
    private let pronounsKey = "pronouns"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        // Optional initial state
        usernameLabel.text = "Guest"
        regionLabel.text = "—"
        birthdayLabel.text = "—"
        pronounsLabel.text = "—"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfileDisplay()
    }

    private func updateProfileDisplay() {
        let defaults = UserDefaults.standard

        if let name = defaults.string(forKey: usernameKey), !name.isEmpty {
            usernameLabel.text = name
        } else {
            usernameLabel.text = "Guest"
        }

        let region = defaults.string(forKey: regionKey)
        regionLabel.text = (region?.isEmpty == false) ? region : "—"

        let birthday = defaults.string(forKey: birthdayKey)
        birthdayLabel.text = (birthday?.isEmpty == false) ? birthday : "—"

        let pronouns = defaults.string(forKey: pronounsKey)
        pronounsLabel.text = (pronouns?.isEmpty == false) ? pronouns : "—"
    }

    // Connect your "Update Profile" button to this action
    @IBAction func updateProfileTapped(_ sender: UIButton) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "ProfileUpdateViewController") as? ProfileUpdateViewController else {
            assertionFailure("Storyboard ID 'ProfileUpdateViewController' not found")
            return
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    // Existing logout
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: usernameKey)
        defaults.removeObject(forKey: regionKey)
        defaults.removeObject(forKey: birthdayKey)
        defaults.removeObject(forKey: pronounsKey)

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
