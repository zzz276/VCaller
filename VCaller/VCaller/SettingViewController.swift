//
//  SettingViewController.swift
//  VCaller
//
//  Created by Mac on 28/10/25.
//

import UIKit

class SettingViewController: UIViewController {

    @IBOutlet weak var switchCam: UISwitch!
    @IBOutlet weak var switchMic: UISwitch!
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        loadSettings()
    }
    
    @IBAction func toggleCam(_ sender: UISwitch) {
        // Set the UserDefaults value directly to the switch's new state
        defaults.set(sender.isOn, forKey: cameraKey)
    }

    @IBAction func toggleMic(_ sender: UISwitch) {
        // Set the UserDefaults value directly to the switch's new state
        defaults.set(sender.isOn, forKey: microphoneKey)
    }
    
    private func loadSettings() {
        // 1. Load Camera Setting
        // If the 'cameraKey' has never been set, defaults.bool(forKey:) returns false.
        // If you want the camera ON by default, you must check for its existence or
        // explicitly set a default value elsewhere.
        
        // Assuming the switch should reflect the state *before* the toggle
        // For a toggle switch, it's easier to think of the stored value as the state:
        // true = ON/Enabled, false = OFF/Disabled
        
        // Check if the key has been set. If not, we assume the camera is ON (true)
        let isCameraOn: Bool = defaults.object(forKey: cameraKey) as? Bool ?? true
        switchCam.isOn = isCameraOn

        // 2. Load Microphone Setting
        // Check if the key has been set. If not, we assume the microphone is ON (true)
        let isMicrophoneOn: Bool = defaults.object(forKey: microphoneKey) as? Bool ?? true
        switchMic.isOn = isMicrophoneOn
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
