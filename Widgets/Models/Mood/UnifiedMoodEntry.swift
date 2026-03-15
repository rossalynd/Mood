//
//  UnifiedMoodEntry.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//


import Foundation
import HealthKit

@available(iOS 26.0, *)
struct UnifiedMoodEntry: Identifiable, Hashable {
    let id: String
    let healthKitUUID: UUID?
    let hkSample: HKStateOfMind?
    let firestore: FirestoreMoodEntry?

    var createdAt: Date {
        firestore?.createdAt ?? hkSample?.startDate ?? Date()
    }

    var updatedAt: Date {
        firestore?.updatedAt ?? createdAt
    }

    static func == (lhs: UnifiedMoodEntry, rhs: UnifiedMoodEntry) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

