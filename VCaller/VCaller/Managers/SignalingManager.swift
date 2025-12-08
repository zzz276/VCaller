//
//  SignalingManager.swift
//  VCaller
//
//  Created by prk on 01/12/25.
//

import Foundation
import SocketIO

final class SignalingManager {
    static let shared = SignalingManager()
    private let manager: SocketManager
    private let socket: SocketIOClient
    
    private let defaults = UserDefaults.standard

    private init(roomID: String) {
        self.manager = SocketManager(socketURL: URL(string: "http://localhost:3000")!, config: [.log(true), .compress, .forceWebsockets(true)])
        self.socket = manager.defaultSocket
        
        listeners()
    }

    // Connect and start listening for events
    func connect() {
        socket.connect()
        
        socket.on(clientEvent: .connect) { _, _ in
            print("Connected to signaling server")
            self.socket.emit("register", self.defaults.string(forKey: idKey)!)
        }
    }
    
    func listeners() {
        socket.on("callRequest") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let from = dict["from"] as? String,
                  let roomUrl = dict["roomUrl"] as? String else { return }
            
            print("Incoming call from \(from)")
            print("Room URL: \(roomUrl)")
            
            NotificationCenter.default.post(name: .incomingCall, object: nil, userInfo: [
                "from": from,
                "roomUrl": roomUrl
            ])
        }
        
        socket.on("callAccepted") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let roomUrl = dict["roomUrl"] as? String else { return }
            
            print("Call accepted, opening room: \(roomUrl)")
            
            NotificationCenter.default.post(name: .callAccepted, object: nil, userInfo: [ "roomUrl": roomUrl ])
        }
        
        socket.on("callRejected") { _, _ in
            print("Call rejected")
            
            NotificationCenter.default.post(name: .callRejected, object: nil)
        }
        
        socket.on("signal") { data, _ in
            guard let dict = data.first as? [String: Any] else { return }
            
            print("Received signaling data: \(dict)")
            
            NotificationCenter.default.post(name: .signalReceived, object: nil, userInfo: dict)
        }
        
        socket.on(clientEvent: .disconnect) { data, _ in print("Disconnected: \(data)") }
    }
    
    func callUser(from: String, to: String) {
        socket.emit("callUser", [
            "from": from,
            "to": to
        ])
    }
    
    func acceptCall(from: String, to: String, roomUrl: String) {
        socket.emit("acceptCall", [
            "from": from,
            "to": to,
            "roomUrl": roomUrl
        ])
    }
    
    func rejectCall(from: String, to: String) {
        socket.emit("rejectCall", [
            "from": from,
            "to": to
        ])
    }
    
    func sendSignal(_ data: [String: Any]) { socket.emit("signal", data) }
    
    // Disconnect
    func disconnect() { socket.disconnect() }
}

extension Notification.Name {
    static let incomingCall = Notification.Name("incomingCall")
    static let callAccepted = Notification.Name("callAccepted")
    static let callRejected = Notification.Name("callRejected")
    static let signalReceived = Notification.Name("signalReceived")
}
