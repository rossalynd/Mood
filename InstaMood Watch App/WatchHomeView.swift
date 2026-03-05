import SwiftUI
import HealthKit

struct WatchHomeView: View {

    @EnvironmentObject var moodStore: HealthKitMoodStore

    @State private var moods: [HKStateOfMind] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showPicker = false

    private var latestMood: HKStateOfMind? {
        moods.first
    }

    var body: some View {

        VStack(spacing: 12) {

            if let latest = latestMood {

                VStack(spacing: 6) {

                    Image(latest.labels.first?.displayName ?? "happy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)

                    Text(latest.labels.first?.displayName ?? "Mood")
                        .font(.headline)

                    Text("Logged today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button("Update") {
                    showPicker = true
                }
                .buttonStyle(.borderedProminent)

            } else {

                VStack(spacing: 6) {

                    Text("No mood logged")
                        .font(.headline)

                    Text("Tap to log")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("Log Mood") {
                    showPicker = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .sheet(isPresented: $showPicker) {
            WatchMoodPicker(onSaved: {
                Task { await loadMoods() }
            })
        }
        .task {
            await loadMoods()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    // MARK: - Load moods (same logic as iPhone)

    @MainActor
    private func loadMoods() async {

        isLoading = true
        defer { isLoading = false }

        do {

            moods = try await moodStore.fetchRecentMoods(limit: 50)

            if let latest = latestMood {

                let assetName = latest.labels.first?.displayName ?? "Happy"

                SharedMoodCache.writeLatest(
                    assetName: assetName,
                    date: latest.startDate
                )
            }

        } catch {

            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
