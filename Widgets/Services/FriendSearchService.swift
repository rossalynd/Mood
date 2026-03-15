//
//  FriendSearchService.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct UsernameLookup: Identifiable, Hashable {
    let id: String
    let uid: String
    let username: String
    let displayName: String?
    let emotionSymbol: String?
    var relationshipState: FriendRelationshipState = .none
}

enum FriendSearchService {
    static func searchUsers(prefix raw: String) async throws -> [UsernameLookup] {
        let term = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else { return [] }

        guard let currentUID = Auth.auth().currentUser?.uid else {
            return []
        }

        let snapshot = try await Firestore.firestore()
            .collection("usernames")
            .whereField("isDiscoverable", isEqualTo: true)
            .order(by: "usernameLower")
            .start(at: [term])
            .end(at: [term + "\u{f8ff}"])
            .limit(to: 15)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()

            guard
                let uid = data["uid"] as? String,
                uid != currentUID,
                let username = data["username"] as? String
            else {
                return nil
            }

            return UsernameLookup(
                id: doc.documentID,
                uid: uid,
                username: username,
                displayName: data["displayName"] as? String,
                emotionSymbol: data["emotionSymbol"] as? String
            )
        }
    }
}
