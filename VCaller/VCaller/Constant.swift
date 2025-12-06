//
//  Constant.swift
//  VCaller
//
//  Created by prk on 11/11/25.
//

import Foundation

let url = "https://v-caller.whereby.com/v-call7bba86d2-1359-4f1b-a807-170ab2df455f"
var id = ""

func generateRandomString() -> String {
    let allowedCharactersArray = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    var result = ""
    
    for _ in 0..<10 { result.append(allowedCharactersArray.randomElement()!) }
    
    return result
}

//var roomObj: [String: String] = [:]
//let API_KEY = ""
//let baseURL = "https://api.whereby.dev/v1/meetings"
//
//func createNewRoom() {
//    let url = URL(string: baseURL)!
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    let headers: [String: String] = [
//        "Authorization": "Bearer \(API_KEY)",
//        "Content-Type": "application/json",
//    ]
//    request.allHTTPHeaderFields = headers
//    request.httpBody = try!JSONSerialization.data(withJSONObject: [
//        "endDate": String(describing: Calendar.current.date(byAdding: .day, value: 1, to: Date())),
//        "isLocked": false,
//        "roomMode": "normal",
//        "roomNamePrefix": "v-caller",
//        "roomNamePattern": "human-short",
//    ])
//    
//    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
//        let json = try! JSONSerialization.jsonObject(with: data!) as! [String: String]
//        roomObj = json
//        
//        print(roomObj)
//    }).resume()
//}
//
//func deleteUsedRoom(meetingId: String) {
//    let url = URL(string: "\(baseURL)/\(meetingId)")!
//    var request = URLRequest(url: url)
//    request.httpMethod = "DELETE"
//    let headers: [String: String] = [
//        "Authorization": "Bearer \(API_KEY)",
//        "Accept": "*/*",
//    ]
//    request.allHTTPHeaderFields = headers
//    
//    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
//        roomObj = [:]
//        print("Room deleted!")
//    }).resume()
//}
//
//@IBAction func startVCall(_ sender: Any) {
//    let roomURL = URL(string: roomObj["roomUrl"]!)!
//    let config = WherebyRoomConfig(url: roomURL)
//    let roomVC = WherebyRoomViewController(config: config, isPushedInNavigationController: true)
//    
//    navigationController?.pushViewController(roomVC, animated: true)
//    roomVC.join()
//}
