import SwiftUI
import HealthKit

struct WatchHomeView: View {

    @EnvironmentObject var moodStore: HealthKitMoodStore

    @State private var moods: [HKStateOfMind] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showPicker = false

    private var latestMood: HKStateOfMind? { moods.first }

    private var latestMoodLabel: HKStateOfMind.Label? {
        latestMood?.labels.first
    }

    var body: some View {
        ZStack {
        LiquidBackdrop()
                .ignoresSafeArea()
            
            VStack(spacing: 10) {
                
                if let label = latestMoodLabel {
                    VStack(spacing: 8) {
                        
                        // Circle behind the provided asset image
                        ZStack {
                            Circle()
                                .fill(label.level.color)
                                .opacity(0.3)
                            label.emoji
                                .resizable()
                                .scaledToFit()
                                .padding(10)
                        }
                        .frame(width: 60, height: 60)
                        
                        Text(label.displayName)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text("Logged today")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("Update") { showPicker = true }
                        .buttonStyle(.bordered)
                    
                } else {
                    VStack(spacing: 6) {
                        Text("No mood logged")
                            .font(.headline)
                        
                        Text("Tap to log")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("Log Mood") { showPicker = true }
                        .buttonStyle(.bordered)
                }
                
               
            }
            .padding()
            .sheet(isPresented: $showPicker) {
                WatchMoodPicker(onSaved: {
                    Task { await loadMoods() }
                })
            }
            .task { await loadMoods() }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    // MARK: - Same logic as your iPhone loadMoods(), but local to watch

    @MainActor
    private func loadMoods() async {
        isLoading = true
        defer { isLoading = false }

        do {
            moods = try await moodStore.fetchRecentMoods(limit: 50)

            if let latest = latestMood {
                let assetName = latest.labels.first?.displayName ?? "Happy"
                SharedMoodCache.writeLatest(assetName: assetName, date: latest.startDate)
            }

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    WatchHomeView()
        .environmentObject(HealthKitMoodStore())
}
