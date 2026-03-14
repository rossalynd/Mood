//
//  FriendRequest.swift
//  Widgets
//
//  Created by Rosie on 3/14/26.
//


import Foundation
@preconcurrency import FirebaseFirestore
import FirebaseAuth

struct PendingFriendRequest: Identifiable, Hashable {
    let id: String
    let fromUID: String
    let toUID: String
    let status: String
    let username: String?
    let displayName: String?
    let emotionSymbol: String?
    let createdAt: Date
}

@MainActor
final class PendingRequestsViewModel: ObservableObject {
    @Published var incoming: [PendingFriendRequest] = []
    @Published var outgoing: [PendingFriendRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be signed in."
            incoming = []
            outgoing = []
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let incomingSnapshot = db.collection("friendRequests")
                .whereField("toUID", isEqualTo: uid)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()

            async let outgoingSnapshot = db.collection("friendRequests")
                .whereField("fromUID", isEqualTo: uid)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()

            let (incomingDocs, outgoingDocs) = try await (incomingSnapshot, outgoingSnapshot)

            let incomingRequests = try await hydrateRequests(
                documents: incomingDocs.documents,
                lookupUIDKey: "fromUID"
            )

            let outgoingRequests = try await hydrateRequests(
                documents: outgoingDocs.documents,
                lookupUIDKey: "toUID"
            )

            incoming = incomingRequests.sorted { $0.createdAt > $1.createdAt }
            outgoing = outgoingRequests.sorted { $0.createdAt > $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
            incoming = []
            outgoing = []
        }
    }

    func accept(_ request: PendingFriendRequest) async {
        do {
            try await FriendFunctionService.acceptFriendRequest(from: request.fromUID)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func decline(_ request: PendingFriendRequest) async {
        do {
            try await FriendFunctionService.declineFriendRequest(from: request.fromUID)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancel(_ request: PendingFriendRequest) async {
        do {
            try await FriendFunctionService.cancelFriendRequest(to: request.toUID)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func hydrateRequests(
        documents: [QueryDocumentSnapshot],
        lookupUIDKey: String
    ) async throws -> [PendingFriendRequest] {
        try await withThrowingTaskGroup(of: PendingFriendRequest?.self) { group in
            for doc in documents {
                group.addTask { [db] in
                    let data = doc.data()

                    guard
                        let fromUID = data["fromUID"] as? String,
                        let toUID = data["toUID"] as? String,
                        let status = data["status"] as? String,
                        let createdAt = data["createdAt"] as? Timestamp
                    else {
                        return nil
                    }

                    let lookupUID = (data[lookupUIDKey] as? String) ?? ""
                    let publicUserSnap = try await db
                        .collection("publicUsers")
                        .document(lookupUID)
                        .getDocument()

                    let publicData = publicUserSnap.data()

                    return PendingFriendRequest(
                        id: doc.documentID,
                        fromUID: fromUID,
                        toUID: toUID,
                        status: status,
                        username: publicData?["username"] as? String,
                        displayName: publicData?["displayName"] as? String,
                        emotionSymbol: publicData?["emotionSymbol"] as? String,
                        createdAt: createdAt.dateValue()
                    )
                }
            }

            var results: [PendingFriendRequest] = []
            for try await request in group {
                if let request {
                    results.append(request)
                }
            }
            return results
        }
    }
}
