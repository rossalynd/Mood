//
//  FriendsListViewModel.swift
//  Widgets
//
//  Created by Rosie on 3/14/26.
//

import Foundation
import FirebaseAuth
@preconcurrency import FirebaseFirestore

@MainActor
final class FriendsListViewModel: ObservableObject {
    @Published var friends: [FriendSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    private static func fetchFriendSummary(
        db: Firestore,
        friendUID: String
    ) async throws -> FriendSummary? {
        let profile = try await db
            .collection("publicUsers")
            .document(friendUID)
            .getDocument()

        guard
            let data = profile.data(),
            let username = data["username"] as? String,
            let displayName = data["displayName"] as? String
        else {
            return nil
        }

        return FriendSummary(
            id: friendUID,
            uid: friendUID,
            username: username,
            displayName: displayName
        )
    }

    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be signed in."
            friends = []
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let friendDocs = try await db
                .collection("friends")
                .document(uid)
                .collection("list")
                .getDocuments()

            let items = try await withThrowingTaskGroup(of: FriendSummary?.self) { group in
                for doc in friendDocs.documents {
                    let friendUID = doc.documentID
                    let dbRef = db

                    group.addTask(priority: nil) { @Sendable in
                        try await FriendsListViewModel.fetchFriendSummary(
                            db: dbRef,
                            friendUID: friendUID
                        )
                    }
                }

                var results: [FriendSummary] = []
                for try await item in group {
                    if let item {
                        results.append(item)
                    }
                }
                return results
            }

            friends = items.sorted {
                $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending
            }
        } catch {
            friends = []
            errorMessage = error.localizedDescription
        }
    }

    func remove(friend: FriendSummary) async {
        do {
            try await FriendFunctionService.removeFriend(uid: friend.uid)
            friends.removeAll { $0.uid == friend.uid }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
