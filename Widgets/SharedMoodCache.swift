//
//  SharedMoodCache.swift
//  Widgets
//
//  Created by Rosie on 2/15/26.
//

import Foundation
import WidgetKit

enum SharedMoodCache {
    static let suiteName = "group.com.Widgets.mood"
    static let suite = UserDefaults(suiteName: suiteName)

    // MARK: - Write

    static func writeLatest(assetName: String, date: Date) {
        suite?.set(assetName, forKey: "latestMoodAsset")
        suite?.set(date, forKey: "latestMoodDate")

        
    }

    // MARK: - Read
    

    static func readAssetName() -> String {
        suite?.string(forKey: "latestMoodAsset") ?? "Happy"
    }

    static func readDate() -> Date? {
        suite?.object(forKey: "latestMoodDate") as? Date
    }
}
