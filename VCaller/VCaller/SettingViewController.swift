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
        
    }
    
    @IBAction func toggleCam(_ sender: Any) {
        if !defaults.bool(forKey: cameraKey) { defaults.set(true, forKey: cameraKey) }
        else { defaults.set(false, forKey: cameraKey) }
    }
    
    @IBAction func toggleMic(_ sender: Any) {
        if !defaults.bool(forKey: microphoneKey) { defaults.set(true, forKey: microphoneKey) }
        else { defaults.set(false, forKey: microphoneKey) }
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
