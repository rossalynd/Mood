//
//  ProfileStore.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//


import Foundation
@preconcurrency import FirebaseFirestore
import FirebaseAuth

enum ProfileStoreError: LocalizedError {
    case notSignedIn
    case invalidUsername
    case usernameTaken

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "User is not signed in."
        case .invalidUsername:
            return "Username must be 3–20 characters and use only lowercase letters, numbers, or underscores."
        case .usernameTaken:
            return "That username is already taken."
        }
    }
}

@MainActor
final class ProfileStore: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private var uid: String? {
        Auth.auth().currentUser?.uid
    }

    deinit {
        listener?.remove()
    }

    func startListening(uid: String) {
        stopListening()

        isLoading = true
        errorMessage = nil

        listener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                Task { @MainActor in
                    self.isLoading = false

                    if let error {
                        self.errorMessage = error.localizedDescription
                        self.profile = nil
                        return
                    }

                    guard let snapshot, snapshot.exists,
                          let data = snapshot.data() else {
                        self.profile = nil
                        return
                    }

                    self.profile = UserProfile(from: data)
                    self.errorMessage = nil
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        profile = nil
        isLoading = false
        errorMessage = nil
    }

    func loadCurrentUserProfile() async {
        guard let uid else {
            errorMessage = "User is not signed in."
            profile = nil
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let doc = try await db.collection("users").document(uid).getDocument()

            guard doc.exists, let data = doc.data() else {
                profile = nil
                return
            }

            profile = UserProfile(from: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveAccountSetup(_ data: AccountSetupData) async throws {
        guard let user = Auth.auth().currentUser else {
            throw ProfileStoreError.notSignedIn
        }

        let cleanedUsername = data.username
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let usernameLower = cleanedUsername.lowercased()

        guard Self.isValidUsername(usernameLower) else {
            throw ProfileStoreError.invalidUsername
        }

        let userRef = db.collection("users").document(user.uid)
        let usernameRef = db.collection("usernames").document(usernameLower)
        let now = Date()

        let existingSnapshot = try await userRef.getDocument()
        let existingData = existingSnapshot.data()
        let existingProfile = existingData.flatMap(UserProfile.init(from:))

        if let existingProfile,
           existingProfile.usernameLower != usernameLower {
            let oldUsernameRef = db.collection("usernames").document(existingProfile.usernameLower)

            let oldUsernameSnap = try await oldUsernameRef.getDocument()
            if let oldData = oldUsernameSnap.data(),
               let oldUID = oldData["uid"] as? String,
               oldUID == user.uid {
                try await oldUsernameRef.delete()
            }
        }

        let usernameSnapshot = try await usernameRef.getDocument()
        if let usernameData = usernameSnapshot.data(),
           let existingUID = usernameData["uid"] as? String,
           existingUID != user.uid {
            throw ProfileStoreError.usernameTaken
        }

        let profile = UserProfile(
            uid: user.uid,
            email: user.email,
            username: cleanedUsername,
            usernameLower: usernameLower,
            displayName: data.displayName,
            emotionSymbol: data.emotionSymbol,
            moodGoalPerWeek: data.moodGoalPerWeek,
            reminderTimes: sanitizeReminderDates(data.reminderTimes),
            hasCompletedSetup: true,
            createdAt: existingProfile?.createdAt ?? now,
            updatedAt: now
        )

        let batch = db.batch()

        batch.setData(profile.firestoreData(), forDocument: userRef, merge: true)
        batch.setData([
            "uid": user.uid,
            "username": cleanedUsername,
            "usernameLower": usernameLower,
            "updatedAt": Timestamp(date: now),
            "createdAt": usernameSnapshot.data()?["createdAt"] ?? Timestamp(date: now)
        ], forDocument: usernameRef, merge: true)

        try await batch.commit()

        self.profile = profile
    }

    func updateProfileFields(
        displayName: String? = nil,
        emotionSymbol: String? = nil,
        moodGoalPerWeek: Int? = nil,
        reminderTimes: [Date]? = nil
    ) async throws {
        guard let uid else {
            throw ProfileStoreError.notSignedIn
        }

        var updates: [String: Any] = [
            "updatedAt": Timestamp(date: Date())
        ]

        if let displayName {
            updates["displayName"] = displayName
        }

        if let emotionSymbol {
            updates["emotionSymbol"] = emotionSymbol
        }

        if let moodGoalPerWeek {
            updates["moodGoalPerWeek"] = moodGoalPerWeek
        }

        if let reminderTimes {
            updates["reminderTimes"] = sanitizeReminderDates(reminderTimes).map { Timestamp(date: $0) }
        }

        try await db.collection("users").document(uid).setData(updates, merge: true)
        await loadCurrentUserProfile()
    }

    private func sanitizeReminderDates(_ dates: [Date]) -> [Date] {
        let min = Date(timeIntervalSince1970: 0)
        let max = Date(timeIntervalSince1970: 253402300799)
        return dates.filter { $0 >= min && $0 <= max }.sorted()
    }

    private static func isValidUsername(_ name: String) -> Bool {
        guard name.count >= 3, name.count <= 20 else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
        return name.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
