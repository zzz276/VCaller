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
    
    private let db = Firestore.firestore()
    private let defaults = UserDefaults.standard
    private let signalingManager = SignalingManager.shared
    
    private var currentCallTarget: String?
    private var meetingID = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUsernameDisplay()
        setupNotificationObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reconnect logged in user here.
        if defaults.string(forKey: idKey) != nil {
            Task {
                guard let currentUserId = defaults.string(forKey: idKey) else { return }
                do {
                    try await db.collection("users").document(currentUserId).setData([ "status": "online", ], merge: true)
                    
                    print("You are now logged in!")
                } catch { print("Error when logging in: \(error)") }
                
                signalingManager.connect()
            }
        }
        
        updateUsernameDisplay()
        setupNotificationObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeNotificationObservers()
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
        
        guard let currentUserId = defaults.string(forKey: idKey) else {
            print("CRITICAL ERROR: User ID not found in defaults. Cannot update status.")
            
            return
        }
        
        Task {
            do {
                try await db.collection("users").document(currentUserId).setData([ "status": "offline" ], merge: true)
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
    
    @objc private func handleIncomingCall(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let from = userInfo["from"] as? String,
              let meetingId = userInfo["meetingId"] as? String,
              let roomUrl = userInfo["roomUrl"] as? String else { return }
        
        self.meetingID = meetingId
        guard let currentUserId = defaults.string(forKey: idKey) else { return }
        
        // Show alert with Accept/Reject options
        let alert = UIAlertController(
            title: "Incoming Call",
            message: "Call from \(from)",
            preferredStyle: .alert
        )
        
        // Accept action
        alert.addAction(UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
            self?.signalingManager.acceptCall(from: from, to: currentUserId, roomUrl: roomUrl)
            
            // Navigate to the call room
            self?.navigateToCallRoom(roomUrl: roomUrl)
        })
        
        // Reject action
        alert.addAction(UIAlertAction(title: "Reject", style: .cancel) { _ in self.signalingManager.rejectCall(from: from, to: currentUserId) })
        
        // Present alert on main thread
        DispatchQueue.main.async { [weak self] in self?.present(alert, animated: true) }
    }
    
    @objc private func appWillTerminateOrGoBackground() {
        // 1. Ensure we have a valid user ID to update
        guard let currentUserId = defaults.string(forKey: idKey) else {
            print("Cannot set offline status: User ID not found.")
            
            return
        }

        // 2. Disconnect the socket connection
        signalingManager.disconnect()

        // 3. Update Firestore status to 'offline'
        Task {
            // We use the 'offline' status for general unavailability
            let statusToSet = "offline"
            
            do {
                // We use the synchronous `try await` call here, but since this runs
                // during termination, the OS may kill the app before it completes.
                // However, this is the most correct Swift way.
                try await db.collection("users").document(currentUserId).setData([ "status": statusToSet ], merge: true)
                
                print("Successfully set user \(currentUserId) status to \(statusToSet).")
            } catch { print("Error setting offline status on app termination: \(error.localizedDescription)") }
        }
        
        // IMPORTANT: On app termination, the OS only gives you a small window (typically 5 seconds)
        // to complete background tasks. You rely on the operating system to honor this.
    }
    
    func roomViewControllerDidJoinRoom(_ roomViewController: WherebySDK.WherebyRoomViewController) {
        guard let currentUserId = defaults.string(forKey: idKey) else {
            print("CRITICAL ERROR: User ID not found in defaults. Cannot update status.")
            
            return
        }
        
        Task {
            do {
                try await db.collection("users").document(currentUserId).setData([ "status": "in-vcall" ], merge: true)
                print("You are now joined in the room!")
            } catch { print("Error when joining the room: \(error)") }
        }
    }
    
    func roomViewControllerDidLeave(_ roomViewController: WherebySDK.WherebyRoomViewController) {
        signalingManager.deleteRoom(meetingId: meetingID)
        navigationController?.popViewController(animated: true)
        currentCallTarget = nil
        guard let currentUserId = defaults.string(forKey: idKey) else {
            print("CRITICAL ERROR: User ID not found in defaults. Cannot update status.")
            
            return
        }
        
        Task {
            do {
                try await db.collection("users").document(currentUserId).setData([ "status": "online" ], merge: true)
                print("You are now available for incoming call!")
            } catch { print("Error when leaving the room: \(error)") }
        }
    }
    
    func roomViewControllerDidUpdateCameraEnabled(_ roomViewController: WherebySDK.WherebyRoomViewController, isCameraEnabled: Bool) { defaults.set(isCameraEnabled, forKey: cameraKey) }
    
    func roomViewControllerDidUpdateMicrophoneEnabled(_ roomViewController: WherebySDK.WherebyRoomViewController, isMicrophoneEnabled: Bool) { defaults.set(isMicrophoneEnabled, forKey: microphoneKey) }
    
    private func updateUsernameDisplay() {
        defaults.string(forKey: usernameKey)
        defaults.string(forKey: regionKey)
        defaults.string(forKey: birthdayKey)
        defaults.string(forKey: pronounsKey)
        
        if let name = UserDefaults.standard.string(forKey: usernameKey), !name.isEmpty {
            subtitleLabel.text = "Welcome, \(name)"
        } else {
            subtitleLabel.text = "Welcome"
        }
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
    
    private func navigateToCallRoom(roomUrl: String) {
        guard let roomURL = URL(string: roomUrl) else { return }
        var config = WherebyRoomConfig(url: roomURL)
        config.userDisplayName = UserDefaults.standard.string(forKey: usernameKey)
        let roomVC = WherebyRoomViewController(config: config, isPushedInNavigationController: true)
        roomVC.delegate = self
        
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.pushViewController(roomVC, animated: true)
            roomVC.join()
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
        
        // NEW: Observe when the app is about to terminate (user force-closes or system kills)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminateOrGoBackground),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
            
            // NEW: Observe when the app enters the background (user hits Home button or switches apps)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminateOrGoBackground),
            name: UIApplication.willResignActiveNotification, // or UIApplication.didEnterBackgroundNotification
            object: nil
        )
    }
    
    private func removeNotificationObservers() { NotificationCenter.default.removeObserver(self) }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        let base = UIFont(descriptor: descriptor, size: pointSize)
        
        return UIFontMetrics.default.scaledFont(for: base)
    }
}
