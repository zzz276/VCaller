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

    private init() {
        self.manager = SocketManager(socketURL: URL(string: "https://vcaller-qi8o.onrender.com")!, config: [.log(true), .compress, .forceWebsockets(true)])
        self.socket = manager.defaultSocket
        
        listeners()
    }

    // Connect and start listening for events
    func connect() {
        if socket.status == .connected || socket.status == .connecting {
            print("Socket is already connected or connecting. Skipping connect() call.")
            
            return
        }
        
        socket.off(clientEvent: .connect)
        
        socket.on(clientEvent: .connect) { _, _ in
            guard let userId = self.defaults.string(forKey: idKey) else {
                print("Registration Failed: User ID not found in UserDefaults.")
                return
            }
            
            // 2. Emit the 'register' event only if the socket is connected
            if self.socket.status == .connected {
                print("Connected to signaling server")
                self.socket.emit("register", userId)
                print("Registered user \(userId) with the signaling server.")
            } else { print("Registration deferred: Socket not yet connected.") }
        }
        
        socket.connect()
    }
    
    func listeners() {
        socket.on("getRequest") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let meetingId = dict["meetingId"] as? String,
                  let roomUrl = dict["roomUrl"] as? String else { return }
            
            print("Room created - Meeting ID: \(meetingId), Room URL: \(roomUrl)")
            
            NotificationCenter.default.post(name: .roomCreated, object: nil, userInfo: [
                "meetingId": meetingId,
                "roomUrl": roomUrl
            ])
        }
        
        socket.on("callRequest") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let from = dict["from"] as? String,
                  let meetingId = dict["meetingId"] as? String,
                  let roomUrl = dict["roomUrl"] as? String else { return }
            
            print("Incoming call from \(from)")
            print("Meeting ID: \(meetingId)")
            print("Room URL: \(roomUrl)")
            
            NotificationCenter.default.post(name: .incomingCall, object: nil, userInfo: [
                "from": from,
                "meetingId": meetingId,
                "roomUrl": roomUrl
            ])
        }
        
        socket.on("callAccepted") { data, _ in
            guard let dict = data.first as? [String: Any],
                  let meetingId = dict["meetingId"] as? String,
                  let roomUrl = dict["roomUrl"] as? String else { return }
            
            print("Call accepted, opening room: \(roomUrl), room ID: \(meetingId)")
            NotificationCenter.default.post(name: .callAccepted, object: nil, userInfo: [ "meetingId": meetingId, "roomUrl": roomUrl ])
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
    
    func acceptCall(from: String, to: String, meetingId: String, roomUrl: String) {
        socket.emit("acceptCall", [
            "from": from,
            "to": to,
            "meetingId": meetingId,
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

    func deleteRoom(meetingId: String) { socket.emit("deleteRoom", meetingId) }
    
    // Disconnect
    func disconnect() { socket.disconnect() }
}

extension Notification.Name {
    static let incomingCall = Notification.Name("incomingCall")
    static let callAccepted = Notification.Name("callAccepted")
    static let callRejected = Notification.Name("callRejected")
    static let signalReceived = Notification.Name("signalReceived")
    static let roomCreated = Notification.Name("roomCreated")
}
