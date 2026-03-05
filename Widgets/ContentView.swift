//
//  ContentView.swift
//  Widgets
//
//  Created by Rosie on 2/14/26.
//

import SwiftUI
import HealthKit
import WidgetKit

@available(iOS 26.0, *)
struct ContentView: View {
   
    @EnvironmentObject var moodStore: HealthKitMoodStore
    @EnvironmentObject var router: DeepLinkRouter

    @State private var errorMessage: String?
    @State private var showError = false

    @State private var moods: [HKStateOfMind] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if moods.isEmpty && !isLoading {
                    ContentUnavailableView(
                        "No moods yet",
                        systemImage: "face.smiling",
                        description: Text("Tap Add Mood to log your first one.")
                    )
                } else {
                    let recents = Array(moods.dropFirst())

                    List {
                        if let latest = moods.first {
                            LatestMoodCard(mood: latest)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 6)
                                .onTapGesture { router.openAddMood = true }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task { await delete(latest) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }

                        Section {
                            ForEach(recents, id: \.uuid) { mood in
                                MoodRow(mood: mood)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            Task { await delete(mood) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            .onDelete { indexSet in
                                for i in indexSet {
                                    let mood = recents[i]
                                    Task { await delete(mood) }
                                }
                            }
                        } header: {
                            Text("Recent")
                                .font(.headline)
                                .padding(.horizontal)
                                .textCase(nil)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle("Mood")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.openAddMood = true
                    } label: {
                        Label("Add Mood", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationDestination(isPresented: $router.openAddMood) {
                if #available(iOS 26.0, *) {
                    AddMoodView()
                        .environmentObject(moodStore)
                } else {
                    VStack(spacing: 12) {
                        Text("State of Mind requires iOS 18+.")
                        Text("Update iOS to use mood logging.")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
            .overlay {
                if isLoading && moods.isEmpty {
                    ProgressView()
                }
            }
            .task {
                do {
                    try await moodStore.requestAuth()
                    await loadMoods()
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }

                // ✅ If the deep link flag was already true before the view appeared,
                // this ensures the navigation still happens.
                if router.openAddMood {
                    // no-op; binding will present automatically once view is ready
                }
            }
            .alert("Health Access", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .onChange(of: router.openAddMood) { _, isPresented in
                if !isPresented {
                    Task { await loadMoods() }
                }
            }
        }
    }

   

    @MainActor
    private func loadMoods() async {
        isLoading = true
        defer { isLoading = false }

        do {
            
                moods = try await moodStore.fetchRecentMoods(limit: 50)

                if let latest = moods.first {
                    let assetName = latest.labels.first?.displayName ?? "Happy"
                    SharedMoodCache.writeLatest(assetName: assetName, date: latest.startDate)
                    WidgetCenter.shared.reloadAllTimelines()
                    
                }
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    
    @MainActor
    private func delete(_ mood: HKStateOfMind) async {
        do {
            try await moodStore.deleteMood(mood)
            await loadMoods() // refresh list
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

}

// MARK: - Big latest card

@available(iOS 26.0, *)
private struct LatestMoodCard: View {
    let mood: HKStateOfMind

    private var primaryLabel: HKStateOfMind.Label? { mood.labels.first }

    var body: some View {
        VStack() {
            VStack(alignment: .center, spacing: 12) {
                Text("Current Mood")
                    .font(.title3.weight(.semibold))
                ZStack {
                    Rectangle()
                        .frame(width: .infinity)
                        .opacity(0)
                    Circle()
                        .fill((primaryLabel?.level.color ?? .gray))
                        .frame(width: 150, height: 150)

                    Image(primaryLabel?.displayName ?? "Happy")
                        .resizable()
                        .frame(width: 100, height: 100)
                        
                }

                VStack(alignment: .center, spacing: 4) {
                    Text(primaryLabel?.displayName ?? "Mood")
                        .font(.title2.weight(.semibold))

                    Text(mood.kind == .dailyMood ? "Daily Mood" : "Momentary Emotion")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(mood.startDate, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

           
        }
        .padding(16)
        
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
        
    }
}

// MARK: - Smaller row

@available(iOS 26.0, *)
private struct MoodRow: View {
    let mood: HKStateOfMind

    private var primaryLabel: HKStateOfMind.Label? { mood.labels.first }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((primaryLabel?.level.color ?? .gray))
                    .frame(width: 44, height: 44)

                Text(primaryLabel?.emoji ?? Image("Happy"))
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(primaryLabel?.displayName ?? "Mood")
                    .font(.headline)

                Text(mood.startDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        
    }
}

