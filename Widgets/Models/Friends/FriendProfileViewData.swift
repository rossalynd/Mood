//
//  FriendProfileViewData.swift
//  Widgets
//
//  Created by Rosie on 3/14/26.
//

import SwiftUI
import Foundation

struct FriendProfileViewData {
    let uid: String
    let username: String
    let displayName: String
    let emotionSymbol: String?
    let friendsSince: Date?
    let latestMood: SharedMoodSummary?
    let recentMoods: [SharedMoodSummary]
    let totalSharedCount: Int
    let streakCount: Int
    let topMoodLabel: String?
}
extension FriendProfileViewData {
    var headerMoodColor: Color {
        guard let latestMood else { return .secondary }
        return MoodLevel(rawValue: latestMood.moodValue)?.color ?? .secondary
    }
}
