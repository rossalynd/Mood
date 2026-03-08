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
                ForEach(moods.prefix(5), id: \.uuid) { mood in
                    MoodEntryRow(mood: mood)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(mood: mood)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onDelete(perform: delete)
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
    
    private func delete(at offsets: IndexSet) {
        // Determine the displayed subset and map offsets safely into concrete items
        let displayed: [HKStateOfMind] = Array(moods.prefix(5))

        let itemsToDelete: [HKStateOfMind] = offsets.compactMap { index -> HKStateOfMind? in
            guard index >= 0 && index < displayed.count else { return nil }
            return displayed[index]
        }

        // Perform deletions in the store
        for mood in itemsToDelete {
            delete(mood: mood)
        }

        // Update local state immediately to reflect deletions
        moods.removeAll { m in itemsToDelete.contains(where: { $0.uuid == m.uuid }) }
    }

    private func delete(mood: HKStateOfMind) {
        // Fire-and-forget delete; if your store is async, you could adapt this to await and handle errors
        Task {
            do {
                try await moodStore.deleteMood(mood)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

@available(iOS 26.0, *)private struct MoodEntryRow: View {
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

#Preview {
    RecentMoodsView()
        .environmentObject(HealthKitMoodStore())
}
