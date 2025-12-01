//
//  ProfileUpdateViewController.swift
//  VCaller
//
//  Created by Mac on 14/11/25.
//

import UIKit

class ProfileUpdateViewController: UIViewController {

    // Outlets for editing profile
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var regionTextField: UITextField!
    @IBOutlet weak var birthdayTextField: UITextField!
    @IBOutlet weak var pronounsTextField: UITextField!

    private let usernameKey = "username"
    private let regionKey = "region"
    private let birthdayKey = "birthday"
    private let pronounsKey = "pronouns"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        preloadFields()
    }

    private func preloadFields() {
        let defaults = UserDefaults.standard
        usernameTextField.text = defaults.string(forKey: usernameKey)
        regionTextField.text = defaults.string(forKey: regionKey)
        birthdayTextField.text = defaults.string(forKey: birthdayKey)
        pronounsTextField.text = defaults.string(forKey: pronounsKey)

        // Optional keyboard settings
        usernameTextField.autocorrectionType = .no
        usernameTextField.autocapitalizationType = .none
        regionTextField.autocorrectionType = .no
        regionTextField.autocapitalizationType = .words
        pronounsTextField.autocorrectionType = .no
        pronounsTextField.autocapitalizationType = .none
    }

    // Connect your "Save" button to this action
    @IBAction func saveTapped(_ sender: UIButton) {
        let defaults = UserDefaults.standard

        let username = (usernameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let region = (regionTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let birthday = (birthdayTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let pronouns = (pronounsTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        // Save all fields (empty strings allowed per your note)
        defaults.set(username, forKey: usernameKey)
        defaults.set(region, forKey: regionKey)
        defaults.set(birthday, forKey: birthdayKey)
        defaults.set(pronouns, forKey: pronounsKey)

        // Pop back to Profile, which will refresh in viewWillAppear
        navigationController?.popViewController(animated: true)
    }
}
