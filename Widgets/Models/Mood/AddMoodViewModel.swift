//
//  AddMoodViewModel.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import SwiftUI
import HealthKit
import WidgetKit
import CoreLocation
import WeatherKit

@available(iOS 26.0, *)
@MainActor
final class AddMoodViewModel: ObservableObject {
    // MARK: - Services
    private let weatherService = AppWeatherService()
    private let locationManager = SimpleLocationManager()
    private let moodService = MoodFirestoreService()

    // MARK: - Core Mood
    @Published var selectedLabel: HKStateOfMind.Label?
    @Published var kind: HKStateOfMind.Kind = .momentaryEmotion
    @Published var moodSort: MoodSort = .byLevel
    @Published var filter: MoodFilter = .all
    @Published var query: String = ""

    // MARK: - App Mood Details
    @Published var moodValue: Int = 3
    @Published var selectedContextTags: Set<String> = []
    @Published var customContextTag: String = ""
    @Published var customMoodTags: [String] = []

    @Published var note: String = ""
    @Published var journalAnswer: String = ""
    @Published var visibility: MoodPrivacy = .private
    @Published var expandHero: Bool = false

    // MARK: - Media
    @Published var mediaItems: [MoodMediaItem] = []
    @Published var newPhotoURL: String = ""
    @Published var newVideoURL: String = ""

    // MARK: - Weather
    @Published var weatherTempC: Double?
    @Published var weatherConditionCode: String = ""
    @Published var weatherLocationBucket: String = ""
    @Published var isLoadingWeather = false
    @Published var weatherErrorMessage: String?

    // MARK: - UI State
    @Published var expandedSections: Set<SectionKey> = [.context, .note]
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var didSaveSuccessfully = false

    let cardRadius: CGFloat = 24

    let moodColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    let suggestedTags = [
        "Work", "Sleep", "Family", "Friends", "Relationship", "Health",
        "Exercise", "Food", "Music", "Travel", "Weather", "School"
    ]

    // MARK: - Derived Data

    var allMoods: [MoodItem] {
        AppleMoodLabels.all.map(MoodItem.init)
    }

    var visibleMoods: [MoodItem] {
        let trimmed = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

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

    var selectedMoodItem: MoodItem? {
        guard let selectedLabel else { return nil }
        return MoodItem(label: selectedLabel)
    }

    var resolvedMoodValue: Int {
        selectedLabel?.level.rawValue ?? moodValue
    }

    var draftWeather: WeatherSnapshot? {
        guard let weatherTempC else { return nil }

        return WeatherSnapshot(
            recordedAt: Date(),
            temperatureC: weatherTempC,
            conditionCode: weatherConditionCode
        )
    }

    var draftDetails: AppMoodDetails {
        AppMoodDetails(
            moodValue: resolvedMoodValue,
            moodKey: selectedLabel?.displayName.lowercased(),
            emojiName: selectedLabel?.displayName,
            labels: selectedLabel.map { [$0.displayName] } ?? [],
            contextTags: Array(selectedContextTags).sorted(),
            note: note.nilIfBlank,
            journalAnswer: journalAnswer.nilIfBlank,
            visibility: visibility,
            media: mediaItems.isEmpty ? nil : mediaItems,
            weather: draftWeather,
            createdAt: Date(),
            updatedAt: Date(),
            deviceId: nil
        )
    }

    var canSave: Bool {
        selectedLabel != nil && !isSaving
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

    var weatherSummaryText: String {
        guard let weatherTempC else { return "No weather loaded" }
        let temp = Int(weatherTempC.rounded())
        return "\(temp)°C • \(weatherConditionCode)"
    }

    // MARK: - Actions

    func toggleSection(_ key: SectionKey) {
        if expandedSections.contains(key) {
            expandedSections.remove(key)
        } else {
            expandedSections.insert(key)
        }
    }

    func selectMood(_ mood: MoodItem) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            selectedLabel = mood.label
            expandHero = true
            moodValue = mood.level.rawValue
        }
    }

    func clearQuery() {
        query = ""
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

    func removeMedia(_ item: MoodMediaItem) {
        mediaItems.removeAll { $0.id == item.id }
    }

    func addPhotoURL() {
        addMedia(type: .photo, urlString: newPhotoURL)
        newPhotoURL = ""
    }

    func addVideoURL() {
        addMedia(type: .video, urlString: newVideoURL)
        newVideoURL = ""
    }

    func loadWeather(for location: CLLocation?) async {
        guard let location else {
            weatherErrorMessage = "Current location is unavailable."
            return
        }

        isLoadingWeather = true
        weatherErrorMessage = nil
        defer { isLoadingWeather = false }

        do {
            let snapshot = try await weatherService.fetchSnapshot(for: location)
            weatherTempC = snapshot.temperatureC
            weatherConditionCode = snapshot.conditionCode
            weatherLocationBucket = Self.makeLocationBucket(from: location)
        } catch {
            weatherErrorMessage = error.localizedDescription
            print("Weather load failed:", error)
        }
    }

    func loadWeather() async {
        guard !isLoadingWeather else { return }

        isLoadingWeather = true
        weatherErrorMessage = nil
        defer { isLoadingWeather = false }

        do {
            let location = try await locationManager.requestCurrentLocation()
            let weather = try await weatherService.fetchSnapshot(for: location)

            weatherConditionCode = weather.conditionCode
            weatherTempC = weather.temperatureC
            weatherLocationBucket = Self.makeLocationBucket(from: location)
        } catch {
            weatherErrorMessage = error.localizedDescription
            weatherConditionCode = "Unavailable"
            weatherTempC = nil
        }
    }

    func refreshWeatherIfNeeded(for location: CLLocation?) async {
        await loadWeather(for: location)
    }

    func setIncludeWeather(_ location: CLLocation?) async {
        await loadWeather(for: location)
    }

    func saveMood(using moodStore: HealthKitMoodStore, auth: AuthService) async {
        guard let label = selectedLabel else { return }

        didSaveSuccessfully = false
        errorMessage = nil
        showError = false
        isSaving = true
        defer { isSaving = false }

        let moodID = makeMoodID()
        let now = Date()
        let metadata = makeHealthMetadata(moodID: moodID)

        do {
            try await moodStore.requestAuth()

            try await moodStore.saveMood(
                valence: label.defaultValence,
                kind: kind,
                labels: [label],
                metadata: metadata
            )

            if auth.currentUser?.uid != nil {
                do {
                    try await moodService.saveMoodEntry(
                        selectedLabel: label,
                        details: appMoodDetails(createdAt: now, updatedAt: now)
                    )
                } catch {
                    errorMessage = "Firestore save failed: \(error.localizedDescription)"
                    showError = true
                    print("Firestore save failed:", error)
                    return
                }
            }

            SharedMoodCache.writeLatest(
                assetName: label.displayName,
                date: now,
                color: label.level.color
            )

            WidgetCenter.shared.reloadTimelines(ofKind: "MoodWidget")
            didSaveSuccessfully = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("Save failed:", error)
        }
    }

    // MARK: - Builders

    private func appMoodDetails(createdAt: Date, updatedAt: Date) -> AppMoodDetails {
        AppMoodDetails(
            moodValue: resolvedMoodValue,
            moodKey: selectedLabel?.displayName.lowercased(),
            emojiName: selectedLabel?.displayName,
            labels: selectedLabel.map { [$0.displayName] } ?? [],
            contextTags: Array(selectedContextTags).sorted(),
            note: note.nilIfBlank,
            journalAnswer: journalAnswer.nilIfBlank,
            visibility: visibility,
            media: mediaItems.isEmpty ? nil : mediaItems,
            weather: draftWeather,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deviceId: makeDeviceID()
        )
    }

    private func makeMoodID() -> String {
        "mood_\(UUID().uuidString.lowercased())"
    }

    private func makeDeviceID() -> String {
        DeviceID.current()
    }

    private func makeHealthMetadata(moodID: String) -> [String: Any] {
        var metadata: [String: Any] = [
            HKMetadataKeySyncIdentifier: moodID,
            HKMetadataKeySyncVersion: 1,
            MoodMetadataKeys.appMoodID: moodID,
            MoodMetadataKeys.moodValue: resolvedMoodValue,
            MoodMetadataKeys.visibility: visibility.rawValue,
            MoodMetadataKeys.deviceId: makeDeviceID()
        ]

        if let label = selectedLabel {
            metadata[MoodMetadataKeys.moodKey] = label.displayName.lowercased()
            metadata[MoodMetadataKeys.emojiName] = label.displayName
            metadata[MoodMetadataKeys.labels] = [label.displayName]
        }

        let tags = Array(selectedContextTags).sorted()
        if !tags.isEmpty {
            metadata[MoodMetadataKeys.contextTags] = tags
        }

        if let note = note.nilIfBlank {
            metadata[MoodMetadataKeys.note] = note
        }

        if let journalAnswer = journalAnswer.nilIfBlank {
            metadata[MoodMetadataKeys.journalAnswer] = journalAnswer
        }

        return metadata
    }

    // MARK: - Helpers

    private static func makeLocationBucket(from location: CLLocation) -> String {
        let lat = round(location.coordinate.latitude * 10) / 10
        let lon = round(location.coordinate.longitude * 10) / 10
        return "\(lat),\(lon)"
    }
}
