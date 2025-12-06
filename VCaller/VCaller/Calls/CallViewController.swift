//
//  CallViewController.swift
//  VCaller
//
//  Created by prk on 01/12/25.
//

import Foundation
import UIKit
import WherebySDK

class CallViewController: UIViewController {
    
    var roomURL: String?
    var meetingID: String?
    
    // Instantiate your Signaling Manager here
    var signalingManager: SignalingManager?
    // var wherebyClient: WherebySDKClient? // Assume you initialize the SDK client here

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        guard let url = roomURL, let id = meetingID else {
            // Handle case where room details are missing
            dismiss(animated: true)
            return
        }
        
        // 1. Initialize Signaling
        // The signaling manager will immediately connect and emit 'join_room'
        self.signalingManager = SignalingManager(roomID: id)
        self.signalingManager?.connect()
        
        // 2. Initialize and Join the Whereby SDK (the actual video engine)
        let roomURL = URL(string: url)!
        let config = WherebyRoomConfig(url: roomURL)
        let roomVC = WherebyRoomViewController(config: config, isPushedInNavigationController: true)
        
        navigationController?.pushViewController(roomVC, animated: true)
        roomVC.join()
    }
    
    // Remember to implement disconnection logic when the view is dismissed
    deinit { signalingManager?.disconnect() }
}
