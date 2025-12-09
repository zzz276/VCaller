//
//  UsernameViewController.swift
//  VCaller
//
//  Created by Mac on 27/10/25.
//

import FirebaseFirestore
import UIKit
import WherebySDK

class UsernameViewController: UIViewController, WherebyRoomViewControllerDelegate {
    
    let db = Firestore.firestore()
    let defaults = UserDefaults.standard
    let signalingManager = SignalingManager.shared
    var meetingID = ""
    var roomUrl = ""
    @IBOutlet weak var targetUsername: UITextField!
    private var currentCallTarget: String?
    private var waitingForCallResponse = false
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotificationObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeNotificationObservers()
    }

    @IBAction func btnCallRandom(_ sender: Any) {
        var randomTarget: [String]?
        var targetId = ""
        
        Task {
            do {
                let querySnapshot = try await db.collection("users").whereField("username", isNotEqualTo: defaults.string(forKey: usernameKey) as Any).whereField("status", isEqualTo: "online").getDocuments()
                
                if querySnapshot.documents.isEmpty {
                    showAlert(title: "No Online Target", message: "No target user is online.")
                    
                    return
                }
                
                for document in querySnapshot.documents { randomTarget?.append(document.documentID) }
            } catch { print("Error when calling random user: \(error)") }
        }
        
        targetId = (randomTarget?.randomElement() as? String)!
        
        // Store the target for later use
        currentCallTarget = targetId
        waitingForCallResponse = true
        
        // Show waiting alert
        showAlert(title: "Calling...", message: "Calling user ID \(targetId)")
        
        // Initiate the call through signaling manager
        signalingManager.callUser(from: defaults.string(forKey: idKey)!, to: targetId)
    }
    
    @IBAction func btnCall(_ sender: Any) {
        let target = (targetUsername.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var targetId = ""
        
        guard !target.isEmpty else {
            showAlert(title: "Missing Username", message: "Please enter a username!")
            
            return
        }
        
        Task {
            let querySnapshot = try await db.collection("users").whereField("username", isEqualTo: target).getDocuments()
            
            if querySnapshot.documents.count == 1 { targetId = querySnapshot.documents[0].documentID }
            else {
                showAlert(title: "Target Offline", message: "Target user is offline.")
                
                return
            }
        }
        
        // Store the target for later use
        currentCallTarget = targetId
        waitingForCallResponse = true
        
        // Show waiting alert
        showAlert(title: "Calling...", message: "Calling user ID \(targetId)")
        
        // Initiate the call through signaling manager
        signalingManager.callUser(from: defaults.string(forKey: idKey)!, to: targetId)
    }
    
    // Simple error utility (optional)
    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCallAccepted(_:)),
            name: .callAccepted,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCallRejected(_:)),
            name: .callRejected,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRoomCreated(_:)),
            name: .roomCreated,
            object: nil
        )
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleCallAccepted(_ notification: Notification) {
        guard waitingForCallResponse else { return }
        waitingForCallResponse = false
        
        guard let userInfo = notification.userInfo,
              let meetingId = userInfo["meetingId"] as? String,
              let roomUrl = userInfo["roomUrl"] as? String else { return }
        
        // Navigate to the call room
        navigateToCallRoom()
    }
    
    @objc private func handleCallRejected(_ notification: Notification) {
        guard waitingForCallResponse else { return }
        waitingForCallResponse = false
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Call Rejected", message: "The call was rejected by \(self?.currentCallTarget ?? "a user")")
        }
    }
    
    @objc private func handleRoomCreated(_ notification: Notification) {
        // This is for the caller - room was created, waiting for callee to accept
        // Could show a "Waiting for answer..." message if needed
        print("Room created, waiting for call acceptance...")
    }
    
    private func navigateToCallRoom() {
        let roomURL = URL(string: roomUrl)!
        var config = WherebyRoomConfig(url: roomURL)
        config.userDisplayName = UserDefaults.standard.string(forKey: usernameKey)
        let roomVC = WherebyRoomViewController(config: config, isPushedInNavigationController: true)
        roomVC.delegate = self
        
        navigationController?.pushViewController(roomVC, animated: true)
        roomVC.join()
    }
}
