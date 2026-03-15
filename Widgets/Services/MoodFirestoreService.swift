//
//  MoodFirestoreService.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//

import Foundation
import HealthKit
import UIKit
import SwiftUI
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore

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

actor MoodFirestoreService {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

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

        try await writeMood(entry, visibility: resolvedVisibility, for: uid, merge: false)
        try await updateUserMoodStats(uid: uid, moodDate: entry.createdAt)

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
        let db = self.db

        let moodId = entry.id
        let privateRef = db.collection("users")
            .document(uid)
            .collection("moods")
            .document(moodId)

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

        try await batch.commit()
    }
    
    func deleteMoodEntry(moodId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw MoodSaveError.userNotSignedIn
        }

        let privateRef = db.collection("users")
            .document(uid)
            .collection("moods")
            .document(moodId)

        let publicRef = db.collection("publicMoodSummaries")
            .document(uid)
            .collection("moods")
            .document(moodId)

        let friendRef = db.collection("friendMoodSummaries")
            .document(uid)
            .collection("moods")
            .document(moodId)

        let batch = db.batch()
        batch.deleteDocument(privateRef)
        batch.deleteDocument(publicRef)
        batch.deleteDocument(friendRef)

        try await batch.commit()
    }

    private func updateUserMoodStats(uid: String, moodDate: Date) async throws {
        let db = self.db
        let privateUserRef = db.collection("users").document(uid)
        let publicUserRef = db.collection("publicUsers").document(uid)
        let calendar = Calendar.current
        let now = Date()

        _ = try await db.runTransaction { transaction, errorPointer in
            let userSnapshot: DocumentSnapshot

            do {
                userSnapshot = try transaction.getDocument(privateUserRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            let data = userSnapshot.data() ?? [:]
            let currentStreak = data["streakCount"] as? Int ?? 0
            let totalMoodCount = data["totalMoodCount"] as? Int ?? 0

            let lastMoodDate: Date? = {
                guard let ts = data["lastMoodDate"] as? Timestamp else { return nil }
                return ts.dateValue()
            }()

            let nextStreak: Int
            if let lastMoodDate {
                if calendar.isDate(lastMoodDate, inSameDayAs: moodDate) {
                    nextStreak = max(currentStreak, 1)
                } else if
                    let yesterday = calendar.date(byAdding: .day, value: -1, to: moodDate),
                    calendar.isDate(lastMoodDate, inSameDayAs: yesterday) {
                    nextStreak = max(currentStreak, 0) + 1
                } else {
                    nextStreak = 1
                }
            } else {
                nextStreak = 1
            }

            transaction.setData([
                "lastMoodDate": Timestamp(date: moodDate),
                "streakCount": nextStreak,
                "totalMoodCount": totalMoodCount + 1,
                "updatedAt": Timestamp(date: now)
            ], forDocument: privateUserRef, merge: true)

            transaction.setData([
                "streakCount": nextStreak,
                "updatedAt": Timestamp(date: now)
            ], forDocument: publicUserRef, merge: true)

            return nil
        }
    }

    private func fetchExistingCreatedAt(uid: String, moodId: String) async throws -> Date? {
        let snapshot = try await db.collection("users")
            .document(uid)
            .collection("moods")
            .document(moodId)
            .getDocument()

        guard
            snapshot.exists,
            let data = snapshot.data(),
            let createdAt = data["createdAt"] as? Timestamp
        else {
            return nil
        }

        return createdAt.dateValue()
    }
    
    func fetchRecentMoods(limit: Int = 20) async throws -> [FirestoreMoodEntry] {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw MoodSaveError.userNotSignedIn
        }

        let snapshot = try await db.collection("users")
            .document(uid)
            .collection("moods")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.map { document in
            var entry = try document.data(as: FirestoreMoodEntry.self)
            entry.id = document.documentID
            return entry
        }
    }
    
    
    private func emptyToNil(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

struct SharedMoodSummary: Codable, Identifiable {
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
extension SharedMoodSummary {
    var moodLevel: MoodLevel {
        MoodLevel(rawValue: moodValue) ?? .neutral
    }

    var moodColor: Color {
        moodLevel.color
    }
}
