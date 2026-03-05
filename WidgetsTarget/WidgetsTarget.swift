//
//  WidgetsTarget.swift
//  WidgetsTarget
//
//  Lock Screen widget that shows latest mood emoji
//

import WidgetKit
import SwiftUI

// MARK: - Widget


struct MoodWidget: Widget {
    private let kind = "MoodWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MoodWidgetView(entry: entry)
        }
        .configurationDisplayName("Current Mood")
        .description("Shows your latest logged mood emoji.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Timeline

struct MoodEntry: TimelineEntry {
    let date: Date
    let assetName: String
}


import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MoodEntry {
        MoodEntry(date: .now, assetName: "Happy")
    }

   func getSnapshot(in context: Context, completion: @escaping (MoodEntry) -> Void) {
        completion(MoodEntry(
            date: SharedMoodCache.readDate() ?? .now,
            assetName: SharedMoodCache.readAssetName()
        ))
    }

     func getTimeline(in context: Context, completion: @escaping (Timeline<MoodEntry>) -> Void) {
        let entry = MoodEntry(
            date: SharedMoodCache.readDate() ?? .now,
            assetName: SharedMoodCache.readAssetName()
        )

        // refresh occasionally; app will force refresh on save
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: .now)
            ?? .now.addingTimeInterval(6 * 3600)

        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}


// MARK: - View (Lock Screen families)

struct MoodWidgetView: View {
    let entry: MoodEntry
    @Environment(\.widgetFamily) private var family

    private let deepLink = URL(string: "moodwidget://addMood")!

    var body: some View {
        content
            // ✅ Apply to the *root* of the widget view
            .widgetURL(deepLink)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            Image("\(entry.assetName)")

        case .accessoryCircular:
            ZStack() {
                Circle()
                    .fill( .black)
                    .opacity(0.7)
                    .frame(width: 65, height: 65)
                
                Image(entry.assetName)
                    .resizable()
                    .frame(width: 65, height: 65)
                    .foregroundStyle(.white)
                    
                 
                
                
                
            }
            
            
                .containerBackground(.clear, for: .widget)

        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image("\(entry.assetName)")

                   
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Mood")
                        .font(.caption.weight(.semibold))
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(.clear, for: .widget)

        default:
            Image("\(entry.assetName)")
        }
    }
}


// MARK: - Preview

#Preview(as: .accessoryCircular) {
    MoodWidget()
} timeline: {
    MoodEntry(date: .now, assetName: "Happy")
}

#Preview(as: .accessoryRectangular) {
    MoodWidget()
} timeline: {
    MoodEntry(date: .now, assetName: "Happy")
}

#Preview(as: .accessoryInline) {
    MoodWidget()
} timeline: {
    MoodEntry(date: .now, assetName: "Happy")
}
