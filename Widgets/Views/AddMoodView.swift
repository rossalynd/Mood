import SwiftUI
import HealthKit
import WidgetKit



@available(iOS 26.0, *)
struct AddMoodView: View {
    @EnvironmentObject var moodStore: HealthKitMoodStore
    @EnvironmentObject var router: DeepLinkRouter
    @Environment(\.dismiss) private var dismiss
    



    

    // Selection
    @State private var selectedLabel: HKStateOfMind.Label? = nil
    @State private var kind: HKStateOfMind.Kind = .momentaryEmotion

    // UI state
    @State private var query: String = ""
    @State private var sort: MoodSort = .byLevel
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isSaving = false

    private let cellHeight: CGFloat = 70
    private let gridSpacing: CGFloat = 18
    private let cardRadius: CGFloat = 22

    private var fourRowHeight: CGFloat {
        (cellHeight * 4) + (gridSpacing * 3)
    }

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        ZStack(alignment: .bottom) {
            LiquidBackdrop()
                .ignoresSafeArea()
            

            ScrollView {
                headerBar
                VStack(spacing: 14) {
                    Color.clear.frame(height: 8)
                    
                    ScrollView {
                        controlsCard.padding(.bottom, 5)
                        
                        
                        if sort == .byLevel {
                            byLevelSections
                        } else {
                            alphabeticalGridCard
                        }
                        
                        Color.clear.frame(height: 110) // room for save bar
                    }
                    
                }
                .padding(.horizontal)
            }.padding(.top)
            saveBar
        }
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .alert("Couldn't save mood", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        
    }
    

    // MARK: - Header (glass)

    private var headerBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Add Mood")
                    .font(.title2.weight(.semibold))

            }

            Spacer()


        }
        .padding(.horizontal)
        
        
    }

    // MARK: - Controls Card (glass)

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)

            VStack(spacing: 10) {
                Picker("Type", selection: $kind) {
                    Text("Momentary").tag(HKStateOfMind.Kind.momentaryEmotion)
                    Text("Daily").tag(HKStateOfMind.Kind.dailyMood)
                }
                .pickerStyle(.segmented)

                Picker("Sort", selection: $sort) {
                    Text("Level").tag(MoodSort.byLevel)
                    Text("A–Z").tag(MoodSort.alphabetical)
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
        .liquidGlassCard(cornerRadius: cardRadius, material: .regularMaterial)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")

            TextField("Search moods", text: $query)
        }
        .padding(10)
        
    }

    // MARK: - By Level

    private var byLevelSections: some View {
        VStack(spacing: 14) {
            ForEach(MoodLevel.sortedDescending, id: \.self) { level in
                let sectionMoods = moodsForLevel(level)

                if !sectionMoods.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(level.sectionTitle)
                                .font(.headline)

                            Spacer()

                            Text("\(sectionMoods.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(sectionMoods) { mood in
                                    MoodCell(mood: mood, isSelected: mood.label == selectedLabel)
                                        .frame(width: 74)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedLabel = mood.label }
                                        .accessibilityLabel(mood.displayName)
                                        .accessibilityHint("Select mood")
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding()
                    .liquidGlassCard(cornerRadius: cardRadius, material: .ultraThinMaterial)
                }
            }
        }
    }

    // MARK: - Alphabetical Grid

    private var alphabeticalGridCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("All moods")
                    .font(.headline)
                Spacer()
                Text("\(filteredAlphabeticalMoods.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: gridSpacing) {
                    ForEach(filteredAlphabeticalMoods) { mood in
                        MoodCell(mood: mood, isSelected: mood.label == selectedLabel)
                            .frame(height: cellHeight)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedLabel = mood.label }
                            .accessibilityLabel(mood.displayName)
                            .accessibilityHint("Select mood")
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(height: fourRowHeight)
            .scrollIndicators(.hidden)
        }
        .padding()
        .liquidGlassCard(cornerRadius: cardRadius, material: .ultraThinMaterial)
    }

    // MARK: - Save Bar (glass)

    private var saveBar: some View {
        VStack(spacing: 10) {
            searchBar.padding(.horizontal)
            
                Button {
                    Task { await save() }
                } label: {
                    ZStack {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(selectedLabel == nil ? "Select a mood" : "Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || selectedLabel == nil)
                .padding(.horizontal)
                .padding(.bottom, 14)
            
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Data

    private var allMoodItems: [MoodItem] {
        AppleMoodLabels.all.map { MoodItem(label: $0) }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredMoodItems: [MoodItem] {
        guard !trimmedQuery.isEmpty else { return allMoodItems }
        let q = trimmedQuery.lowercased()
        return allMoodItems.filter { $0.displayName.lowercased().contains(q) }
    }

    private func moodsForLevel(_ level: MoodLevel) -> [MoodItem] {
        filteredMoodItems
            .filter { $0.level == level }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private var filteredAlphabeticalMoods: [MoodItem] {
        filteredMoodItems.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    // MARK: - Save

    private func save() async {
        guard let label = selectedLabel else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            try await moodStore.requestAuth()
            try await moodStore.saveMood(
                valence: label.defaultValence,
                kind: kind,
                labels: [label]
            )

            SharedMoodCache.writeLatest(assetName: label.displayName, date: Date(), color: label.level.color)
            WidgetCenter.shared.reloadTimelines(ofKind: "MoodWidget")
            dismiss()
            
            

            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("Save failed:", error)
        }
    }
}



// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    RootShellView()
        .environmentObject(HealthKitMoodStore())
        .environmentObject(DeepLinkRouter())
}
