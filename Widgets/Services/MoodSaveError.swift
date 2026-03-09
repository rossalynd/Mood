//
//  MoodSaveError.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore
import HealthKit
import UIKit

enum MoodSaveError: LocalizedError {
    case userNotSignedIn
    case invalidMoodSelection

    var errorDescription: String? {
        switch self {
        case .userNotSignedIn:
            return "No signed-in user was found."
        case .invalidMoodSelection:
            return "The selected mood could not be converted into a valid mood entry."
        }
    }
}

@MainActor
final class MoodFirestoreService: ObservableObject {
    private let db = Firestore.firestore()

    func saveMoodEntry(
        selectedLabel: HKStateOfMind.Label,
        details: AppMoodDetails
    ) async throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw MoodSaveError.userNotSignedIn
        }

        let now = Date()
        let documentRef = db
            .collection("users")
            .document(uid)
            .collection("moods")
            .document()

        let entry = FirestoreMoodEntry(
            id: documentRef.documentID,
            moodValue: details.moodValue ?? selectedLabel.level.rawValue,
            moodKey: details.moodKey ?? selectedLabel.displayName.lowercased(),
            emoji: details.emojiName ?? selectedLabel.displayName,
            labels: details.labels ?? [selectedLabel.displayName],
            contextTags: details.contextTags ?? [],
            note: emptyToNil(details.note),
            journalPromptId: emptyToNil(details.journalPromptId),
            journalAnswer: emptyToNil(details.journalAnswer),
            visibility: (details.visibility ?? .private).rawValue,
            media: details.media ?? [],
            weather: details.weather,
            createdAt: details.createdAt ?? now,
            updatedAt: now,
            deviceId: details.deviceId ?? UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
        )

        try documentRef.setData(from: entry)
        return documentRef.documentID
    }

    func updateMoodEntry(
        moodId: String,
        details: AppMoodDetails,
        selectedLabel: HKStateOfMind.Label
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw MoodSaveError.userNotSignedIn
        }

        let documentRef = db
            .collection("users")
            .document(uid)
            .collection("moods")
            .document(moodId)

        let entry = FirestoreMoodEntry(
            id: moodId,
            moodValue: details.moodValue ?? selectedLabel.level.rawValue,
            moodKey: details.moodKey ?? selectedLabel.displayName.lowercased(),
            emoji: details.emojiName ?? selectedLabel.displayName,
            labels: details.labels ?? [selectedLabel.displayName],
            contextTags: details.contextTags ?? [],
            note: emptyToNil(details.note),
            journalPromptId: emptyToNil(details.journalPromptId),
            journalAnswer: emptyToNil(details.journalAnswer),
            visibility: (details.visibility ?? .private).rawValue,
            media: details.media ?? [],
            weather: details.weather,
            createdAt: details.createdAt ?? Date(),
            updatedAt: Date(),
            deviceId: details.deviceId ?? UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
        )

        try documentRef.setData(from: entry, merge: true)
    }

    private func emptyToNil(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
