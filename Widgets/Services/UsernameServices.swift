//
//  UsernameServices.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//

import FirebaseAuth
import FirebaseFirestore

enum UsernameService {
    static func claimUsername(_ raw: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw UsernameError.notSignedIn
        }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let usernameLower = trimmed.lowercased()

        guard isValid(usernameLower) else {
            throw UsernameError.invalid
        }

        let db = Firestore.firestore()
        let usernameRef = db.collection("usernames").document(usernameLower)
        let userRef = db.collection("users").document(uid)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.runTransaction({ transaction, errorPointer in
                do {
                    let existing = try transaction.getDocument(usernameRef)

                    if existing.exists {
                        errorPointer?.pointee = UsernameError.taken as NSError
                        return nil
                    }

                    transaction.setData([
                        "uid": uid,
                        "createdAt": FieldValue.serverTimestamp()
                    ], forDocument: usernameRef)

                    transaction.setData([
                        "username": trimmed,
                        "usernameLower": usernameLower,
                        "createdAt": FieldValue.serverTimestamp()
                    ], forDocument: userRef, merge: true)

                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            })
        }
    }

    private static func isValid(_ name: String) -> Bool {
        guard name.count >= 3, name.count <= 20 else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
        return name.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
enum UsernameError: LocalizedError {
    case notSignedIn
    case invalid
    case taken

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "User is not signed in."
        case .invalid: return "Username is invalid."
        case .taken: return "Username is already taken."
        }
    }
}
