//
//  UnifiedMoodService.swift
//  Widgets
//
//  Created by Rosie on 3/14/26.
//


import Foundation
import HealthKit

@available(iOS 26.0, *)
actor UnifiedMoodService {
    private let firestoreService: MoodFirestoreService
    private let healthKitStore: HealthKitMoodStore

    init(
        healthKitStore: HealthKitMoodStore,
        firestoreService: MoodFirestoreService = MoodFirestoreService()
    ) {
        self.healthKitStore = healthKitStore
        self.firestoreService = firestoreService
    }

    func fetchRecentMoods(limit: Int = 10) async throws -> [UnifiedMoodEntry] {
        async let hkTask = healthKitStore.fetchRecentMoods(limit: limit * 2)
        async let fsTask = firestoreService.fetchRecentMoods(limit: limit * 2)

        let (hkMoods, fsMoods) = try await (hkTask, fsTask)

        var firestoreByID: [String: FirestoreMoodEntry] = [:]
        fsMoods.forEach { firestoreByID[$0.id] = $0 }

        var usedFirestoreIDs = Set<String>()
        var merged: [UnifiedMoodEntry] = []

        for hkMood in hkMoods {
            if let firestoreID = hkMood.firestoreMoodID,
               let firestoreMood = firestoreByID[firestoreID] {
                usedFirestoreIDs.insert(firestoreID)

                merged.append(
                    UnifiedMoodEntry(
                        id: firestoreMood.id,
                        healthKitUUID: hkMood.uuid,
                        hkSample: hkMood,
                        firestore: firestoreMood
                    )
                )
            } else {
                merged.append(
                    UnifiedMoodEntry(
                        id: hkMood.uuid.uuidString,
                        healthKitUUID: hkMood.uuid,
                        hkSample: hkMood,
                        firestore: nil
                    )
                )
            }
        }

        for firestoreMood in fsMoods where !usedFirestoreIDs.contains(firestoreMood.id) {
            merged.append(
                UnifiedMoodEntry(
                    id: firestoreMood.id,
                    healthKitUUID: nil,
                    hkSample: nil,
                    firestore: firestoreMood
                )
            )
        }

        return merged
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }
}

import HealthKit

@available(iOS 26.0, *)
private extension HKStateOfMind {
    var firestoreMoodID: String? {
        metadata?[MoodMetadataKeys.appMoodID] as? String
    }
}
