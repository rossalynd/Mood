import SwiftUI
import HealthKit
import WidgetKit

@available(iOS 26.0, *)
struct AddMoodView: View {
    @EnvironmentObject private var moodStore: HealthKitMoodStore
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var selectedLabel: HKStateOfMind.Label?
    @State private var kind: HKStateOfMind.Kind = .momentaryEmotion

    @State private var query = ""
    @State private var filter: MoodFilter = .all

    @State private var showDetails = false
    @State private var selectedContextTags: Set<String> = []
    @State private var note = ""
    @State private var journalAnswer = ""
    @State private var visibility: MoodPrivacy = .private

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false

    // Replace with real auth state later
    private let isSignedIn = true

    // MARK: - Constants

    private let cardRadius: CGFloat = 24

    private let suggestedTags = [
        "Sleep", "Work", "Music", "Friends", "Family", "Exercise",
        "Relationship", "Travel", "Weather", "Health", "Food", "School"
    ]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // MARK: - Derived Data

    private var allMoods: [MoodItem] {
        AppleMoodLabels.all.map(MoodItem.init)
    }

    private var visibleMoods: [MoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return allMoods
            .filter {
                trimmed.isEmpty || $0.displayName.lowercased().contains(trimmed)
            }
            .filter {
                filter.matches($0.level)
            }
            .sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            LiquidBackdrop()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    checkInCard
                    detailsCard
                    moodGridCard

                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }

            saveBar
        }
        .autocorrectionDisabled()
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
        VStack(alignment: .leading, spacing: 4) {
            Text("Add Mood")
                .font(.title2.bold())

            Text("Choose the feeling that fits best right now.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var checkInCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Check-In")
                .font(.headline)

            searchBar
            filterChips
        }
        .cardStyle(radius: cardRadius, material: .regularMaterial)
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

    var filterChips: some View {
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
    }

    var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    showDetails.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add more details")
                            .font(.headline)

                        Text(
                            isSignedIn
                            ? "Add context, notes, privacy, and journal details."
                            : "Add a note now. More synced details can appear when signed in."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showDetails {
                VStack(alignment: .leading, spacing: 18) {
                    contextSection
                    noteSection

                    if isSignedIn {
                        privacySection
                        journalSection
                    } else {
                        signInInfoCard
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .cardStyle(radius: cardRadius, material: .regularMaterial)
    }

    var contextSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Context")
                .font(.headline)

            TagWrapView(tags: suggestedTags, selectedTags: $selectedContextTags)
        }
    }

    var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Note")
                .font(.headline)

            TextField("What’s contributing to this feeling?", text: $note, axis: .vertical)
                .lineLimit(3...6)
                .inputStyle()
        }
    }

    var privacySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Visibility")
                .font(.headline)

            Picker("Visibility", selection: $visibility) {
                ForEach(MoodPrivacy.allCases) { option in
                    Label(option.displayName, systemImage: option.icon)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    var journalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Journal Reflection")
                .font(.headline)

            TextField("Write a short reflection…", text: $journalAnswer, axis: .vertical)
                .lineLimit(4...8)
                .inputStyle()
        }
    }

    var signInInfoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Sign in later to sync privacy, journal, media, weather, and other app-only mood details.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    var moodGridCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Choose a Mood")
                    .font(.headline)

                Spacer()

                Text("\(visibleMoods.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    )
            }

            if visibleMoods.isEmpty {
                ContentUnavailableView(
                    "No moods found",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search or filter.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(visibleMoods) { mood in
                        MoodCell2(
                            mood: mood,
                            isSelected: mood.label == selectedLabel
                        ) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                selectedLabel = mood.label
                            }
                        }
                    }
                }
            }
        }
        .cardStyle(radius: cardRadius, material: .ultraThinMaterial)
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
                        VStack(spacing: 2) {
                            Text(selectedLabel == nil ? "Select a mood" : "Save Mood")
                                .font(.headline)

                            if let selectedLabel {
                                Text(selectedLabel.displayName)
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
            .disabled(isSaving || selectedLabel == nil)
            .padding(.horizontal)
            .padding(.bottom, 14)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Actions

@available(iOS 26.0, *)
private extension AddMoodView {
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

// MARK: - Mood Cell

private struct MoodCell2: View {
    let mood: MoodItem
    let isSelected: Bool
    let action: () -> Void

    @State private var bump = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(mood.displayName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .padding(4)

                Text(mood.displayName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Spacer()
            }
           
            .frame(maxWidth: .infinity, minHeight: 45)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(mood.level.color.opacity(isSelected ? 0.16 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(
                        isSelected ? .white.opacity(0.95) : .white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .scaleEffect(bump ? 1.05 : 1.0)
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
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
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
                        .stroke(.white.opacity(isSelected ? 0.22 : 0.10), lineWidth: 1)
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

    private let rows = [
        GridItem(.adaptive(minimum: 80), spacing: 8)
    ]

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
                        .background(selectedTags.contains(tag) ? .instablue.opacity(0.18) : .instapurple.opacity(0.08))
                        
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
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
