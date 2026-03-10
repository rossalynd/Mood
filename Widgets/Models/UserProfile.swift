//
//  UserProfile.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import Foundation
import FirebaseFirestore

struct UserProfile {
    let uid: String
    let email: String?
    let username: String
    let usernameLower: String
    let displayName: String
    let emotionSymbol: String?
    let moodGoalPerWeek: Int
    let reminderTimes: [Date]
    let hasCompletedSetup: Bool
    let createdAt: Date
    let updatedAt: Date
}

extension UserProfile {
    init?(from data: [String: Any]) {
        guard
            let uid = data["uid"] as? String,
            let username = data["username"] as? String,
            let displayName = data["displayName"] as? String,
            let moodGoalPerWeek = data["moodGoalPerWeek"] as? Int,
            let hasCompletedSetup = data["hasCompletedSetup"] as? Bool,
            let createdAtTimestamp = data["createdAt"] as? Timestamp,
            let updatedAtTimestamp = data["updatedAt"] as? Timestamp
        else {
            return nil
        }

        self.uid = uid
        self.email = data["email"] as? String
        self.username = username
        self.usernameLower = (data["usernameLower"] as? String) ?? username.lowercased()
        self.displayName = displayName
        self.emotionSymbol = data["emotionSymbol"] as? String
        self.moodGoalPerWeek = data["moodGoalPerWeek"] as? Int ?? 0
        self.hasCompletedSetup = hasCompletedSetup
        self.createdAt = createdAtTimestamp.dateValue()
        self.updatedAt = updatedAtTimestamp.dateValue()

        if let reminderTimestamps = data["reminderTimes"] as? [Timestamp] {
            self.reminderTimes = reminderTimestamps.map { $0.dateValue() }
        } else {
            self.reminderTimes = []
        }
    }

    func firestoreData() -> [String: Any] {
        [
            "uid": uid,
            "email": email as Any,
            "username": username,
            "usernameLower": usernameLower,
            "displayName": displayName,
            "emotionSymbol": emotionSymbol as Any,
            "moodGoalPerWeek": moodGoalPerWeek,
            "reminderTimes": reminderTimes.map { Timestamp(date: $0) },
            "hasCompletedSetup": hasCompletedSetup,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
}
