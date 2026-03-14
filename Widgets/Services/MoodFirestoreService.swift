//
//  MoodFirestoreService.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
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
        let moodID = db
            .collection("users")
            .document(uid)
            .collection("moods")
            .document()
            .documentID

        let resolvedVisibility = details.visibility ?? .private

        let entry = FirestoreMoodEntry(
            id: moodID,
            moodValue: details.moodValue ?? selectedLabel.level.rawValue,
            moodKey: details.moodKey ?? selectedLabel.displayName.lowercased(),
            emoji: details.emojiName ?? selectedLabel.displayName,
            labels: details.labels ?? [selectedLabel.displayName],
            contextTags: details.contextTags ?? [],
            note: emptyToNil(details.note),
            journalAnswer: emptyToNil(details.journalAnswer),
            visibility: resolvedVisibility.rawValue,
            media: details.media ?? [],
            weather: details.weather,
            createdAt: details.createdAt ?? now,
            updatedAt: now,
            deviceId: details.deviceId ?? DeviceID.current()
        )

        print("Selected visibility:", resolvedVisibility.rawValue)
        print("Details visibility:", details.visibility?.rawValue ?? "nil")

        try await writeMood(entry, visibility: resolvedVisibility, for: uid, merge: false)
        return moodID
    }

    func updateMoodEntry(
        moodId: String,
        details: AppMoodDetails,
        selectedLabel: HKStateOfMind.Label
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw MoodSaveError.userNotSignedIn
        }

        let existingCreatedAt = try await fetchExistingCreatedAt(uid: uid, moodId: moodId)
        let resolvedVisibility = details.visibility ?? .private

        let entry = FirestoreMoodEntry(
            id: moodId,
            moodValue: details.moodValue ?? selectedLabel.level.rawValue,
            moodKey: details.moodKey ?? selectedLabel.displayName.lowercased(),
            emoji: details.emojiName ?? selectedLabel.displayName,
            labels: details.labels ?? [selectedLabel.displayName],
            contextTags: details.contextTags ?? [],
            note: emptyToNil(details.note),
            journalAnswer: emptyToNil(details.journalAnswer),
            visibility: resolvedVisibility.rawValue,
            media: details.media ?? [],
            weather: details.weather,
            createdAt: details.createdAt ?? existingCreatedAt ?? Date(),
            updatedAt: Date(),
            deviceId: details.deviceId ?? DeviceID.current()
        )

        try await writeMood(entry, visibility: resolvedVisibility, for: uid, merge: true)
    }

    private func writeMood(
        _ entry: FirestoreMoodEntry,
        visibility: MoodPrivacy,
        for uid: String,
        merge: Bool
    ) async throws {
        let moodId = entry.id

        let privateRef = privateMoodRef(uid: uid, moodId: moodId)
        let publicParentRef = db.collection("publicMoodSummaries").document(uid)
        let publicRef = publicParentRef.collection("moods").document(moodId)
        let friendParentRef = db.collection("friendMoodSummaries").document(uid)
        let friendRef = friendParentRef.collection("moods").document(moodId)

        let batch = db.batch()

        let privateData = try Firestore.Encoder().encode(entry)
        if merge {
            batch.setData(privateData, forDocument: privateRef, merge: true)
        } else {
            batch.setData(privateData, forDocument: privateRef)
        }

        let summary = SharedMoodSummary.from(entry, ownerUID: uid)

        switch visibility {
        case .private:
            batch.deleteDocument(publicRef)
            batch.deleteDocument(friendRef)

        case .friends:
            batch.deleteDocument(publicRef)

            batch.setData([
                "ownerUID": uid,
                "updatedAt": Timestamp(date: entry.updatedAt)
            ], forDocument: friendParentRef, merge: true)

            batch.setData(summary.firestoreData(), forDocument: friendRef)

        case .public:
            batch.setData([
                "ownerUID": uid,
                "updatedAt": Timestamp(date: entry.updatedAt)
            ], forDocument: publicParentRef, merge: true)

            batch.setData([
                "ownerUID": uid,
                "updatedAt": Timestamp(date: entry.updatedAt)
            ], forDocument: friendParentRef, merge: true)

            batch.setData(summary.firestoreData(), forDocument: publicRef)
            batch.setData(summary.firestoreData(), forDocument: friendRef)
        }

        print("Writing mood with visibility:", visibility.rawValue)

        do {
            try await batch.commit()
            print("Batch commit succeeded for mood:", moodId)
        } catch {
            print("Batch commit failed for mood \(moodId):", error)
            throw error
        }
    }

    private func fetchExistingCreatedAt(uid: String, moodId: String) async throws -> Date? {
        let snapshot = try await privateMoodRef(uid: uid, moodId: moodId).getDocument()
        guard
            snapshot.exists,
            let data = snapshot.data(),
            let createdAt = data["createdAt"] as? Timestamp
        else {
            return nil
        }

        return createdAt.dateValue()
    }

    private func privateMoodRef(uid: String, moodId: String) -> DocumentReference {
        db.collection("users")
            .document(uid)
            .collection("moods")
            .document(moodId)
    }

    private func emptyToNil(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

struct SharedMoodSummary: Codable {
    let id: String
    let ownerUID: String
    let moodValue: Int
    let moodKey: String
    let emoji: String
    let createdAt: Date
    let updatedAt: Date
    let visibility: String

    static func from(_ entry: FirestoreMoodEntry, ownerUID: String) -> SharedMoodSummary {
        SharedMoodSummary(
            id: entry.id,
            ownerUID: ownerUID,
            moodValue: entry.moodValue,
            moodKey: entry.moodKey,
            emoji: entry.emoji,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
            visibility: entry.visibility
        )
    }

    func firestoreData() -> [String: Any] {
        [
            "id": id,
            "ownerUID": ownerUID,
            "moodValue": moodValue,
            "moodKey": moodKey,
            "emoji": emoji,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "visibility": visibility
        ]
    }
}
