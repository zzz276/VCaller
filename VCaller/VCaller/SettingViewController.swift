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
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
    }
    
    @IBAction func toggleMic(_ sender: Any) {
        if !UserDefaults.standard.bool(forKey: "Microphone") { UserDefaults.standard.set(true, forKey: "Microphone") }
        else { UserDefaults.standard.set(false, forKey: "Microphone") }
    }
    
    @IBAction func toggleCam(_ sender: Any) {
        if !UserDefaults.standard.bool(forKey: "Camera") { UserDefaults.standard.set(true, forKey: "Camera") }
        else { UserDefaults.standard.set(false, forKey: "Camera") }
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
