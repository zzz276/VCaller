//
//  ProfileViewController.swift
//  VCaller
//
//  Created by Mac on 28/10/25.
//

import FirebaseFirestore
import UIKit

class ProfileViewController: UIViewController {

    // Outlets to display profile info
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var pronounsLabel: UILabel!
    
    private let db = Firestore.firestore()
    private let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        
        updateProfileDisplay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfileDisplay()
    }

    private func updateProfileDisplay() {
        if let name = defaults.string(forKey: usernameKey), !name.isEmpty { usernameLabel.text = name }
        else { usernameLabel.text = "Guest" }
        
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

    private func switchToLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let login = storyboard.instantiateViewController(withIdentifier: "LoginViewController")

        if let scene = view.window?.windowScene,
           let sceneDelegate = scene.delegate as? SceneDelegate { sceneDelegate.setRoot(login, animated: true) } else {
            UIApplication.shared.windows.first?.rootViewController = login
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
    }
}
