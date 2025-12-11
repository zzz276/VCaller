//
//  ViewController.swift
//  VCaller
//
//  Created by Mac on 27/10/25.
//

import FirebaseFirestore
import UIKit
import WherebySDK

class ViewController: UIViewController, WherebyRoomViewControllerDelegate {
        
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    let db = Firestore.firestore()
    let signalingManager = SignalingManager.shared
    let defaults = UserDefaults.standard
    private var meetingID = ""
    private var currentCallTarget: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUsernameDisplay()
        setupNotificationObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUsernameDisplay()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeNotificationObservers()
    }
    
    func roomViewControllerDidJoinRoom(_ roomViewController: WherebySDK.WherebyRoomViewController) {
        Task {
            do {
                try await db.collection("users").document(defaults.string(forKey: idKey)!).setData([ "status": "in-vcall" ], merge: true)
                print("You are now joined in the room!")
            } catch { print("Error when joining the room: \(error)") }
        }
    }
    
    func roomViewControllerDidLeave(_ roomViewController: WherebySDK.WherebyRoomViewController) {
        signalingManager.deleteRoom(meetingId: meetingID)
        navigationController?.popViewController(animated: true)
        currentCallTarget = nil
        
        Task {
            do {
                try await db.collection("users").document(defaults.string(forKey: idKey)!).setData([ "status": "online" ], merge: true)
                print("You are now available for incoming call!")
            } catch { print("Error when leaving the room: \(error)") }
        }
    }
    
    func roomViewControllerDidUpdateMicrophoneEnabled(_ roomViewController: WherebySDK.WherebyRoomViewController, isMicrophoneEnabled: Bool) {
        
    }
    
    func roomViewControllerDidUpdateCameraEnabled(_ roomViewController: WherebySDK.WherebyRoomViewController, isCameraEnabled: Bool) {
        
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
        // Disconnect from signaling server
        signalingManager.disconnect()
        
        Task {
            do {
                try await db.collection("users").document(defaults.string(forKey: idKey)!).setData([ "status": "offline" ], merge: true)
                print("You are now logged out!")
            } catch { print("Error when logging out: \(error)") }
            
            defaults.removeObject(forKey: usernameKey)
            defaults.removeObject(forKey: regionKey)
            defaults.removeObject(forKey: birthdayKey)
            defaults.removeObject(forKey: pronounsKey)
        }
        
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
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleIncomingCall(_:)),
            name: .incomingCall,
            object: nil
        )
    }
    
    private func removeNotificationObservers() { NotificationCenter.default.removeObserver(self) }
    
    @objc private func handleIncomingCall(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let from = userInfo["from"] as? String,
              let meetingId = userInfo["meetingId"] as? String,
              let roomUrl = userInfo["roomUrl"] as? String else {
            return
        }
        
        guard let currentUserId = defaults.string(forKey: idKey) else { return }
        
        // Show alert with Accept/Reject options
        let alert = UIAlertController(
            title: "Incoming Call",
            message: "Call from \(from)",
            preferredStyle: .alert
        )
        
        // Accept action
        alert.addAction(UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
            self?.signalingManager.acceptCall(from: from, to: currentUserId, meetingId: meetingId, roomUrl: roomUrl)
            
            // Navigate to the call room
            self?.navigateToCallRoom(roomUrl: roomUrl)
        })
        
        // Reject action
        alert.addAction(UIAlertAction(title: "Reject", style: .cancel) { _ in
            self.signalingManager.rejectCall(from: from, to: currentUserId)
        })
        
        // Present alert on main thread
        DispatchQueue.main.async { [weak self] in
            self?.present(alert, animated: true)
        }
    }
    
    private func navigateToCallRoom(roomUrl: String) {
        guard let roomURL = URL(string: roomUrl) else { return }
        var config = WherebyRoomConfig(url: roomURL)
        config.userDisplayName = UserDefaults.standard.string(forKey: usernameKey)
        let roomVC = WherebyRoomViewController(config: config, isPushedInNavigationController: true)
        roomVC.delegate = self
        
//        DispatchQueue.main.async { [weak self] in
//            self?.navigationController?.pushViewController(roomVC, animated: true)
//            roomVC.join()
//        }
        navigationController?.pushViewController(roomVC, animated: true)
        roomVC.join()
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        let base = UIFont(descriptor: descriptor, size: pointSize)
        
        return UIFontMetrics.default.scaledFont(for: base)
    }
}
