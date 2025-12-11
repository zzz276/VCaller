//
//  Constant.swift
//  VCaller
//
//  Created by prk on 11/11/25.
//

import Foundation

let url = "https://v-caller.whereby.com/v-call7bba86d2-1359-4f1b-a807-170ab2df455f"
let idKey = "id"
let usernameKey = "username"
let regionKey = "region"
let birthdayKey = "birthday"
let pronounsKey = "pronouns"
let cameraKey = "Camera"
let microphoneKey = "Microphone"

func generateRandomString() -> String {
    let allowedCharactersArray = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    var result = ""
    
    for _ in 0..<10 { result.append(allowedCharactersArray.randomElement()!) }
    
    return result
}
