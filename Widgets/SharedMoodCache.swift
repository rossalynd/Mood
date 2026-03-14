//
//  SharedMoodCache.swift
//  Widgets
//
//  Created by Rosie on 2/15/26.
//

import Foundation
import SwiftUI

enum SharedMoodCache {
    static let suiteName = "group.com.Widgets.mood"

    // ✅ Swift 6 friendly: no stored static UserDefaults
    private static func suite() -> UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Write (your original API, unchanged)

    static func writeLatest(assetName: String, date: Date, color: Color) {
        let s = suite()

        s?.set(assetName, forKey: "latestMoodAsset")
        s?.set(date, forKey: "latestMoodDate")

        let validColors: [Color: String] = [
            .indigo: "indigo",
            .orange: "orange",
            .yellow: "yellow",
            .pink: "pink",
            .purple: "purple",
            .mint: "mint",
            .blue: "blue",
            .red: "red",
            .green: "green"
            
        ]

        if let colorName = validColors[color] {
            s?.set(colorName, forKey: "latestMoodColor")
        } else {
            // fallback if somehow an unexpected color appears
            s?.set("yellow", forKey: "latestMoodColor")
            print()
            print("⚠️ Invalid mood color, defaulting to yellow")
        }
    }

    // MARK: - Read (your original API, unchanged)

    static func readAssetName() -> String {
        suite()?.string(forKey: "latestMoodAsset") ?? "Happy"
    }

    static func readDate() -> Date? {
        suite()?.object(forKey: "latestMoodDate") as? Date
    }
    
    static func readColor() -> Color {
        let name = suite()?.string(forKey: "latestMoodColor") ?? "yellow"
        switch name {
        case "indigo": return .indigo
        case "orange": return .orange
        case "yellow": return .yellow
        case "pink":   return .pink
        case "purple": return .purple
        case "mint": return .mint
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        default:       return .yellow
        }
    }

    // MARK: - Optional additions (won’t break anything else)

    static func writeStreak(current: Int) {
        suite()?.set(current, forKey: "streakCurrent")
    }

    static func readStreakCurrent() -> Int {
        suite()?.integer(forKey: "streakCurrent") ?? 0
    }

    static func hasMoodLoggedToday(now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let d = readDate() else { return false }
        return calendar.isDate(d, inSameDayAs: now)
    }
}
