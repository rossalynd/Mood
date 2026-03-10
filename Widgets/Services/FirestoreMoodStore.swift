//
//  FirestoreMoodStore.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore


@MainActor
final class FirestoreMoodStore: ObservableObject {
    private let db = Firestore.firestore()

    func saveMood(_ entry: FirestoreMoodEntry, userID: String) async throws {
        guard let id = entry.id else {
            throw NSError(domain: "FirestoreMoodStore", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Missing mood id."
            ])
        }

        try db
            .collection("users")
            .document(userID)
            .collection("moods")
            .document(id)
            .setData(from: entry, merge: true)
    }

    func fetchMoods(userID: String) async throws -> [FirestoreMoodEntry] {
        let snapshot = try await db
            .collection("users")
            .document(userID)
            .collection("moods")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try doc.data(as: FirestoreMoodEntry.self)
        }
    }
}
