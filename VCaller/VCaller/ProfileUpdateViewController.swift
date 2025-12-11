//
//  ProfileUpdateViewController.swift
//  VCaller
//
//  Created by Mac on 14/11/25.
//

import FirebaseFirestore
import UIKit

class ProfileUpdateViewController: UIViewController {
    
    // Outlets for editing profile
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var regionTextField: UITextField!
    @IBOutlet weak var birthdayTextField: UITextField!
    @IBOutlet weak var pronounsTextField: UITextField!
    private let db = Firestore.firestore()

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
        
        if region.isEmpty {
            showAlert(title: "Invalid Region", message: "Please enter a valid region!")
            
            return
        }
        
        if validateBirthday(bd: birthday) == false {
            showAlert(title: "Invalid Birthday", message: "Please enter a valid birthday!")
            
            return
        }
        
        if pronouns.isEmpty {
            showAlert(title: "Invalid Pronouns", message: "Please enter a valid pronouns!")
            
            return
        }
        
        // Save all fields (empty strings allowed per your note)
        Task {
            do {
                try await db.collection("users").document(defaults.string(forKey: idKey)!).setData([
                    usernameKey: username,
                    regionKey: region,
                    birthdayKey: birthday,
                    pronounsKey: pronouns,
                ], merge: true)
                
                print("Your profile is updated!")
            } catch { print("Error when updating: \(error)") }
        }
        
        defaults.set(username, forKey: usernameKey)
        defaults.set(region, forKey: regionKey)
        defaults.set(birthday, forKey: birthdayKey)
        defaults.set(pronouns, forKey: pronounsKey)

        // Pop back to Profile, which will refresh in viewWillAppear
        navigationController?.popViewController(animated: true)
    }
    
    func validateBirthday(bd: String) -> Bool {
        let pattern = #"^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|[0-2])/(19\d{2}|20\d{2})$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        
        let range = NSRange(location: 0, length: bd.utf16.count)
        
        guard regex.firstMatch(in: bd, range: range) != nil else { return false }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: (7 * 60 * 60))
        formatter.isLenient = false
        guard let date = formatter.date(from: bd) else { return false }
        
        if date > Date() { return false }
        let calendar = Calendar.current
        if let age = calendar.dateComponents([.year], from: date, to: Date()).year, age < 0 || age > 130 { return false }
        
        return true
    }
    
    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
