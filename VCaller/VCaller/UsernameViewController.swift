//
//  UsernameViewController.swift
//  VCaller
//
//  Created by Mac on 27/10/25.
//

import UIKit
import WherebySDK

class UsernameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Username"
    }

    @IBAction func btnCallRandom(_ sender: Any) {
        createRoom { [weak self] result in
            
            switch result {
            case .success(let roomDetails):
                print("Room created successfully. URL: \(roomDetails.roomUrl)")
                        
                // --- CRUCIAL STEP: Navigate to the Call View ---
                self?.navigateToCallView(with: roomDetails)
                
            case .failure(let error):
                print("Error creating room: \(error.localizedDescription)")
                // Handle the error (e.g., show an alert)
                self?.showErrorAlert(message: "Failed to start call. Please try again.")
            }
        }
    }
    
    @IBAction func btnCall(_ sender: Any) {
        createRoom { [weak self] result in
            
            switch result {
            case .success(let roomDetails):
                print("Room created successfully. URL: \(roomDetails.roomUrl)")
                        
                // --- CRUCIAL STEP: Navigate to the Call View ---
                self?.navigateToCallView(with: roomDetails)
                
            case .failure(let error):
                print("Error creating room: \(error.localizedDescription)")
                // Handle the error (e.g., show an alert)
                self?.showErrorAlert(message: "Failed to start call. Please try again.")
            }
        }
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
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
