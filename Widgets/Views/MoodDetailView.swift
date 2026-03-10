//
//  MoodDetailView.swift
//  Widgets
//
//  Created by Rosie on 3/10/26.
//


import SwiftUI

@available(iOS 26.0, *)
struct MoodDetailView: View {
    let mood: AppMoodDetails

    @State private var isEditing = false

    // Editable placeholders
    @State private var editedMoodKey: String = ""
    @State private var editedMoodValue: String = ""
    @State private var editedNote: String = ""
    @State private var editedJournalAnswer: String = ""
    @State private var editedLabels: [String] = []
    @State private var editedContextTags: [String] = []

    var body: some View {
        ZStack {
            LiquidBackdrop()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerCard

                    detailsSection(
                        title: "Mood"
                    ) {
                        if isEditing {
                            VStack(spacing: 12) {
                                premiumTextField(
                                    title: "Mood Name",
                                    text: $editedMoodKey,
                                    placeholder: "How were you feeling?"
                                )

                                premiumTextField(
                                    title: "Mood Value",
                                    text: $editedMoodValue,
                                    placeholder: "Mood intensity"
                                )
                            }
                        } else {
                            infoRow("Mood Name", value: mood.moodKey?.formattedMoodTitle ?? "Unknown")
                            infoRow("Mood Value", value: mood.moodValue.map(String.init) ?? "—")
                        }
                    }

                    if !(currentLabels.isEmpty) || isEditing {
                        detailsSection(title: "Labels") {
                            editableChipSection(
                                items: $editedLabels,
                                fallbackItems: currentLabels,
                                placeholder: "Add label",
                                isEditing: isEditing
                            )
                        }
                    }

                    if !(currentContextTags.isEmpty) || isEditing {
                        detailsSection(title: "Context") {
                            editableChipSection(
                                items: $editedContextTags,
                                fallbackItems: currentContextTags,
                                placeholder: "Add context tag",
                                isEditing: isEditing
                            )
                        }
                    }

                    if mood.note?.isEmpty == false || isEditing {
                        detailsSection(title: "Note") {
                            if isEditing {
                                premiumTextEditor(
                                    text: $editedNote,
                                    placeholder: "Write a note..."
                                )
                            } else {
                                textBlock(mood.note ?? "No note")
                            }
                        }
                    }

                    if mood.journalAnswer?.isEmpty == false || isEditing {
                        detailsSection(title: "Journal") {
                            if isEditing {
                                premiumTextEditor(
                                    text: $editedJournalAnswer,
                                    placeholder: "Reflect on what was happening..."
                                )
                            } else {
                                textBlock(mood.journalAnswer ?? "No journal entry")
                            }
                        }
                    }

                    if let visibility = mood.visibility {
                        detailsSection(title: "Visibility") {
                            infoRow("Privacy", value: String(describing: visibility).capitalized)
                        }
                    }

                    if let weather = mood.weather {
                        weatherSection(weather)
                    }

                    if let media = mood.media, !media.isEmpty {
                        mediaSection(media)
                    }

                    detailsSection(title: "Details") {
                        infoRow("Created", value: mood.createdAt?.formattedMoodDate ?? "—")
                        infoRow("Updated", value: mood.updatedAt?.formattedMoodDate ?? "—")
                        infoRow("Device ID", value: mood.deviceId ?? "—")
                    }

                    Color.clear
                        .frame(height: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation(.spring(duration: 0.32)) {
                        if !isEditing {
                            beginEditing()
                        } else {
                            // Placeholder only for now.
                            // Later this is where you can save changes.
                        }
                        isEditing.toggle()
                    }
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .onAppear {
            beginEditing()
        }
    }
}

// MARK: - Subviews

@available(iOS 26.0, *)
private extension MoodDetailView {
    var headerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.10))
                    .frame(width: 108, height: 108)

                Circle()
                    .stroke(.white.opacity(0.14), lineWidth: 1)
                    .frame(width: 108, height: 108)

                moodImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
            }
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)

            VStack(spacing: 6) {
                Text(mood.moodKey?.formattedMoodTitle ?? "Mood")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                if let createdAt = mood.createdAt {
                    Text(createdAt.formattedMoodDate)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 18)
        .background(premiumCardBackground)
    }

    var moodImage: Image {
        if let emojiName = mood.emojiName, !emojiName.isEmpty {
            return Image(emojiName)
        } else {
            return Image(systemName: "face.smiling.inverse")
        }
    }

    var premiumCardBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 24, x: 0, y: 14)
    }

    func detailsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline.weight(.semibold))
                .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(premiumCardBackground)
        }
    }

    func infoRow(_ title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }

    func textBlock(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.95))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }

    func premiumTextField(
        title: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        }
    }

    func premiumTextEditor(
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.07))

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)

            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.white.opacity(0.38))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
            }

            TextEditor(text: text)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minHeight: 130)
        }
    }

    func editableChipSection(
        items: Binding<[String]>,
        fallbackItems: [String],
        placeholder: String,
        isEditing: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            let displayItems = isEditing ? items.wrappedValue : fallbackItems

            if displayItems.isEmpty {
                Text(isEditing ? "No items yet" : "—")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                FlexibleTagWrap(tags: displayItems)
            }

            if isEditing {
                Button {
                    items.wrappedValue.append(placeholder)
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    func weatherSection(_ weather: WeatherSnapshot) -> some View {
        detailsSection(title: "Weather") {
            VStack(spacing: 12) {
                infoRow("Condition", value: weather.conditionText ?? "—")
                infoRow("Temperature", value: weather.temperatureDisplay ?? "—")
                infoRow("Location", value: weather.locationName ?? "—")
            }
        }
    }

    func mediaSection(_ media: [MoodMediaItem]) -> some View {
        detailsSection(title: "Media") {
            VStack(spacing: 12) {
                ForEach(Array(media.indices), id: \.self) { index in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white.opacity(0.08))
                            .frame(width: 54, height: 54)
                            .overlay {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.72))
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Media Item \(index + 1)")
                                .font(.subheadline.weight(.semibold))

                            Text("Placeholder preview")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                        }

                        Spacer()

                        if isEditing {
                            Button("Edit") {
                                // Placeholder
                            }
                            .font(.caption.weight(.semibold))
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.white.opacity(0.05))
                    )
                }
            }
        }
    }

    var currentLabels: [String] {
        mood.labels ?? []
    }

    var currentContextTags: [String] {
        mood.contextTags ?? []
    }

    func beginEditing() {
        editedMoodKey = mood.moodKey ?? ""
        editedMoodValue = mood.moodValue.map(String.init) ?? ""
        editedNote = mood.note ?? ""
        editedJournalAnswer = mood.journalAnswer ?? ""
        editedLabels = mood.labels ?? []
        editedContextTags = mood.contextTags ?? []
    }
}

// MARK: - Flexible Tags

@available(iOS 26.0, *)
private struct FlexibleTagWrap: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(chunkedTags, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.08), in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.10), lineWidth: 1)
                            )
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var chunkedTags: [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []

        for tag in tags {
            if currentRow.count >= 3 {
                rows.append(currentRow)
                currentRow = [tag]
            } else {
                currentRow.append(tag)
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}

// MARK: - Formatting Helpers

private extension String {
    var formattedMoodTitle: String {
        replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

private extension Date {
    var formattedMoodDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Placeholder Helpers For Unknown Models

extension WeatherSnapshot {
    var conditionText: String? { nil }
    var temperatureDisplay: String? { nil }
    var locationName: String? { nil }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    NavigationStack {
        MoodDetailView(
            mood: AppMoodDetails(
                moodValue: 8,
                moodKey: "peaceful",
                emojiName: "calmMood",
                labels: ["Calm", "Grounded", "Open"],
                contextTags: ["Home", "Music", "Evening"],
                note: "I felt really centered tonight after taking some quiet time for myself and listening to music.",
                journalAnswer: "What helped most was slowing down and letting myself be present instead of rushing into the next thing.",
                visibility: nil,
                media: [],
                weather: nil,
                createdAt: .now.addingTimeInterval(-3600 * 6),
                updatedAt: .now.addingTimeInterval(-1800),
                deviceId: "iPhone Placeholder"
            )
        )
    }
}