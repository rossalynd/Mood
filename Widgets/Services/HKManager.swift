//
//  HKManager.swift
//  Widgets
//
//  Created by Rosie on 2/14/26.
//

import HealthKit
@available(iOS 26.0, *)
@MainActor
final class HealthKitMoodStore: ObservableObject {
    private let store = HKHealthStore()
    @Published private(set) var moods: [HKStateOfMind] = []
    @Published private(set) var streak: MoodStreak = .init(current: 0, longest: 0, lastCountedDay: nil)

    func requestAuth() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        

        let stateOfMindType = HKObjectType.stateOfMindType() // iOS 18+
        try await store.requestAuthorization(toShare: [stateOfMindType], read: [stateOfMindType])
    }

    func refresh() async {
            do {
                let samples = try await fetchRecentMoods()
                await MainActor.run {
                    self.moods = samples
                    self.streak = StreakCalculator.compute(from: samples)
                }
            } catch {
                // handle error
            }
        }
    
    func saveMood(valence: Double,
                  kind: HKStateOfMind.Kind,
                  labels: [HKStateOfMind.Label] = []) async throws {
        

        let sample = HKStateOfMind(
            date: Date(),
            kind: kind,
            valence: valence,          // -1.0 ... 1.0
            labels: labels,
            associations: [],
            metadata: nil
        )
        try await store.save(sample)
    }
    
    func fetchRecentMoods(limit: Int = 365) async throws -> [HKStateOfMind] {
           

           try await requestAuth()

           let type = HKObjectType.stateOfMindType()
           let predicate = HKQuery.predicateForSamples(
               withStart: .distantPast,
               end: Date(),
               options: []
           )
           let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

           return try await withCheckedThrowingContinuation { cont in
               let query = HKSampleQuery(
                   sampleType: type,
                   predicate: predicate,
                   limit: limit,
                   sortDescriptors: [sort]
               ) { _, samples, error in
                   if let error { cont.resume(throwing: error); return }
                   let moods = (samples as? [HKStateOfMind]) ?? []
                   cont.resume(returning: moods)
               }

               self.store.execute(query)
           }
       }
    func deleteMood(_ mood: HKStateOfMind) async throws {
        
        try await requestAuth()

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            store.delete(mood) { success, error in
                if let error {
                    cont.resume(throwing: error)
                } else if success {
                    cont.resume(returning: ())
                } else {
                    cont.resume(throwing: NSError(
                        domain: "HealthKit",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Delete failed"]
                    ))
                }
            }
        }
    }


   }

