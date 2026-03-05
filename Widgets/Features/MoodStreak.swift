//
//  MoodStreak.swift
//  Widgets
//
//  Created by Rosie on 3/4/26.
//

import Foundation
import Foundation
import HealthKit

struct MoodStreak {
    let current: Int
    let longest: Int
    let lastCountedDay: Date?   // startOfDay that ended the current streak
}

@available(iOS 26.0, *)
enum StreakCalculator {

    /// Computes current + longest streak from a list of HKStateOfMind samples.
    /// - Parameter anchorDay: Usually "today" (startOfDay). If you want a "grace" behavior, see note below.
    static func compute(from samples: [HKStateOfMind],
                        calendar: Calendar = .current,
                        anchorDay: Date = Date()) -> MoodStreak {

        let dayStarts: [Date] = samples
            .map { calendar.startOfDay(for: $0.startDate) }
        
        let uniqueDays = Set(dayStarts)
        let sortedDaysDesc = uniqueDays.sorted(by: >) // newest first

        guard !sortedDaysDesc.isEmpty else {
            return MoodStreak(current: 0, longest: 0, lastCountedDay: nil)
        }

        let today = calendar.startOfDay(for: anchorDay)

        // Current streak:
        // If user didn't log today, we can start counting from yesterday (common behavior).
        // We'll pick the best starting day = today if present, else yesterday if present, else 0.
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let startDay: Date?
        if uniqueDays.contains(today) {
            startDay = today
        } else if uniqueDays.contains(yesterday) {
            startDay = yesterday
        } else {
            startDay = nil
        }

        let current = startDay.map { countConsecutiveDays(from: $0, days: uniqueDays, calendar: calendar) } ?? 0

        // Longest streak across all logged days:
        let longest = longestRun(in: sortedDaysDesc, calendar: calendar)

        let lastCountedDay = startDay
        return MoodStreak(current: current, longest: longest, lastCountedDay: lastCountedDay)
    }

    private static func countConsecutiveDays(from start: Date,
                                             days: Set<Date>,
                                             calendar: Calendar) -> Int {
        var count = 0
        var cursor = start

        while days.contains(cursor) {
            count += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return count
    }

    private static func longestRun(in sortedDaysDesc: [Date],
                                   calendar: Calendar) -> Int {
        var best = 1
        var current = 1

        for i in 0..<(sortedDaysDesc.count - 1) {
            let d1 = sortedDaysDesc[i]
            let d2 = sortedDaysDesc[i + 1]
            let expectedPrev = calendar.date(byAdding: .day, value: -1, to: d1)!

            if calendar.isDate(d2, inSameDayAs: expectedPrev) {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }
}
