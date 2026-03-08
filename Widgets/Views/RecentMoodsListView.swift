//
//  RecentMoodsListView.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//

//
//  RecentMoodsListView.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//

import SwiftUI
import HealthKit

@available(iOS 26.0, *)
struct RecentMoodsListView: View {
    @EnvironmentObject var moodStore: HealthKitMoodStore

    @State private var moods: [HKStateOfMind] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?

    @State private var isSelectionMode = false
    @State private var selectedMoodIDs: Set<UUID> = []
    @State private var isDeletingSelection = false

    var body: some View {
        ZStack {
            LiquidBackdrop()
                .ignoresSafeArea()

            content
        }
        .navigationTitle("Recent Moods")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .safeAreaInset(edge: .bottom) {
            if isSelectionMode && !moods.isEmpty {
                selectionBar
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
            }
        }
        .task {
            await load()
        }
        .refreshable {
            await load()
        }
        .alert("Couldn't load moods", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .alert("Delete selected moods?", isPresented: $isDeletingSelection) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSelected()
            }
        } message: {
            Text("This will permanently delete \(selectedMoodIDs.count) mood\(selectedMoodIDs.count == 1 ? "" : "s").")
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && moods.isEmpty {
            loadingView
        } else if moods.isEmpty {
            emptyView
        } else {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    headerCard

                    LazyVStack(spacing: 14) {
                        ForEach(moods, id: \.uuid) { mood in
                            PremiumMoodRow(
                                mood: mood,
                                isSelectionMode: isSelectionMode,
                                isSelected: selectedMoodIDs.contains(mood.uuid)
                            ) {
                                handleTap(on: mood)
                            } deleteAction: {
                                delete(mood: mood)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, isSelectionMode ? 110 : 24)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text("Loading moods…")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No moods yet",
            systemImage: "face.smiling",
            description: Text("Add a mood and it’ll show up here.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var headerCard: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelectionMode ? "checkmark.circle.badge.questionmark" : "sparkles")
                .font(.title3)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text(isSelectionMode ? "Select moods to delete" : "Your recent check-ins")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(
                    isSelectionMode
                    ? "\(selectedMoodIDs.count) selected"
                    : "\(moods.count) mood\(moods.count == 1 ? "" : "s") logged"
                )
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()
        }
        .padding(16)
        .background(cardBackground)
    }

    private var selectionBar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    exitSelectionMode()
                }
            } label: {
                Text("Cancel")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .foregroundStyle(.white)

            Button {
                isDeletingSelection = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Delete (\(selectedMoodIDs.count))")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selectedMoodIDs.isEmpty ? .white.opacity(0.08) : .red.opacity(0.85))
            )
            .foregroundStyle(.white)
            .disabled(selectedMoodIDs.isEmpty)
            .opacity(selectedMoodIDs.isEmpty ? 0.55 : 1)
        }
        .padding(10)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !moods.isEmpty {
                Button(isSelectionMode ? "Done" : "Select") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        if isSelectionMode {
                            exitSelectionMode()
                        } else {
                            isSelectionMode = true
                        }
                    }
                }
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.white.opacity(0.10))
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
    }

    private func handleTap(on mood: HKStateOfMind) {
        guard isSelectionMode else { return }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            if selectedMoodIDs.contains(mood.uuid) {
                selectedMoodIDs.remove(mood.uuid)
            } else {
                selectedMoodIDs.insert(mood.uuid)
            }
        }
    }

    private func exitSelectionMode() {
        isSelectionMode = false
        selectedMoodIDs.removeAll()
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            moods = try await moodStore.fetchRecentMoods(limit: 50)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func deleteSelected() {
        let idsToDelete = selectedMoodIDs
        let moodsToDelete = moods.filter { idsToDelete.contains($0.uuid) }

        Task {
            do {
                for mood in moodsToDelete {
                    try await moodStore.deleteMood(mood)
                }

                moods.removeAll { idsToDelete.contains($0.uuid) }

                await MainActor.run {
                    exitSelectionMode()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func delete(mood: HKStateOfMind) {
        Task {
            do {
                try await moodStore.deleteMood(mood)
                moods.removeAll { $0.uuid == mood.uuid }
                selectedMoodIDs.remove(mood.uuid)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

@available(iOS 26.0, *)
private struct PremiumMoodRow: View {
    let mood: HKStateOfMind
    let isSelectionMode: Bool
    let isSelected: Bool
    let tapAction: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        Button(action: tapAction) {
            HStack(spacing: 14) {
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                        .frame(width: 26)
                }

                MoodEntryRow(mood: mood)
                    .allowsHitTesting(false)

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(rowBackground)
            .overlay(alignment: .topTrailing) {
                if isSelectionMode && isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.white.opacity(0.18), in: Circle())
                        .padding(10)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .scaleEffect(isSelected ? 0.985 : 1)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: !isSelectionMode) {
            if !isSelectionMode {
                Button(role: .destructive, action: deleteAction) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(isSelected ? .white.opacity(0.16) : .white.opacity(0.09))
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? .white.opacity(0.28) : .white.opacity(0.10), lineWidth: 1)
            )
            .shadow(radius: isSelected ? 10 : 0)
    }
}
