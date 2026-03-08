//
//  RecentMoodsView.swift
//  Widgets
//
//  Created by Rosie on 2/15/26.
//

import Foundation
import SwiftUI
import HealthKit

import SwiftUI
import HealthKit

@available(iOS 26.0, *)
struct RecentMoodsPreviewCard: View {
    @EnvironmentObject var moodStore: HealthKitMoodStore
    let onSeeAll: () -> Void

    @State private var moods: [HKStateOfMind] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?

    private var displayedMoods: [HKStateOfMind] {
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
                    ForEach(displayedMoods, id: \.uuid) { mood in
                        MoodEntryRow(mood: mood)

                        if mood.uuid != displayedMoods.last?.uuid {
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
            moods = try await moodStore.fetchRecentMoods(limit: 10)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

@available(iOS 26.0, *)
    struct MoodEntryRow: View {
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
                    .resizable()
                    .frame(maxWidth: 30, maxHeight: 30)
                    .foregroundStyle(primaryLabel?.level.color ?? .gray)
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
                    

                    Text(mood.startDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            
        }
        .padding(.vertical, 4)
    }
}

