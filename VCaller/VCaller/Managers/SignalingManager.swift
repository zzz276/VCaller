//
//  SignalingManager.swift
//  VCaller
//
//  Created by prk on 01/12/25.
//

import Foundation
import SocketIO

class SignalingManager: ObservableObject {
    private var manager: SocketManager
    private var socket: SocketIOClient

    init(roomID: String) {
        // 1. Initialize SocketManager
        // Point to your running Node.js server
        self.manager = SocketManager(socketURL: URL(string: "http://localhost:3000")!,
                                      config: [.log(true), .compress])
        
        self.socket = manager.defaultSocket
        
        // 2. Set up Handlers (Connection and Signaling)
        setupHandlers(roomID: roomID)
    }

    // Connect and start listening for events
    func connect() { socket.connect() }
    
    // Disconnect
    func disconnect() { socket.disconnect() }

    // Send a signaling message to the Node.js server
    func sendSignalingMessage(roomName: String, targetId: String?, payload: [String: Any]) {
        // Match the structure the Node.js server expects
        let data: [String: Any] = [
            "room": roomName,
            "targetId": targetId as Any, // targetId is optional in broadcast
            "payload": payload
        ]
        
        // Emit the event name that your Node.js server is listening for
        socket.emit("signaling_message", data)
    }

    // 3. Define Event Listeners
    private func setupHandlers(roomID: String) {
        // Connection events
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            print("Socket Connected!")
            // ⚠️ Crucial Step: Join the room once connected
            self?.socket.emit("join_room", roomID)
        }
        
        socket.on(clientEvent: .disconnect) { data, ack in
            print("Socket Disconnected.")
        }

        // Signaling message listener
        // When your Node.js server relays a message (SDP, ICE, etc.)
        socket.on("signaling_message") { data, ack in
            guard let dictionary = data[0] as? [String: Any] else { return }
            
            // This dictionary is the 'payload' that contains the SDP or ICE candidate.
            // You pass this data directly to your WebRTC client (e.g., Google WebRTC library).
            print("Received Signaling Message:", dictionary)
            
            // Example: check message type and hand off to WebRTC
            if let type = dictionary["type"] as? String, type == "offer" {
                // Handle SDP Offer
            }
        }
        
        // Other events (e.g., user joined/left)
        socket.on("user_joined") { data, ack in
            print("A new user joined with ID:", data[0])
            // Update UI or initiate an offer to the new user
        }
    }
    
    // Swift SignalingManager Extension

    private func setupRoomClosureHandler() {
        socket.on("room_closed") { [weak self] data, ack in
            print("Received room_closed event. Disconnecting.")
            
            // 1. Disconnect the Socket.IO connection
            self?.socket.disconnect()
            
            // 2. Instruct the Whereby SDK to leave the meeting (if applicable)
            // wherebySDKClient.leaveRoom()
            
        }
    }
}
