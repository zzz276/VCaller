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
        let roomURL = URL(string: roomObj["roomUrl"]!)!
        let config = WherebyRoomConfig(url: roomURL)
        let roomVC = WherebyRoomViewController(config: config, isPushedInNavigationController: true)
        
        navigationController?.pushViewController(roomVC, animated: true)
        roomVC.join()
    }
    
    @IBAction func btnCall(_ sender: Any) {
        let roomURL = URL(string: roomObj["roomUrl"]!)!
        let config = WherebyRoomConfig(url: roomURL)
        let roomVC = WherebyRoomViewController(config: config, isPushedInNavigationController: true)
        
        navigationController?.pushViewController(roomVC, animated: true)
        roomVC.join()
    }
}
