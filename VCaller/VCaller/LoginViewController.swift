//
//  LoginViewController.swift
//  VCaller
//
//  Created by Mac on 02/11/25.
//

import FirebaseFirestore
import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var usernametxt: UITextField!
    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Optional UI setup
        usernametxt.autocorrectionType = .no
        usernametxt.autocapitalizationType = .none
        usernametxt.placeholder = "Username"
    }

    // Connect this to your Login button in Interface Builder
    @IBAction func loginTapped(_ sender: UIButton) {
        let username = (usernametxt.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else {
            showAlert(title: "Missing Username", message: "Please enter a username!")
            
            return
        }

        // Save username as the login state
        let defaults = UserDefaults.standard
        
        Task {
            let querySnapshot = try await db.collection("users").whereField("username", isEqualTo: username).getDocuments()
            
            if querySnapshot.documents.count == 1 { defaults.set(querySnapshot.documents[0].documentID, forKey: idKey) }
            else { defaults.set(generateRandomString(), forKey: idKey) }
            do {
                try await db.collection("users").document(defaults.string(forKey: idKey)!).setData([
                    "username": username,
                    "status": "online",
                ], merge: true)
                
                print("You are now logged in!")
            } catch { print("Error when logging in: \(error)") }
            
            SignalingManager.shared.connect()
            defaults.set(username, forKey: usernameKey)
            defaults.set("-", forKey: regionKey)
            defaults.set("-", forKey: birthdayKey)
            defaults.set("-", forKey: pronounsKey)
        }

        // Swap to Home flow
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let initial = storyboard.instantiateInitialViewController() {
            switchToRoot(initial)
        } else if let home = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController {
            let nav = UINavigationController(rootViewController: home)
            
            switchToRoot(nav)
        }
    }

    private func switchToRoot(_ vc: UIViewController) {
        if let scene = view.window?.windowScene,
           let sceneDelegate = scene.delegate as? SceneDelegate {
            sceneDelegate.setRoot(vc, animated: true)
        } else {
            // Fallback (shouldn’t be needed normally)
            UIApplication.shared.windows.first?.rootViewController = vc
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
    }
    
    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
