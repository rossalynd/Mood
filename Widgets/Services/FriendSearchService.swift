//
//  FriendSearchService.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//


import Foundation
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

        let db = Firestore.firestore()

        let usernameSnapshot = try await db
            .collection("usernames")
            .order(by: "usernameLower")
            .start(at: [term])
            .end(at: [term + "\u{f8ff}"])
            .limit(to: 15)
            .getDocuments()

        let usernameHits: [(id: String, uid: String, username: String)] = usernameSnapshot.documents.compactMap { doc in
            let data = doc.data()

            guard
                let uid = data["uid"] as? String,
                let username = data["username"] as? String
            else {
                return nil
            }

            return (id: doc.documentID, uid: uid, username: username)
        }

        guard !usernameHits.isEmpty else { return [] }

        var results: [UsernameLookup] = []
        results.reserveCapacity(usernameHits.count)

        for hit in usernameHits {
            let publicUserSnapshot = try await db
                .collection("publicUsers")
                .document(hit.uid)
                .getDocument()

            guard
                let publicData = publicUserSnapshot.data(),
                (publicData["isDiscoverable"] as? Bool ?? true)
            else {
                continue
            }

            results.append(
                UsernameLookup(
                    id: hit.id,
                    uid: hit.uid,
                    username: publicData["username"] as? String ?? hit.username,
                    displayName: publicData["displayName"] as? String,
                    emotionSymbol: publicData["emotionSymbol"] as? String
                )
            )
        }

        return results
    }
}
