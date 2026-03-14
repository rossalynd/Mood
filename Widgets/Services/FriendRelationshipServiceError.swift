//
//  FriendRelationshipServiceError.swift
//  Widgets
//
//  Created by Rosie on 3/14/26.
//


import Foundation
import FirebaseAuth
@preconcurrency import FirebaseFirestore

enum FriendRelationshipServiceError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You must be signed in."
        }
    }
}

enum FriendRelationshipService {
    static func relationshipState(
        currentUID: String,
        otherUID: String
    ) async throws -> FriendRelationshipState {
        let db = Firestore.firestore()

        async let friendDoc = db.collection("friends")
            .document(currentUID)
            .collection("list")
            .document(otherUID)
            .getDocument()

        async let outgoingRequest = db.collection("friendRequests")
            .document(requestID(fromUID: currentUID, toUID: otherUID))
            .getDocument()

        async let incomingRequest = db.collection("friendRequests")
            .document(requestID(fromUID: otherUID, toUID: currentUID))
            .getDocument()

        let (friendSnapshot, outgoingSnapshot, incomingSnapshot) = try await (
            friendDoc,
            outgoingRequest,
            incomingRequest
        )

        if friendSnapshot.exists {
            return .friends
        }

        if
            outgoingSnapshot.exists,
            let data = outgoingSnapshot.data(),
            data["status"] as? String == "pending"
        {
            return .pendingOutgoing
        }

        if
            incomingSnapshot.exists,
            let data = incomingSnapshot.data(),
            data["status"] as? String == "pending"
        {
            return .pendingIncoming
        }

        return .none
    }

    static func relationshipState(with otherUID: String) async throws -> FriendRelationshipState {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            throw FriendRelationshipServiceError.notSignedIn
        }

        return try await relationshipState(
            currentUID: currentUID,
            otherUID: otherUID
        )
    }

    private static func requestID(fromUID: String, toUID: String) -> String {
        "\(fromUID)_\(toUID)"
    }
}
