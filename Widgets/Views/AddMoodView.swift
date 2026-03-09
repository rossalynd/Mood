import SwiftUI
import HealthKit
import WidgetKit

@available(iOS 26.0, *)
struct AddMoodView: View {
    @EnvironmentObject private var moodStore: HealthKitMoodStore
    @Environment(\.dismiss) private var dismiss

    // MARK: - Core Mood
    @State private var selectedLabel: HKStateOfMind.Label?
    @State private var kind: HKStateOfMind.Kind = .momentaryEmotion
    @State private var moodSort: MoodSort = .byLevel
    @State private var filter: MoodFilter = .all
    @State private var query: String = ""

    // MARK: - App Mood Details
    @State private var moodValue: Int = 3
    @State private var selectedContextTags: Set<String> = []
    @State private var customContextTag: String = ""
    
    @State private var note: String = ""
    @State private var journalPromptId: String = ""
    @State private var journalAnswer: String = ""
    @State private var visibility: MoodPrivacy = .private
    @State private var expandHero: Bool = false

    // MARK: - Media
    @State private var mediaItems: [MoodMediaItem] = []
    @State private var newPhotoURL: String = ""
    @State private var newVideoURL: String = ""

    // MARK: - Weather
    @State private var includeWeather = false
    @State private var weatherTempC: Double = 75
    @State private var weatherConditionCode: String = ""
    @State private var weatherLocationBucket: String = ""

    // MARK: - UI State
    @State private var expandedSections: Set<SectionKey> = [.context, .note]
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false

    // Replace with real auth state later
    private let isSignedIn = true

    private let cardRadius: CGFloat = 24
    private let moodColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let suggestedTags = [
        "Work", "Sleep", "Family", "Friends", "Relationship", "Health",
        "Exercise", "Food", "Music", "Travel", "Weather", "School"
    ]
    @State private var customMoodTags: [String] = []

    // MARK: - Data

    private var allMoods: [MoodItem] {
        AppleMoodLabels.all.map(MoodItem.init)
    }

    private var visibleMoods: [MoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let filtered = allMoods
            .filter { trimmed.isEmpty || $0.displayName.lowercased().contains(trimmed) }
            .filter { filter.matches($0.level) }

        switch moodSort {
        case .alphabetical:
            return filtered.sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }

        case .byLevel:
            return filtered.sorted { lhs, rhs in
                if lhs.level.sortRank == rhs.level.sortRank {
                    return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
                }
                return lhs.level.sortRank > rhs.level.sortRank
            }
        }
    }

    private var selectedMoodItem: MoodItem? {
        guard let selectedLabel else { return nil }
        return MoodItem(label: selectedLabel)
    }

    private var resolvedMoodValue: Int {
        if let selectedLabel {
            return selectedLabel.level.rawValue
        }
        return moodValue
    }

    private var draftWeather: WeatherSnapshot? {
        guard includeWeather else { return nil }

        return WeatherSnapshot(recordedAt: Date(), temperatureC: weatherTempC, conditionCode: weatherConditionCode)
    }

    private var draftDetails: AppMoodDetails {
        AppMoodDetails(
            moodValue: resolvedMoodValue,
            moodKey: selectedLabel?.displayName.lowercased(),
            emojiName: selectedLabel?.displayName,
            labels: selectedLabel.map { [$0.displayName] } ?? [],
            contextTags: Array(selectedContextTags).sorted(),
            note: note.nilIfBlank,
            journalPromptId: journalPromptId.nilIfBlank,
            journalAnswer: journalAnswer.nilIfBlank,
            visibility: visibility,
            media: mediaItems.isEmpty ? nil : mediaItems,
            weather: draftWeather,
            createdAt: Date(),
            updatedAt: Date(),
            deviceId: nil
        )
    }

    private var canSave: Bool {
        selectedLabel != nil && !isSaving
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LiquidBackdrop()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    
                    header
                    if expandHero == true {
                        selectedMoodHero
                            .onTapGesture {
                                expandHero = false
                            }
                    } else {
                        
                        moodPickerCard
                        
                    }
                    if isSignedIn {
                        Picker("Visibility", selection: $visibility) {
                            ForEach(MoodPrivacy.allCases) { option in
                                Label(option.displayName, systemImage: option.icon)
                                    .tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    expandableDetailsCard

                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }

            saveBar
        }
        .autocorrectionDisabled(false)
        .textInputAutocapitalization(.sentences)
        .alert("Couldn't save mood", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
    
    
    
}

// MARK: - Sections

@available(iOS 26.0, *)
private extension AddMoodView {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("New Check-In")
                .font(.title2.bold())

            Text("Capture how you feel with as much or as little detail as you want.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var selectedMoodHero: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((selectedMoodItem?.level.color ?? .white).opacity(0.18))
                    .frame(width: 58, height: 58)

                if let selectedMoodItem {
                    selectedMoodItem.emoji
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                } else {
                    Image(systemName: "face.smiling")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedMoodItem?.displayName ?? "No mood selected")
                    .font(.headline)

                Text(selectedMoodItem == nil
                     ? "Choose the feeling that fits best."
                     : selectedMoodSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .cardStyle(radius: cardRadius, material: .regularMaterial)
    }

    var selectedMoodSummary: String {
        guard let item = selectedMoodItem else { return "" }

        switch item.level {
        case .veryPositive: return "Very positive check-in"
        case .positive: return "Positive check-in"
        case .neutral: return "Neutral check-in"
        case .negative: return "Negative check-in"
        case .veryNegative: return "Very negative check-in"
        }
    }

    var moodPickerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Choose Mood")
                    .font(.headline)

                Spacer()

                Text("\(visibleMoods.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            searchBar
            pickerControls

            if visibleMoods.isEmpty {
                ContentUnavailableView(
                    "No moods found",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search or filter.")
                )
                .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: moodColumns, spacing: 12) {
                    ForEach(visibleMoods) { mood in
                        PremiumMoodGridCell(
                            mood: mood,
                            isSelected: selectedLabel == mood.label
                        ) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                selectedLabel = mood.label
                                expandHero = true
                                moodValue = mood.level.rawValue
                            }
                        }
                    }
                }
            }
        }
        .cardStyle(radius: cardRadius, material: .ultraThinMaterial)
    }

    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search moods", text: $query)
                .textInputAutocapitalization(.never)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .inputStyle()
    }

    var pickerControls: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MoodFilter.allCases) { option in
                        FilterChip(
                            title: option.title,
                            isSelected: filter == option
                        ) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                filter = option
                            }
                        }
                    }
                }
            }

            Picker("Sort", selection: $moodSort) {
                Text("By Level").tag(MoodSort.byLevel)
                Text("A–Z").tag(MoodSort.alphabetical)
            }
            .pickerStyle(.segmented)
        }
    }

    var checkInCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Check-In Settings")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                rowTitle("Type")

                Picker("Type", selection: $kind) {
                    Text("Emotion").tag(HKStateOfMind.Kind.momentaryEmotion)
                    Text("Mood").tag(HKStateOfMind.Kind.dailyMood)
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 10) {
                rowTitle("Intensity")

                HStack {
                    Text("Low")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(
                        value: Binding(
                            get: { Double(resolvedMoodValue) },
                            set: { moodValue = Int($0.rounded()) }
                        ),
                        in: 1...5,
                        step: 1
                    )

                    Text("High")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { value in
                        Circle()
                            .fill(value <= resolvedMoodValue
                                  ? (selectedMoodItem?.level.color ?? .white).opacity(0.9)
                                  : .white.opacity(0.12))
                            .frame(width: 10, height: 10)
                    }

                    Text("Value \(resolvedMoodValue)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle(radius: cardRadius, material: .regularMaterial)
    }

    var expandableDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("More Details")
                .font(.headline)

            detailSection(.context, title: "Context", subtitle: "What is influencing your mood?") {
                MoodTagSelectorView(
                    suggestedTags: suggestedTags,
                    selectedTags: $selectedContextTags,
                    customTags: $customMoodTags
                )
                .id(suggestedTags)
            }

            detailSection(.note, title: "Note", subtitle: "Write what is contributing to this mood.") {
                TextField("What’s going on right now?", text: $note, axis: .vertical)
                    .lineLimit(4...8)
                    .inputStyle()
            }

            detailSection(.journal, title: "Journal", subtitle: "Capture a deeper reflection for this check-in.") {
                VStack(spacing: 12) {
                    TextField("Prompt ID (optional)", text: $journalPromptId)
                        .inputStyle()

                    TextField("Journal reflection", text: $journalAnswer, axis: .vertical)
                        .lineLimit(5...10)
                        .inputStyle()
                }
            }

            
            detailSection(.media, title: "Media", subtitle: "Attach links now, or replace this with photo/video pickers later.") {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        TextField("Photo URL", text: $newPhotoURL)
                            .inputStyle()

                        Button("Add") {
                            addMedia(type: .photo, urlString: newPhotoURL)
                            newPhotoURL = ""
                        }
                        .buttonStyle(.glass)
                    }

                    HStack(spacing: 10) {
                        TextField("Video URL", text: $newVideoURL)
                            .inputStyle()

                        Button("Add") {
                            addMedia(type: .video, urlString: newVideoURL)
                            newVideoURL = ""
                        }
                        .buttonStyle(.glass)
                    }

                    if !mediaItems.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(mediaItems) { item in
                                HStack(spacing: 10) {
                                    Image(systemName: item.type == .photo ? "photo.fill" : "video.fill")
                                        .foregroundStyle(.secondary)

                                    Text(item.url)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .truncationMode(.middle)

                                    Spacer()

                                    Button(role: .destructive) {
                                        mediaItems.removeAll { $0.id == item.id }
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(12)
                                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                }
            }

            detailSection(.weather, title: "Weather Snapshot", subtitle: "Store optional weather context with the entry.") {
                VStack(spacing: 12) {
                    Toggle("Include weather data", isOn: $includeWeather)
                        .toggleStyle(.switch)

                    HStack(spacing: 10) {
                        Text(weatherConditionCode)
                        Text("\(weatherTempC)")
                        
                    }
                }
            }
        }
        .cardStyle(radius: cardRadius, material: .regularMaterial)
    }

    var saveBar: some View {
        VStack(spacing: 10) {
            Divider()
                .overlay(.white.opacity(0.08))

            Button {
                Task { await saveMood() }
            } label: {
                ZStack {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 3) {
                            Text(canSave ? "Save Mood" : "Select a mood")
                                .font(.headline)

                            if let selectedMoodItem {
                                Text("\(selectedMoodItem.displayName) • \(visibility.displayName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .disabled(!canSave)
            .padding(.horizontal)
            .padding(.bottom, 14)
        }
        .background(.ultraThinMaterial)
    }

    func rowTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    func detailSection<Content: View>(
        _ key: SectionKey,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    toggleSection(key)
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)

                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: expandedSections.contains(key) ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if expandedSections.contains(key) {
                content()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Actions

@available(iOS 26.0, *)
private extension AddMoodView {
    func toggleSection(_ key: SectionKey) {
        if expandedSections.contains(key) {
            expandedSections.remove(key)
        } else {
            expandedSections.insert(key)
        }
    }

    func addMedia(type: MoodMediaItem.MediaType, urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        mediaItems.append(
            MoodMediaItem(
                type: type,
                url: trimmed,
                thumbnailURL: nil,
                createdAt: Date()
            )
        )
    }

    func saveMood() async {
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

            // TODO: save draftDetails to your app database / Firebase
            print("App mood details:", draftDetails)

            SharedMoodCache.writeLatest(
                assetName: label.displayName,
                date: Date(),
                color: label.level.color
            )

            WidgetCenter.shared.reloadTimelines(ofKind: "MoodWidget")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("Save failed:", error)
        }
    }
}

// MARK: - Supporting Types

@available(iOS 26.0, *)
private enum SectionKey: Hashable {
    case context
    case note
    case journal
    case sharing
    case media
    case weather
}

// MARK: - Premium Mood Grid Cell

@available(iOS 26.0, *)
private struct PremiumMoodGridCell: View {
    let mood: MoodItem
    let isSelected: Bool
    let action: () -> Void

    @State private var bump = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(mood.level.color.opacity(isSelected ? 0.24 : 0.14))
                        .frame(width: 52, height: 52)

                    mood.emoji
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }

                Text(mood.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)

                Text(mood.level.sectionTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 124)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(isSelected ? 0.14 : 0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? mood.level.color.opacity(0.95) : .white.opacity(0.08),
                        lineWidth: isSelected ? 1.6 : 1
                    )
            )
            .scaleEffect(bump ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .onChange(of: isSelected) { _, newValue in
            guard newValue else { return }
            bump = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                bump = false
            }
        }
        .animation(.easeOut(duration: 0.12), value: bump)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Filter Chip

@available(iOS 26.0, *)
private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? .white.opacity(0.18) : .white.opacity(0.08))
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(isSelected ? 0.24 : 0.10), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tag Wrap

@available(iOS 26.0, *)
private struct TagWrapView: View {
    let tags: [String]
    @Binding var selectedTags: Set<String>

    private let rows = [GridItem(.adaptive(minimum: 88), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: rows, alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Button {
                    toggle(tag)
                } label: {
                    Text(tag)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(selectedTags.contains(tag) ? .instablue.opacity(0.16) : .instapurple.opacity(0.08))
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.10), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}

// MARK: - Reusable Styles

private extension View {
    func cardStyle(radius: CGFloat, material: Material) -> some View {
        self
            .padding(18)
            .liquidGlassCard(cornerRadius: radius, material: material)
    }

    func inputStyle() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                .white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
    }
}

// MARK: - Helpers

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    RootShellView()
        .environmentObject(HealthKitMoodStore())
        .environmentObject(AuthService())
        .environmentObject(DeepLinkRouter())
}
