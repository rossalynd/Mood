//
//  UserProfile.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//

//
//  UserProfile.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//

import Foundation
import FirebaseFirestore

// MARK: - Private Profile (users/{uid})
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
    let allowsFriendRequests: Bool
    let isDiscoverable: Bool

    // Mood stats
    let streakCount: Int
    let totalMoodCount: Int
    let lastMoodDate: Date?
}

extension UserProfile {
    init?(from data: [String: Any]) {
        guard
            let uid = data["uid"] as? String,
            let username = data["username"] as? String,
            let displayName = data["displayName"] as? String,
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
        self.allowsFriendRequests = data["allowsFriendRequests"] as? Bool ?? true
        self.isDiscoverable = data["isDiscoverable"] as? Bool ?? true
        self.streakCount = data["streakCount"] as? Int ?? 0
        self.totalMoodCount = data["totalMoodCount"] as? Int ?? 0

        if let lastMoodTimestamp = data["lastMoodDate"] as? Timestamp {
            self.lastMoodDate = lastMoodTimestamp.dateValue()
        } else {
            self.lastMoodDate = nil
        }

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
            "updatedAt": Timestamp(date: updatedAt),
            "allowsFriendRequests": allowsFriendRequests,
            "isDiscoverable": isDiscoverable,
            "streakCount": streakCount,
            "totalMoodCount": totalMoodCount,
            "lastMoodDate": lastMoodDate.map { Timestamp(date: $0) } as Any
        ]
    }
}

// MARK: - Shared/Public Profile (publicUsers/{uid})
struct PublicUserProfile {
    let uid: String
    let username: String
    let usernameLower: String
    let displayName: String
    let emotionSymbol: String?
    let createdAt: Date
    let updatedAt: Date
    let isDiscoverable: Bool

    // Shared mood stat
    let streakCount: Int
}

extension PublicUserProfile {
    init?(from data: [String: Any]) {
        guard
            let uid = data["uid"] as? String,
            let username = data["username"] as? String,
            let displayName = data["displayName"] as? String,
            let createdAtTimestamp = data["createdAt"] as? Timestamp,
            let updatedAtTimestamp = data["updatedAt"] as? Timestamp
        else {
            return nil
        }

        self.uid = uid
        self.username = username
        self.usernameLower = (data["usernameLower"] as? String) ?? username.lowercased()
        self.displayName = displayName
        self.emotionSymbol = data["emotionSymbol"] as? String
        self.createdAt = createdAtTimestamp.dateValue()
        self.updatedAt = updatedAtTimestamp.dateValue()
        self.isDiscoverable = data["isDiscoverable"] as? Bool ?? true
        self.streakCount = data["streakCount"] as? Int ?? 0
    }

    func firestoreData() -> [String: Any] {
        [
            "uid": uid,
            "username": username,
            "usernameLower": usernameLower,
            "displayName": displayName,
            "emotionSymbol": emotionSymbol as Any,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "isDiscoverable": isDiscoverable,
            "streakCount": streakCount
        ]
    }
}
