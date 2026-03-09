//
//  MoodTagEngine.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import HealthKit

@available(iOS 26.0, *)
enum MoodTagEngine {
    static let baseTags: [String] = [
        "Sleep", "Work", "Music", "Friends", "Family", "Exercise",
        "Relationship", "Travel", "Weather", "Health", "Food", "School",
        "Finances", "Self-care", "Routine", "Social", "Rest"
    ]

    static func tags(for label: HKStateOfMind.Label?) -> [String] {
        guard let label else { return baseTags }

        switch label {
        case .happy, .content, .calm:
            return [
                "Friends", "Family", "Music", "Exercise", "Travel",
                "Self-care", "Food", "Social", "Routine"
            ]

        case .stressed, .worried, .anxious:
            return [
                "Work", "School", "Sleep", "Health", "Finances",
                "Relationship", "Routine", "Weather"
            ]

        case .sad:
            return [
                "Sleep", "Relationship", "Family", "Health",
                "Weather", "Self-care", "Rest"
            ]

        case .angry, .frustrated:
            return [
                "Work", "Relationship", "Family", "Traffic",
                "Routine", "Health"
            ]

        case .excited:
            return [
                "Travel", "Friends", "Music", "Exercise",
                "Social", "Plans", "Family"
            ]

        default:
            return baseTags
        }
    }
}