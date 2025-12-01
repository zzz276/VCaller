//
//  File.swift
//  VCaller
//
//  Created by prk on 01/12/25.
//

import Foundation

// Swift data structure for the successful Whereby API response
struct WherebyRoom: Decodable {
    let meetingId: String
    let roomUrl: String
}

// Data structure for the body sent to your backend's room creation endpoint
struct RoomCreationRequest: Encodable {
    let endDate: String // ISO 8601 string
    let roomMode: String
}
