//
//  RecentMoodsView.swift
//  Widgets
//
//  Created by Rosie on 2/15/26.
//

import Foundation
import SwiftUI
import HealthKit

@available(iOS 18.0, *)
struct RecentMoodsView: View {
    @EnvironmentObject var moodStore: HealthKitMoodStore

    @State private var moods: [HKStateOfMind] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if moods.isEmpty && !isLoading {
                ContentUnavailableView(
                    "No moods yet",
                    systemImage: "face.smiling",
                    description: Text("Add a mood and it’ll show up here.")
                )
            } else {
                ForEach(moods, id: \.uuid) { mood in
                    MoodEntryRow(mood: mood)
                }
            }
        }
        .navigationTitle("Recent Moods")
        .overlay {
            if isLoading && moods.isEmpty { ProgressView() }
        }
        .task { await load() }
        .refreshable { await load() }
        .alert("Couldn't load moods", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            moods = try await moodStore.fetchRecentMoods(limit: 50)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

@available(iOS 18.0, *)
private struct MoodEntryRow: View {
    let mood: HKStateOfMind

    private var primaryLabel: HKStateOfMind.Label? { mood.labels.first }
    private var extraCount: Int { max(0, mood.labels.count - 1) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((primaryLabel?.level.color ?? .gray).opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(primaryLabel?.displayName ?? "Happy")
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(primaryLabel?.displayName ?? "Mood")
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

                HStack(spacing: 8) {
                    Text(mood.kind == .dailyMood ? "Daily Mood" : "Momentary Emotion")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(mood.startDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(mood.valence, format: .number.precision(.fractionLength(1)))
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
        }
        .padding(.vertical, 4)
    }
}
