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
    @State private var draft = EditDraft()

    var body: some View {
        ZStack {
            LiquidBackdrop()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    MoodHeroCard(display: display)

                    MoodQuickStatsRow(display: display)

                    if !display.labels.isEmpty {
                        MoodDetailSection(title: "Mood Labels", systemImage: "sparkles") {
                            MoodTagCloud(
                                tags: display.labels,
                                tint: display.level.color.opacity(0.16)
                            )
                        }
                    }

                    if !display.contextTags.isEmpty || isEditing {
                        MoodDetailSection(title: "Context", systemImage: "square.grid.2x2.fill") {
                            if isEditing {
                                EditableContextTagsSection(draft: $draft)
                            } else {
                                MoodOptionalTagContent(tags: display.contextTags)
                            }
                        }
                    }

                    if display.hasNote || isEditing {
                        MoodDetailSection(title: "Note", systemImage: "note.text") {
                            if isEditing {
                                PremiumTextEditor(
                                    text: $draft.note,
                                    placeholder: "Add a note..."
                                )
                            } else {
                                MoodBodyText(display.note)
                            }
                        }
                    }

                    if display.hasJournal || isEditing {
                        MoodDetailSection(title: "Journal", systemImage: "book.pages.fill") {
                            if isEditing {
                                PremiumTextEditor(
                                    text: $draft.journalAnswer,
                                    placeholder: "Write your reflection..."
                                )
                            } else {
                                MoodBodyText(display.journalAnswer)
                            }
                        }
                    }

                    if display.visibility != nil || isEditing {
                        MoodDetailSection(title: "Visibility", systemImage: "eye.fill") {
                            if isEditing {
                                VisibilityEditor(selection: $draft.visibility)
                            } else if let visibility = display.visibility {
                                VisibilityDisplayRow(visibility: visibility)
                            } else {
                                MoodEmptyStateText("No visibility set")
                            }
                        }
                    }

                    if let weather = display.weather {
                        MoodDetailSection(title: "Weather", systemImage: "cloud.sun.fill") {
                            WeatherDetailContent(weather: weather)
                        }
                    }

                    if !display.media.isEmpty || isEditing {
                        MoodDetailSection(title: "Media", systemImage: "photo.on.rectangle.angled") {
                            if draft.media.isEmpty && isEditing {
                                MoodEmptyStateText("No media attached")
                            } else if display.media.isEmpty && !isEditing {
                                MoodEmptyStateText("No media attached")
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(isEditing ? draft.media : display.media) { item in
                                        MediaItemRow(
                                            item: item,
                                            isEditing: isEditing
                                        ) {
                                            draft.media.removeAll { $0.id == item.id }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MoodDetailSection(title: "Details", systemImage: "info.circle.fill") {
                        VStack(spacing: 12) {
                            DetailInfoRow(title: "Mood Key", value: display.moodKey)
                            DetailInfoRow(title: "Mood Value", value: display.moodValueText)
                            DetailInfoRow(title: "Created", value: display.createdAtText)
                            DetailInfoRow(title: "Updated", value: display.updatedAtText)
                            DetailInfoRow(title: "Device", value: display.deviceId)
                        }
                    }

                    Color.clear.frame(height: 28)
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
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        if isEditing {
                            // save placeholder
                        } else {
                            draft = EditDraft(from: mood)
                        }
                        isEditing.toggle()
                    }
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .onAppear {
            draft = EditDraft(from: mood)
        }
    }

    private var display: MoodDisplayModel {
        MoodDisplayModel(mood: mood)
    }
}

// MARK: - Display Model

@available(iOS 26.0, *)
private struct MoodDisplayModel {
    let mood: AppMoodDetails

    var labels: [String] { mood.labels ?? [] }
    var contextTags: [String] { mood.contextTags ?? [] }
    var note: String { mood.note ?? "" }
    var journalAnswer: String { mood.journalAnswer ?? "" }
    var visibility: MoodPrivacy? { mood.visibility }
    var weather: WeatherSnapshot? { mood.weather }
    var media: [MoodMediaItem] { mood.media ?? [] }
    var deviceId: String { mood.deviceId ?? "—" }

    var level: MoodLevel {
        guard let value = mood.moodValue, let level = MoodLevel(rawValue: value) else {
            return .neutral
        }
        return level
    }

    var title: String {
        if let key = mood.moodKey, !key.isEmpty {
            return key.capitalized
        }
        if let first = labels.first, !first.isEmpty {
            return first
        }
        return "Mood"
    }

    var subtitle: String {
        switch level {
        case .veryPositive: return "Very positive check-in"
        case .positive: return "Positive check-in"
        case .neutral: return "Neutral check-in"
        case .negative: return "Negative check-in"
        case .veryNegative: return "Very negative check-in"
        }
    }

    var image: Image {
        if let emojiName = mood.emojiName, !emojiName.isEmpty {
            return Image(emojiName)
        }
        return Image(systemName: "face.smiling")
    }

    var hasNote: Bool { !note.trimmed.isEmpty }
    var hasJournal: Bool { !journalAnswer.trimmed.isEmpty }

    var moodKey: String {
        mood.moodKey?.capitalized ?? "—"
    }

    var moodValueText: String {
        mood.moodValue.map(String.init) ?? "—"
    }

    var createdAtText: String {
        mood.createdAt.map(AppFormatters.detailDate.string(from:)) ?? "—"
    }

    var updatedAtText: String {
        mood.updatedAt.map(AppFormatters.detailDate.string(from:)) ?? "—"
    }

    var heroDateText: String? {
        mood.createdAt.map(AppFormatters.detailDate.string(from:))
    }

    var privacyText: String {
        visibility?.displayName ?? "None"
    }

    var privacyIcon: String {
        
        visibility?.icon ?? "eye.slash"
    }

    var mediaCountText: String {
        "\(media.count)"
    }
}

// MARK: - Edit Draft

private struct EditDraft {
    var contextTags: [String] = []
    var newContextTag: String = ""
    var note: String = ""
    var journalAnswer: String = ""
    var visibility: MoodPrivacy = .private
    var media: [MoodMediaItem] = []

    init() {}

    init(from mood: AppMoodDetails) {
        contextTags = mood.contextTags ?? []
        note = mood.note ?? ""
        journalAnswer = mood.journalAnswer ?? ""
        visibility = mood.visibility ?? .private
        media = mood.media ?? []
    }
}

// MARK: - Hero

@available(iOS 26.0, *)
private struct MoodHeroCard: View {
    let display: MoodDisplayModel

    var body: some View {
        VStack(spacing: 16) {
            
            ZStack{
                
                HStack() {
                    Spacer()
                    VStack {
                        ZStack {
                            Circle()
                                .fill(display.level.color.opacity(0.18))
                                .frame(width: 30, height: 30)
                            Image(systemName: display.privacyIcon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.75))
                            
                        }
                            Spacer()
                        
                    }
                }
                VStack {
                    ZStack {
                        Circle()
                            .fill(display.level.color.opacity(0.18))
                            .frame(width: 112, height: 112)
                        
                        Circle()
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                            .frame(width: 112, height: 112)
                        
                        display.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                    }
                    .shadow(color: display.level.color.opacity(0.18), radius: 24, x: 0, y: 10)
                    
                    VStack(spacing: 6) {
                        Text(display.title)
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)
                        
                        
                        if let heroDateText = display.heroDateText {
                            Text(heroDateText)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.58))
                        }
                    }
                }
            }
            
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 18)
        .background(MoodCardBackground())
    }
}

// MARK: - Quick Stats

@available(iOS 26.0, *)
private struct MoodQuickStatsRow: View {
    let display: MoodDisplayModel

    var body: some View {
        HStack(spacing: 12) {
            StatPill(
                title: "Level",
                value: display.level.sectionTitle,
                systemImage: "circle.fill"
            )

            StatPill(
                title: "Privacy",
                value: display.privacyText,
                systemImage: display.privacyIcon
            )

            StatPill(
                title: "Media",
                value: display.mediaCountText,
                systemImage: "photo"
            )
        }
    }
}

// MARK: - Section Wrapper

@available(iOS 26.0, *)
private struct MoodDetailSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))

                Text(title)
                    .font(.headline.weight(.semibold))
            }
            .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 14) {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MoodCardBackground())
        }
    }
}

// MARK: - Card Background

private struct MoodCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 24, x: 0, y: 14)
    }
}

// MARK: - Reusable Small Views

private struct StatPill: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))

                Text(value)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct DetailInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.65))
                .frame(width: 88, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}

private struct MoodBodyText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
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
}

private struct MoodEmptyStateText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.55))
    }
}

private struct PremiumTextEditor: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.07))

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)

            if text.isEmpty {
                Text(placeholder)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.38))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
            }

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minHeight: 130)
        }
    }
}

// MARK: - Context Tags

private struct EditableContextTagsSection: View {
    @Binding var draft: EditDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if draft.contextTags.isEmpty {
                MoodEmptyStateText("No context tags yet")
            } else {
                MoodTagCloud(tags: draft.contextTags)
            }

            HStack(spacing: 10) {
                TextField("Add a context tag", text: $draft.newContextTag)
                    .textInputAutocapitalization(.words)
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

                Button {
                    let trimmed = draft.newContextTag.trimmed
                    guard !trimmed.isEmpty else { return }
                    draft.contextTags.append(trimmed)
                    draft.newContextTag = ""
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct MoodOptionalTagContent: View {
    let tags: [String]

    var body: some View {
        if tags.isEmpty {
            MoodEmptyStateText("No context tags")
        } else {
            MoodTagCloud(tags: tags)
        }
    }
}

// MARK: - Visibility

private struct VisibilityDisplayRow: View {
    let visibility: MoodPrivacy

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: visibility.icon)
                .font(.subheadline.weight(.semibold))
                .frame(width: 26, height: 26)
                .background(.white.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(visibility.displayName)
                    .font(.subheadline.weight(.semibold))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()
        }
    }

    private var description: String {
        switch visibility {
        case .private:
            return "Only you can see this mood"
        case .friends:
            return "Visible to approved friends"
        case .public:
            return "Visible to anyone"
        }
    }
}

private struct VisibilityEditor: View {
    @Binding var selection: MoodPrivacy

    var body: some View {
        VStack(spacing: 10) {
            ForEach(MoodPrivacy.allCases) { option in
                Button {
                    selection = option
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: option.icon)
                            .frame(width: 22)

                        Text(option.displayName)
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        if selection == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(selection == option ? .white.opacity(0.12) : .white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Weather

private struct WeatherDetailContent: View {
    let weather: WeatherSnapshot

    var body: some View {
        VStack(spacing: 12) {
            DetailInfoRow(
                title: "Temperature",
                value: "\(Int(weather.temperatureC.rounded()))°C"
            )
            DetailInfoRow(
                title: "Condition",
                value: weather.conditionCode
            )
            DetailInfoRow(
                title: "Recorded",
                value: AppFormatters.detailDate.string(from: weather.recordedAt)
            )
        }
    }
}

// MARK: - Media

private struct MediaItemRow: View {
    let item: MoodMediaItem
    let isEditing: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.08))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: item.type == .photo ? "photo.fill" : "video.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.75))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.type == .photo ? "Photo" : "Video")
                    .font(.subheadline.weight(.semibold))

                Text(item.url)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)

                Text(AppFormatters.detailDate.string(from: item.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.48))
            }

            Spacer()

            if isEditing {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .padding(10)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Tag Cloud

private struct MoodTagCloud: View {
    let tags: [String]
    var tint: Color = .white.opacity(0.08)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(chunkedTags, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(tint, in: Capsule())
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
        stride(from: 0, to: tags.count, by: 3).map {
            Array(tags[$0..<min($0 + 3, tags.count)])
        }
    }
}

// MARK: - Formatters

private enum AppFormatters {
    static let detailDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Helpers

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    NavigationStack {
        MoodDetailView(
            mood: AppMoodDetails(
                moodValue: 4,
                moodKey: "happy",
                emojiName: "Happy",
                labels: ["Happy"],
                contextTags: ["Music", "Friends", "Travel"],
                note: "I felt really light and energized after getting outside and listening to music.",
                journalAnswer: "Today reminded me that my mood shifts quickly when I give myself room to enjoy the moment.",
                visibility: .private,
                media: [
                    MoodMediaItem(type: .photo, url: "https://example.com/photo1.jpg"),
                    MoodMediaItem(type: .video, url: "https://example.com/video1.mp4")
                ],
                weather: WeatherSnapshot(
                    recordedAt: .now.addingTimeInterval(-1800),
                    temperatureC: 18.4,
                    conditionCode: "stars.fill"
                ),
                createdAt: .now.addingTimeInterval(-7200),
                updatedAt: .now.addingTimeInterval(-1800),
                deviceId: "iPhone"
            )
        )
    }
}
