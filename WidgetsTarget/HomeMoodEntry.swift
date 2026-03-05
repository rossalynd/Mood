import WidgetKit
import SwiftUI

// MARK: - Entry

struct HomeMoodEntry: TimelineEntry {
    let date: Date
    let assetName: String
    let hasToday: Bool
    let streak: Int
    let color: Color
}

// MARK: - Provider

struct HomeMoodProvider: TimelineProvider {
    func placeholder(in context: Context) -> HomeMoodEntry {
        HomeMoodEntry(date: .now, assetName: "Happy", hasToday: true, streak: 3, color: .green)
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeMoodEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeMoodEntry>) -> Void) {
        let entry = readEntry()

        // fallback refresh; your app will also call reloadAllTimelines() on changes
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)
        ?? .now.addingTimeInterval(30 * 60)

        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readEntry() -> HomeMoodEntry {
        HomeMoodEntry(
            date: .now,
            assetName: SharedMoodCache.readAssetName(),
            hasToday: SharedMoodCache.hasMoodLoggedToday(),
            streak: SharedMoodCache.readStreakCurrent(),
            color: SharedMoodCache.readColor()
        
        )
    }
}

// MARK: - Widget

struct HomeMoodWidget: Widget {
    private let kind = "HomeMoodWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeMoodProvider()) { entry in
            HomeMoodWidgetView(entry: entry)
        }
        .configurationDisplayName("InstaMood")
        .description("Your current mood + streak.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - View

struct HomeMoodWidgetView: View {
    let entry: HomeMoodEntry

    private let deepLink = URL(string: "moodwidget://addMood")!

    var body: some View {
        ZStack() {
            LiquidBackdrop()
                .padding(-20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                
            
       
                // Background
                
                
                
                // Main content
                ZStack() {
                    
                    
                    
                    
                    if entry.hasToday {
                        
                        Circle()
                            .fill(entry.color)
                            .frame(width: 120, height: 120)
                        Image(entry.assetName)
                            .resizable()
                            .frame(width: 180, height: 180)
                        
                    } else {
                        
                        VStack(spacing: 8) {
                            Text("Log mood")
                                .font(.headline)
                            Text("Tap to check in")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .multilineTextAlignment(.center)
                        
                        
                        
                    }
                    
                    VStack {
                        HStack {
                            Spacer()
                            streakBadge(entry.streak)
                               
                        }
                        Spacer()
                    }
                    
                    .frame(width: 150, height: 150)
                   
                }
            
                // Streak badge
                
            
            
        }
        .widgetURL(deepLink)
        .containerBackground(.clear, for: .widget)
        .ignoresSafeArea()
        
    }

    private func streakBadge(_ streak: Int) -> some View {
        HStack(spacing: 3) {
            
            Image(systemName: "flame.fill")
                .font(.caption)
            Text("\(streak)")
                .font(.subheadline.weight(.semibold))
        }
        .padding(10)
        .background(.ultraThinMaterial, in: Capsule())
        
        
        .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))
        .accessibilityLabel("Streak \(streak) days")
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    HomeMoodWidget()
} timeline: {
    HomeMoodEntry(date: .now, assetName: "Happy", hasToday: true, streak: 5, color: .green)
    HomeMoodEntry(date: .now, assetName: "Happy", hasToday: false, streak: 0, color: .green)
}
