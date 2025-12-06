//
//  WherebyAPI.swift
//  VCaller
//
//  Created by prk on 01/12/25.
//

import Foundation

func createRoom(completion: @escaping (Result<WherebyRoom, Error>) -> Void) {
    // ⚠️ IMPORTANT: This URL should point to YOUR Node.js/Backend endpoint,
    // which handles the API Key security and makes the actual Whereby call.
    guard let url = URL(string: "https://your-backend.com/api/create-room") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            // Handle no data error
            return
        }

        do {
            let room = try JSONDecoder().decode(WherebyRoom.self, from: data)
            DispatchQueue.main.async {
                completion(.success(room))
            }
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
    task.resume()
}

//func deleteRoom(meetingId: String, completion: @escaping (Result<Void, Error>) -> Void) {
//    // ⚠️ This URL points to your Node.js/Backend endpoint,
//    // e.g., "https://your-backend.com/api/delete-room/123456"
//    guard let url = URL(string: "https://your-backend.com/api/delete-room/\(meetingId)") else {
//        completion(.failure(AppError.invalidURL))
//        return
//    }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "DELETE"
//    
//    // Include any necessary authentication for your backend (e.g., a user session token)
//    // request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
//
//    let task = URLSession.shared.dataTask(with: request) { data, response, error in
//        if let error = error {
//            completion(.failure(error))
//            return
//        }
//
//        // 204 No Content is the successful status for DELETE requests.
//        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
//            DispatchQueue.main.async {
//                completion(.success(())) // Success
//            }
//        } else {
//            // Handle error response from your backend
//            DispatchQueue.main.async {
//                completion(.failure(AppError.deletionFailed))
//            }
//        }
//    }
//    task.resume()
//}
