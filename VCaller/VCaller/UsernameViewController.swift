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
    override func viewDidLoad() { super.viewDidLoad() }

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
        
        let roomURL = URL(string: url)!
        let config = WherebyRoomConfig(url: roomURL)
        let roomVC = WherebyRoomViewController(config: config, isPushedInNavigationController: true)
        
        navigationController?.pushViewController(roomVC, animated: true)
        roomVC.join()
        
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
//                self?.showAlert(message: "Failed to start call. Please try again.")
//            }
//        }
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
}
