//
//  FriendProfileViewModel.swift
//  Widgets
//
//  Created by Rosie on 3/14/26.
//

import SwiftUI
import FirebaseAuth
@preconcurrency import FirebaseFirestore

@MainActor
final class FriendProfileViewModel: ObservableObject {
    @Published var data: FriendProfileViewData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db: Firestore
    let friendUID: String
    private let previewMode: Bool

    init(
        friendUID: String,
        db: Firestore = Firestore.firestore(),
        previewMode: Bool = false
    ) {
        self.friendUID = friendUID
        self.db = db
        self.previewMode = previewMode
    }

    static func preview() -> FriendProfileViewModel {
        let vm = FriendProfileViewModel(
            friendUID: "preview-friend-uid",
            previewMode: true
        )

        vm.data = FriendProfileViewData(
            uid: "preview-friend-uid",
            username: "rosiefriend",
            displayName: "Luna Rivera",
            emotionSymbol: "sparkles",
            friendsSince: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
            latestMood: SharedMoodSummary(
                id: "mood-preview-1",
                ownerUID: "preview-friend-uid",
                moodValue: 4,
                moodKey: "happy",
                emoji: "Happy",
                createdAt: Date(),
                updatedAt: Date(),
                visibility: "friends"
            ),
            recentMoods: [
                SharedMoodSummary(
                    id: "mood-preview-1",
                    ownerUID: "preview-friend-uid",
                    moodValue: 4,
                    moodKey: "happy",
                    emoji: "Happy",
                    createdAt: Date(),
                    updatedAt: Date(),
                    visibility: "friends"
                ),
                SharedMoodSummary(
                    id: "mood-preview-2",
                    ownerUID: "preview-friend-uid",
                    moodValue: 3,
                    moodKey: "calm",
                    emoji: "Calm",
                    createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                    updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                    visibility: "friends"
                ),
                SharedMoodSummary(
                    id: "mood-preview-3",
                    ownerUID: "preview-friend-uid",
                    moodValue: 2,
                    moodKey: "drained",
                    emoji: "Drained",
                    createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                    updatedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                    visibility: "friends"
                )
            ],
            totalSharedCount: 3,
            streakCount: 12,
            topMoodLabel: "Happy"
        )

        return vm
    }

    func load() async {
        if previewMode {
            return
        }

        guard let currentUID = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be signed in."
            data = nil
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let publicProfileTask = db
                .collection("publicUsers")
                .document(friendUID)
                .getDocument()

            async let friendshipTask = db
                .collection("friends")
                .document(currentUID)
                .collection("list")
                .document(friendUID)
                .getDocument()

            async let moodsTask = db
                .collection("friendMoodSummaries")
                .document(friendUID)
                .collection("moods")
                .order(by: "createdAt", descending: true)
                .limit(to: 30)
                .getDocuments()

            let (publicProfileSnap, friendshipSnap, moodsSnap) = try await (
                publicProfileTask,
                friendshipTask,
                moodsTask
            )

            guard
                let publicData = publicProfileSnap.data(),
                let username = publicData["username"] as? String,
                let displayName = publicData["displayName"] as? String
            else {
                errorMessage = "Unable to load this profile."
                data = nil
                return
            }

            let emotionSymbol = publicData["emotionSymbol"] as? String
            let streakCount = publicData["streakCount"] as? Int ?? 0

            let friendsSince: Date? = {
                guard
                    let friendData = friendshipSnap.data(),
                    let createdAt = friendData["createdAt"] as? Timestamp
                else {
                    return nil
                }
                return createdAt.dateValue()
            }()

            let moods: [SharedMoodSummary] = try moodsSnap.documents.compactMap { doc in
                try doc.data(as: SharedMoodSummary.self)
            }

            let latestMood = moods.first
            let totalSharedCount = moods.count
            let topMoodLabel = Self.topMood(from: moods)

            data = FriendProfileViewData(
                uid: friendUID,
                username: username,
                displayName: displayName,
                emotionSymbol: emotionSymbol,
                friendsSince: friendsSince,
                latestMood: latestMood,
                recentMoods: moods,
                totalSharedCount: totalSharedCount,
                streakCount: streakCount,
                topMoodLabel: topMoodLabel
            )
        } catch {
            errorMessage = error.localizedDescription
            data = nil
        }
    }

    func removeFriend() async throws {
        if previewMode { return }
        try await FriendFunctionService.removeFriend(uid: friendUID)
    }

    private static func topMood(from moods: [SharedMoodSummary]) -> String? {
        let counts = Dictionary(grouping: moods, by: \.moodKey)
            .mapValues(\.count)

        return counts.max { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key < rhs.key
            }
            return lhs.value < rhs.value
        }?.key.capitalized
    }
}
