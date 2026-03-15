//
//  RecentMoodsView.swift
//  Widgets
//
//  Created by Rosie on 2/15/26.
//

import Foundation
import SwiftUI
import HealthKit

@available(iOS 26.0, *)
struct RecentMoodsPreviewCard: View {
    @EnvironmentObject var moodStore: HealthKitMoodStore
    let onSeeAll: () -> Void

    @State private var moods: [UnifiedMoodEntry] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?

    private var displayedMoods: [UnifiedMoodEntry] {
        Array(moods.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.headline)

                Spacer()

                Button("See All") {
                    onSeeAll()
                }
                .font(.subheadline.weight(.semibold))
            }

            if isLoading && moods.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 24)
            } else if displayedMoods.isEmpty {
                ContentUnavailableView(
                    "No moods yet",
                    systemImage: "face.smiling",
                    description: Text("Add a mood and it’ll show up here.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(displayedMoods) { mood in
                        MoodEntryRow(mood: mood)

                        if mood.id != displayedMoods.last?.id {
                            Divider()
                                .padding(.leading, 56)
                                .opacity(0.2)
                        }
                    }
                }
            }
        }
        .padding()
        .liquidGlassCard(cornerRadius: 22, material: .thinMaterial)
        .task {
            await load()
        }
        .onAppear {
            Task { await load() }
        }
        .alert("Couldn't load moods", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let unifiedService = UnifiedMoodService(healthKitStore: moodStore)
            moods = try await unifiedService.fetchRecentMoods(limit: 10)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

import SwiftUI
import HealthKit

@available(iOS 26.0, *)
struct MoodEntryRow: View {
    let mood: UnifiedMoodEntry

    private var primaryLabelName: String {
        if let first = mood.firestore?.labels.first, !first.isEmpty {
            return first
        }
        if let first = mood.hkSample?.labels.first?.displayName {
            return first
        }
        return "Mood"
    }

    private var imageName: String {
        if let emoji = mood.firestore?.emoji, !emoji.isEmpty {
            return emoji
        }
        if let name = mood.hkSample?.labels.first?.displayName {
            return name
        }
        return "Happy"
    }

    private var level: MoodLevel {
        if let value = mood.firestore?.moodValue {
            return MoodLevel(rawValue: value) ?? .neutral
        }
        if let hkLevel = mood.hkSample?.labels.first?.level {
            return hkLevel
        }
        return .neutral
    }

    private var extraCount: Int {
        if let count = mood.firestore?.labels.count {
            return max(0, count - 1)
        }
        if let count = mood.hkSample?.labels.count {
            return max(0, count - 1)
        }
        return 0
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(level.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(imageName)
                    .resizable()
                    .frame(maxWidth: 30, maxHeight: 30)
                    .foregroundStyle(level.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(primaryLabelName)
                        .font(.headline)

                    if extraCount > 0 {
                        Text("+\(extraCount)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.thinMaterial, in: Capsule())
                    }
                }

                Text(mood.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
