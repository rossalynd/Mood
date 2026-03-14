//
//  FriendSearchViewModel.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//


import Foundation
import FirebaseAuth

@MainActor
final class FriendSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [UsernameLookup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            var users = try await FriendSearchService.searchUsers(prefix: trimmed)

            if let currentUID {
                for index in users.indices {
                    let state = try await FriendRelationshipService.relationshipState(
                        currentUID: currentUID,
                        otherUID: users[index].uid
                    )
                    users[index].relationshipState = state
                }
            }

            results = users
        } catch {
            results = []
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func sendRequest(to user: UsernameLookup) async {
        errorMessage = nil

        do {
            try await FriendFunctionService.sendFriendRequest(to: user.uid)
            try await refreshRelationshipState(for: user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelRequest(to user: UsernameLookup) async {
        errorMessage = nil

        do {
            try await FriendFunctionService.cancelFriendRequest(to: user.uid)
            try await refreshRelationshipState(for: user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptRequest(from user: UsernameLookup) async {
        errorMessage = nil

        do {
            try await FriendFunctionService.acceptFriendRequest(from: user.uid)
            try await refreshRelationshipState(for: user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func declineRequest(from user: UsernameLookup) async {
        errorMessage = nil

        do {
            try await FriendFunctionService.declineFriendRequest(from: user.uid)
            try await refreshRelationshipState(for: user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshRelationshipState(for otherUID: String) async throws {
        guard let currentUID else { return }
        let state = try await FriendRelationshipService.relationshipState(
            currentUID: currentUID,
            otherUID: otherUID
        )
        updateRelationshipState(for: otherUID, to: state)
    }

    private func updateRelationshipState(for uid: String, to newState: FriendRelationshipState) {
        guard let index = results.firstIndex(where: { $0.uid == uid }) else { return }

        var updated = results
        updated[index].relationshipState = newState
        results = updated
    }
}
