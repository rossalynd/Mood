//
//  WeekdayMoodAverage.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//

import SwiftUI
import Charts
import HealthKit


@available(iOS 26.0, *)
struct WeekdayMoodAverage: Identifiable, Hashable {
    let dayStart: Date            // stable identity for the bar
    let label: String             // "Mon", "Tue", ...
    let average: Double?          // nil = no data or future day
    let isFuture: Bool

    var id: Date { dayStart }
}

@available(iOS 26.0, *)
extension MoodLevel {
    static func fromAverageValence(_ v: Double) -> MoodLevel {
        switch v {
        case ..<(-0.6): return .veryNegative
        case ..<(-0.2): return .negative
        case ..<(0.2):  return .neutral
        case ..<(0.6):  return .positive
        default:        return .veryPositive
        }
    }
}

@available(iOS 26.0, *)
struct CurrentWeekMoodBarGraph: View {
    @EnvironmentObject var moodStore: HealthKitMoodStore

    var chartHeight: CGFloat = 100

    private var weekData: [WeekdayMoodAverage] {
        let cal = Calendar.current
        let now = Date()

        let week = cal.dateInterval(of: .weekOfYear, for: now)!
        let startOfWeek = week.start
        let startOfToday = cal.startOfDay(for: now)

        // Only moods in the current week
        let weekMoods = moodStore.moods.filter {
            $0.startDate >= startOfWeek && $0.startDate < week.end
        }

        // Bucket by dayStart (not weekday) so we’re guaranteed 7 distinct days
        var buckets: [Date: [Double]] = [:]
        for mood in weekMoods {
            let d = cal.startOfDay(for: mood.startDate)
            buckets[d, default: []].append(mood.valence)
        }

        return (0..<7).map { offset in
            let dayDate = cal.date(byAdding: .day, value: offset, to: startOfWeek)!
            let dayStart = cal.startOfDay(for: dayDate)
            let isFuture = dayStart > startOfToday

            let vals = buckets[dayStart] ?? []
            let avg = vals.isEmpty ? nil : vals.reduce(0, +) / Double(vals.count)

            // Leave future days blank
            let finalAvg: Double? = isFuture ? nil : avg

            // Label for that exact date (so it matches the week start correctly)
            let label = cal.shortWeekdaySymbols[cal.component(.weekday, from: dayStart) - 1]

            return WeekdayMoodAverage(
                dayStart: dayStart,
                label: label,
                average: finalAvg,
                isFuture: isFuture
            )
        }
    }

    var body: some View {
        Chart(weekData) { day in
            if let avg = day.average {
                PointMark(
                    x: .value("Day", day.label),
                    y: .value("Avg Valence", avg)
                )
                .symbolSize(200)
                .foregroundStyle(MoodLevel.fromAverageValence(avg).color)
                .opacity(0.9)
            } else {
                // Invisible point to keep the category visible on the x-axis
                PointMark(
                    x: .value("Day", day.label),
                    y: .value("Avg Valence", 0)
                )
                .opacity(0.001)
            }

            RuleMark(y: .value("Neutral", 0))
                .foregroundStyle(.white.opacity(0.06))
        }
        .chartYScale(domain: -1.0...1.0)
        .chartYAxis(.hidden)
        .frame(height: chartHeight)
        .padding(.vertical, 5)
        .chartXAxis {
            AxisMarks(values: weekData.map { $0.label }) { value in
                            
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            
            }
        }
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 26.0, *)
#Preview {
    
    RootShellView()
        .environmentObject(HealthKitMoodStore())
        .environmentObject(DeepLinkRouter())
        .environmentObject(AuthService())
      
}
