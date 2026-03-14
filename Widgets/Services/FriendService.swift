//
//  FriendService.swift
//  Widgets
//
//  Created by Rosie on 3/14/26.
//

//
//  FriendService.swift
//  Widgets
//
//  Created by Rosie on 3/14/26.
//

import Foundation
import FirebaseAuth
@preconcurrency import FirebaseFirestore

enum FriendServiceError: LocalizedError {
    case notSignedIn
    case cannotFriendYourself
    case alreadyFriends
    case requestAlreadySent
    case requestAlreadyReceived
    case invalidRequest
    case missingData

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You must be signed in."
        case .cannotFriendYourself:
            return "You can't add yourself."
        case .alreadyFriends:
            return "You're already friends."
        case .requestAlreadySent:
            return "Friend request already sent."
        case .requestAlreadyReceived:
            return "This user already sent you a request."
        case .invalidRequest:
            return "This friend request is invalid."
        case .missingData:
            return "Required data is missing."
        }
    }
}

enum FriendRelationshipState: Equatable, Hashable {
    case none
    case pendingOutgoing
    case pendingIncoming
    case friends
    case me
}



import Foundation
import FirebaseFunctions


enum FriendFunctionService {
    private static let functions = Functions.functions(region: "us-central1")
    // change region if you deployed elsewhere

    static func sendFriendRequest(to uid: String) async throws {
        let result = try await functions.httpsCallable("sendFriendRequest").call([
            "toUID": uid
        ])
        print("✅ sendFriendRequest result:", result.data)
    }

    static func cancelFriendRequest(to uid: String) async throws {
        let result = try await functions.httpsCallable("cancelFriendRequest").call([
            "toUID": uid
        ])
        print("✅ cancelFriendRequest result:", result.data)
    }

    static func acceptFriendRequest(from uid: String) async throws {
        let result = try await functions.httpsCallable("acceptFriendRequest").call([
            "fromUID": uid
        ])
        print("✅ acceptFriendRequest result:", result.data)
    }

    static func declineFriendRequest(from uid: String) async throws {
        let result = try await functions.httpsCallable("declineFriendRequest").call([
            "fromUID": uid
        ])
        print("✅ declineFriendRequest result:", result.data)
    }

    static func removeFriend(uid: String) async throws {
        let result = try await functions.httpsCallable("removeFriend").call([
            "otherUID": uid
        ])
        print("✅ removeFriend result:", result.data)
    }
}
