//
//  UsernameViewController.swift
//  VCaller
//
//  Created by Mac on 27/10/25.
//

import UIKit
import WherebySDK

class UsernameViewController: UIViewController {

    @IBOutlet weak var targetUsername: UITextField!
    private var currentCallTarget: String?
    private var waitingForCallResponse = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotificationObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeNotificationObservers()
    }

    @IBAction func btnCallRandom(_ sender: Any) {
//        createRoom { [weak self] result in
//            
//            switch result {
//            case .success(let roomDetails):
//                print("Room created successfully. URL: \(roomDetails.roomUrl)")
//                        
//                // --- CRUCIAL STEP: Navigate to the Call View ---
//                self?.navigateToCallView(with: roomDetails)
//                
//            case .failure(let error):
//                print("Error creating room: \(error.localizedDescription)")
//                // Handle the error (e.g., show an alert)
//                self?.showErrorAlert(message: "Failed to start call. Please try again.")
//            }
//        }
        
        let roomURL = URL(string: url)!
        let config = WherebyRoomConfig(url: roomURL)
        let roomVC = WherebyRoomViewController(config: config, isPushedInNavigationController: true)
        
        navigationController?.pushViewController(roomVC, animated: true)
        roomVC.join()
    }
    
    @IBAction func btnCall(_ sender: Any) {
        let target = (targetUsername.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else {
            showAlert(title: "Missing Username", message: "Please enter a username!")
            
            return
        }
        
        let defaults = UserDefaults.standard
        guard let currentUserId = defaults.string(forKey: idKey) else {
            showAlert(title: "Error", message: "User not logged in")
            return
        }
        
        // Store the target for later use
        currentCallTarget = target
        waitingForCallResponse = true
        
        // Show waiting alert
        showAlert(title: "Calling...", message: "Calling \(target)")
        
        // Initiate the call through signaling manager
        SignalingManager.shared.callUser(from: currentUserId, to: target)
    }
    
    // Function to navigate to the call view controller
    func navigateToCallView(with room: WherebyRoom) {
        // 1. Instantiate your dedicated Call View Controller
        // This is the view where you integrate the Whereby iOS SDK (or WebRTC UI)
        let callVC = CallViewController()
        
        // 2. Pass the necessary data (the URL for the SDK to join)
        callVC.roomURL = room.roomUrl
        callVC.meetingID = room.meetingId
        
        // 3. Present the new view (using a modal or navigation controller)
        self.present(callVC, animated: true, completion: nil)
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
              let roomUrl = userInfo["roomUrl"] as? String else {
            return
        }
        
        // Navigate to the call room
        navigateToCallRoom(roomUrl: roomUrl)
    }
    
    @objc private func handleCallRejected(_ notification: Notification) {
        guard waitingForCallResponse else { return }
        waitingForCallResponse = false
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Call Rejected", message: "The call was rejected by \(self?.currentCallTarget ?? "the user")")
        }
    }
    
    @objc private func handleRoomCreated(_ notification: Notification) {
        // This is for the caller - room was created, waiting for callee to accept
        // Could show a "Waiting for answer..." message if needed
        print("Room created, waiting for call acceptance...")
    }
    
    private func navigateToCallRoom(roomUrl: String) {
        guard let roomURL = URL(string: roomUrl) else { return }
        
        let config = WherebyRoomConfig(url: roomURL)
        let roomVC = WherebyRoomViewController(config: config, isPushedInNavigationController: true)
        
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.pushViewController(roomVC, animated: true)
            roomVC.join()
        }
    }
}
