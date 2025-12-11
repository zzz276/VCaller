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
    
    @IBOutlet weak var targetUsername: UITextField!
    let db = Firestore.firestore()
    let defaults = UserDefaults.standard
    let signalingManager = SignalingManager.shared
    private var meetingID = ""
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
        Task {
            var randomTarget: [String] = []
            var targetId = ""
            
            do {
                let querySnapshot = try await db.collection("users").whereField("username", isNotEqualTo: defaults.string(forKey: usernameKey) as Any).whereField("status", isEqualTo: "online").getDocuments()
                
                if querySnapshot.documents.isEmpty {
                    showAlert(title: "No Online Target", message: "No target user is online.")
                    
                    return
                }
                
                for document in querySnapshot.documents { randomTarget.append(document.documentID) }
                targetId = (randomTarget.randomElement())!
                
                // Store the target for later use
                currentCallTarget = targetId
                waitingForCallResponse = true
                
                // Show waiting alert
                showAlert(title: "Calling...", message: "Calling user ID \(targetId)")
                
                // Initiate the call through signaling manager
                signalingManager.callUser(from: defaults.string(forKey: idKey)!, to: targetId)
            } catch { print("Error when calling random user: \(error)") }
        }
    }
    
    @IBAction func btnCall(_ sender: Any) {
        let target = (targetUsername.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !target.isEmpty else {
            showAlert(title: "Missing Username", message: "Please enter a username!")
            
            return
        }
        
        Task {
            var targetId = ""
            
            do {
                let querySnapshot = try await db.collection("users").whereField("username", isEqualTo: target).whereField("status", isEqualTo: "online").getDocuments()
                
                if querySnapshot.documents.count == 1 { targetId = querySnapshot.documents[0].documentID }
                else {
                    showAlert(title: "Target Unavailable", message: "Target user is either offline or unavailable.")
                    
                    return
                }
                
                // Store the target for later use
                currentCallTarget = targetId
                waitingForCallResponse = true
                
                // Show waiting alert
                showAlert(title: "Calling...", message: "Calling user ID \(targetId)")
                
                // Initiate the call through signaling manager
                signalingManager.callUser(from: defaults.string(forKey: idKey)!, to: targetId)
            } catch { print("Error when retrieving other user ID: \(error)") }
        }
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleIncomingCall(_:)),
            name: .incomingCall,
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
        navigateToCallRoom(roomUrl: roomUrl)
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
    
    @objc private func handleIncomingCall(_ notification: Notification) {
        // Ensure you are on the main thread when updating UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  // Extract data passed from SignalingManager
                  let userInfo = notification.userInfo,
                  let fromUserID = userInfo["from"] as? String,
                  let meetingId = userInfo["meetingId"] as? String,
                  let roomUrl = userInfo["roomUrl"] as? String else { return }

            // Store the sender's ID in case the user accepts/rejects
            self.currentCallTarget = fromUserID
            self.meetingID = meetingId // Store the ID for room cleanup later

            // 1. Fetch the Username of the caller for a friendly display
            self.fetchUsername(for: fromUserID) { callerUsername in
                let displayUsername = callerUsername ?? fromUserID

                let alertController = UIAlertController(
                    title: "Incoming Call",
                    message: "Call from \(displayUsername). Do you want to answer?",
                    preferredStyle: .alert
                )

                // 2. Add ACCEPT action
                let acceptAction = UIAlertAction(title: "Accept", style: .default) { _ in
                    // Inform the caller (via server) that the call is accepted
                    self.signalingManager.acceptCall(
                        from: self.defaults.string(forKey: idKey)!,
                        to: fromUserID,
                        meetingId: meetingId,
                        roomUrl: roomUrl
                    )
                    // Navigate to the call room immediately
                    self.navigateToCallRoom(roomUrl: roomUrl)
                }

                // 3. Add REJECT action
                let rejectAction = UIAlertAction(title: "Reject", style: .cancel) { _ in
                    // Inform the caller (via server) that the call is rejected
                    self.signalingManager.rejectCall(
                        from: self.defaults.string(forKey: idKey)!,
                        to: fromUserID
                    )
                    self.currentCallTarget = nil // Clear the target
                    self.meetingID = ""
                }

                alertController.addAction(acceptAction)
                alertController.addAction(rejectAction)
                self.present(alertController, animated: true)
            }
        }
    }

    // You will also need this helper function to look up the username
    // based on the Firestore logic already present in your file.
    private func fetchUsername(for id: String, completion: @escaping (String?) -> Void) {
        Task {
            do {
                let document = try await db.collection("users").document(id).getDocument()
                let username = document.data()?["username"] as? String
                completion(username)
            } catch {
                print("Error fetching username for ID \(id): \(error)")
                completion(nil)
            }
        }
    }
    
    private func navigateToCallRoom(roomUrl: String) {
        guard let roomURL = URL(string: roomUrl) else { return }
        var config = WherebyRoomConfig(url: roomURL)
        config.userDisplayName = UserDefaults.standard.string(forKey: usernameKey)
        let roomVC = WherebyRoomViewController(config: config, isPushedInNavigationController: true)
        roomVC.delegate = self
        
        navigationController?.pushViewController(roomVC, animated: true)
        roomVC.join()
    }
}
