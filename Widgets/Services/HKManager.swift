//
//  HKManager.swift
//  Widgets
//
//  Created by Rosie on 2/14/26.
//

import HealthKit
import WidgetKit

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

                let computed = StreakCalculator.compute(from: samples)
                self.moods = samples
                self.streak = computed

                // ✅ Update shared cache for widget
                if let latest = samples.first { // your query sorts descending, so first is newest
                    let assetName = latest.labels.first?.displayName ?? "Happy"
                    SharedMoodCache.writeLatest(assetName: assetName, date: latest.startDate, color: latest.labels.first?.level.color ?? .green)
                }

                SharedMoodCache.writeStreak(current: computed.current)

                // ✅ Force widget refresh
                WidgetCenter.shared.reloadAllTimelines()

            } catch {
                // handle error if you want
            }
        }
    
    func saveMood(valence: Double,
                  kind: HKStateOfMind.Kind,
                  labels: [HKStateOfMind.Label],
                metadata: [String: Any]
    
    ) async throws {
        

        let sample = HKStateOfMind(
            date: Date(),
            kind: kind,
            valence: valence,          // -1.0 ... 1.0
            labels: labels,
            associations: [],
            metadata: nil
        )
        try await store.save(sample)
        await refresh()
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
        await refresh()
    }
    func moods(forSameDayAs date: Date) -> [HKStateOfMind] {
            let calendar = Calendar.current
            return moods.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
        }

        func snapshot(for date: Date) -> MoodDaySnapshot {
            MoodDaySnapshot(
                date: date,
                moods: moods(forSameDayAs: date)
            )
        }

        var todaySnapshot: MoodDaySnapshot {
            snapshot(for: Date())
        }

   }

import HealthKit
import WidgetKit

@available(iOS 26.0, *)
struct MoodDaySnapshot {
    let date: Date
    let moods: [HKStateOfMind]

    var checkInCount: Int {
        moods.count
    }

    var averageValence: Double? {
        guard !moods.isEmpty else { return nil }
        let total = moods.reduce(0.0) { $0 + $1.valence }
        return total / Double(moods.count)
    }

    var latestMood: HKStateOfMind? {
        moods.max(by: { $0.startDate < $1.startDate })
    }

    var lastLogDate: Date? {
        latestMood?.startDate
    }

    var topLabelName: String? {
        let names = moods
            .flatMap { $0.labels.map(\.displayName) }

        guard !names.isEmpty else { return nil }

        let counts = Dictionary(grouping: names, by: { $0 })
            .mapValues(\.count)

        return counts.max(by: { $0.value < $1.value })?.key
    }

    var averageLabelText: String {
        guard let averageValence else { return "No data" }

        switch averageValence {
        case ..<(-0.6): return "Very Low 😞"
        case -0.6..<(-0.2): return "Low 🙁"
        case -0.2..<0.2: return "Calm 🙂"
        case 0.2..<0.6: return "Good 😊"
        default: return "Great 😄"
        }
    }
}
