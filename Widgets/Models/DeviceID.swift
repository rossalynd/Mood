//
//  DeviceID.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//


import Foundation

enum DeviceID {
    
    private static let key = "app.device.id"
    
    static func current() -> String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }
}
