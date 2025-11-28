//
//  Constant.swift
//  VCaller
//
//  Created by prk on 11/11/25.
//

import Foundation

var roomObj: [String: String] = [:]
let baseURL = "https://api.whereby.dev/v1/meetings"
let API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmFwcGVhci5pbiIsImF1ZCI6Imh0dHBzOi8vYXBpLmFwcGVhci5pbi92MSIsImV4cCI6OTAwNzE5OTI1NDc0MDk5MSwiaWF0IjoxNzYyODIwNzUwLCJvcmdhbml6YXRpb25JZCI6MzI4NzY3LCJqdGkiOiI0OGQzYjFlMi02YTljLTQ5NGQtYjlkZC00MTUwNDJmYzAzODAifQ.mQWuhmPEhDxzB3RshbQ4DSwuFRJnnqrQvU2Z4Ew94l0"

func createNewRoom() {
    let url = URL(string: baseURL)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let headers: [String: String] = [
        "Authorization": "Bearer \(API_KEY)",
        "Content-Type": "application/json",
    ]
    request.allHTTPHeaderFields = headers
    request.httpBody = try!JSONSerialization.data(withJSONObject: [
        "endDate": String(describing: Calendar.current.date(byAdding: .day, value: 1, to: Date())),
        "isLocked": false,
        "roomMode": "normal",
        "roomNamePrefix": "v-caller",
        "roomNamePattern": "human-short",
    ])
    
    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
        let json = try! JSONSerialization.jsonObject(with: data!) as! [String: String]
        roomObj = json
        
        print(roomObj)
    }).resume()
}

func deleteUsedRoom(meetingId: String) {
    let url = URL(string: "\(baseURL)/\(meetingId)")!
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    let headers: [String: String] = [
        "Authorization": "Bearer \(API_KEY)",
        "Accept": "*/*",
    ]
    request.allHTTPHeaderFields = headers
    
    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
        roomObj = [:]
        print("Room deleted!")
    }).resume()
}

//@IBAction func startVCall(_ sender: Any) {
//    let roomURL = URL(string: roomObj["roomUrl"]!)!
//    let config = WherebyRoomConfig(url: roomURL)
//    let roomVC = WherebyRoomViewController(config: config, isPushedInNavigationController: true)
//    
//    navigationController?.pushViewController(roomVC, animated: true)
//    roomVC.join()
//}
