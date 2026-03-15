//
//  ProfileStore.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//

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
    case profileMissing

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "User is not signed in."
        case .invalidUsername:
            return "Username must be 3–20 characters and use only lowercase letters, numbers, or underscores."
        case .usernameTaken:
            return "That username is already taken."
        case .profileMissing:
            return "Unable to load the current profile."
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

    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Document References

    private func privateUserRef(_ uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }

    private func publicUserRef(_ uid: String) -> DocumentReference {
        db.collection("publicUsers").document(uid)
    }

    private func usernameRef(_ usernameLower: String) -> DocumentReference {
        db.collection("usernames").document(usernameLower)
    }

    // MARK: - Listening

    func startListening(uid: String) {
        stopListening()

        isLoading = true
        errorMessage = nil

        listener = privateUserRef(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            Task { @MainActor in
                self.isLoading = false

                if let error {
                    self.errorMessage = error.localizedDescription
                    self.profile = nil
                    return
                }

                guard let snapshot, snapshot.exists, let data = snapshot.data() else {
                    self.profile = nil
                    self.errorMessage = nil
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

    // MARK: - Loading

    func loadCurrentUserProfile() async {
        guard let uid = currentUID else {
            profile = nil
            errorMessage = ProfileStoreError.notSignedIn.errorDescription
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let snapshot = try await privateUserRef(uid).getDocument()

            guard snapshot.exists, let data = snapshot.data() else {
                profile = nil
                return
            }

            profile = UserProfile(from: data)
        } catch {
            profile = nil
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Account Setup / Initial Save

    func saveAccountSetup(_ data: AccountSetupData) async throws {
        guard let user = Auth.auth().currentUser else {
            throw ProfileStoreError.notSignedIn
        }

        let cleanedUsername = data.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedDisplayName = data.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let usernameLower = cleanedUsername.lowercased()
        let now = Date()

        guard Self.isValidUsername(usernameLower) else {
            throw ProfileStoreError.invalidUsername
        }

        let privateRef = privateUserRef(user.uid)
        let publicRef = publicUserRef(user.uid)
        let newUsernameRef = usernameRef(usernameLower)

        let existingSnapshot = try await privateRef.getDocument()
        let existingProfile = existingSnapshot.data().flatMap(UserProfile.init(from:))

        if let existingProfile,
           existingProfile.usernameLower != usernameLower {
            let oldUsernameRef = usernameRef(existingProfile.usernameLower)
            let oldUsernameSnapshot = try await oldUsernameRef.getDocument()

            if let oldData = oldUsernameSnapshot.data(),
               let oldUID = oldData["uid"] as? String,
               oldUID == user.uid {
                try await oldUsernameRef.delete()
            }
        }

        let usernameSnapshot = try await newUsernameRef.getDocument()
        if let usernameData = usernameSnapshot.data(),
           let existingUID = usernameData["uid"] as? String,
           existingUID != user.uid {
            throw ProfileStoreError.usernameTaken
        }

        let createdAt = existingProfile?.createdAt ?? now
        let allowsFriendRequests = existingProfile?.allowsFriendRequests ?? true
        let isDiscoverable = existingProfile?.isDiscoverable ?? true

        let privateProfile = UserProfile(
            uid: user.uid,
            email: user.email,
            username: cleanedUsername,
            usernameLower: usernameLower,
            displayName: cleanedDisplayName,
            emotionSymbol: data.emotionSymbol,
            moodGoalPerWeek: data.moodGoalPerWeek,
            reminderTimes: sanitizeReminderDates(data.reminderTimes),
            hasCompletedSetup: true,
            createdAt: createdAt,
            updatedAt: now,
            allowsFriendRequests: allowsFriendRequests,
            isDiscoverable: isDiscoverable,
            streakCount: existingProfile?.streakCount ?? 0,
            totalMoodCount: existingProfile?.totalMoodCount ?? 0,
            lastMoodDate: existingProfile?.lastMoodDate
        )

        let sharedProfile = PublicUserProfile(
            uid: user.uid,
            username: cleanedUsername,
            usernameLower: usernameLower,
            displayName: cleanedDisplayName,
            emotionSymbol: data.emotionSymbol,
            createdAt: createdAt,
            updatedAt: now,
            isDiscoverable: isDiscoverable,
            streakCount: existingProfile?.streakCount ?? 0
        )

        let batch = db.batch()

        batch.setData(privateProfile.firestoreData(), forDocument: privateRef, merge: true)
        batch.setData(sharedProfile.firestoreData(), forDocument: publicRef, merge: true)
        batch.setData([
            "uid": user.uid,
            "username": cleanedUsername,
            "usernameLower": usernameLower,
            "createdAt": usernameSnapshot.data()?["createdAt"] ?? Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ], forDocument: newUsernameRef, merge: true)

        try await batch.commit()
        profile = privateProfile
        errorMessage = nil
    }

    // MARK: - Updates

    func updateProfileFields(
        displayName: String? = nil,
        emotionSymbol: String? = nil,
        moodGoalPerWeek: Int? = nil,
        reminderTimes: [Date]? = nil,
        allowsFriendRequests: Bool? = nil,
        isDiscoverable: Bool? = nil
    ) async throws {
        guard currentUID != nil else {
            throw ProfileStoreError.notSignedIn
        }

        let currentProfile: UserProfile
        if let profile {
            currentProfile = profile
        } else {
            await loadCurrentUserProfile()
            guard let loadedProfile = profile else {
                throw ProfileStoreError.profileMissing
            }
            currentProfile = loadedProfile
        }

        try await updateUsingCurrentProfile(
            currentProfile,
            displayName: displayName,
            emotionSymbol: emotionSymbol,
            moodGoalPerWeek: moodGoalPerWeek,
            reminderTimes: reminderTimes,
            allowsFriendRequests: allowsFriendRequests,
            isDiscoverable: isDiscoverable
        )
    }

    private func updateUsingCurrentProfile(
        _ current: UserProfile,
        displayName: String?,
        emotionSymbol: String?,
        moodGoalPerWeek: Int?,
        reminderTimes: [Date]?,
        allowsFriendRequests: Bool?,
        isDiscoverable: Bool?
    ) async throws {
        let now = Date()

        let nextDisplayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? current.displayName
        let nextEmotionSymbol = emotionSymbol ?? current.emotionSymbol
        let nextMoodGoalPerWeek = moodGoalPerWeek ?? current.moodGoalPerWeek
        let nextReminderTimes = reminderTimes.map(sanitizeReminderDates) ?? current.reminderTimes
        let nextAllowsFriendRequests = allowsFriendRequests ?? current.allowsFriendRequests
        let nextIsDiscoverable = isDiscoverable ?? current.isDiscoverable

        let updatedPrivateProfile = UserProfile(
            uid: current.uid,
            email: current.email,
            username: current.username,
            usernameLower: current.usernameLower,
            displayName: nextDisplayName,
            emotionSymbol: nextEmotionSymbol,
            moodGoalPerWeek: nextMoodGoalPerWeek,
            reminderTimes: nextReminderTimes,
            hasCompletedSetup: current.hasCompletedSetup,
            createdAt: current.createdAt,
            updatedAt: now,
            allowsFriendRequests: nextAllowsFriendRequests,
            isDiscoverable: nextIsDiscoverable,
            streakCount: current.streakCount,
            totalMoodCount: current.totalMoodCount,
            lastMoodDate: current.lastMoodDate
        )

        let updatedPublicProfile = PublicUserProfile(
            uid: current.uid,
            username: current.username,
            usernameLower: current.usernameLower,
            displayName: nextDisplayName,
            emotionSymbol: nextEmotionSymbol,
            createdAt: current.createdAt,
            updatedAt: now,
            isDiscoverable: nextIsDiscoverable,
            streakCount: current.streakCount
        )

        let batch = db.batch()
        batch.setData(updatedPrivateProfile.firestoreData(), forDocument: privateUserRef(current.uid), merge: true)
        batch.setData(updatedPublicProfile.firestoreData(), forDocument: publicUserRef(current.uid), merge: true)

        try await batch.commit()
        profile = updatedPrivateProfile
        errorMessage = nil
    }

    // MARK: - Helpers

    private func sanitizeReminderDates(_ dates: [Date]) -> [Date] {
        let min = Date(timeIntervalSince1970: 0)
        let max = Date(timeIntervalSince1970: 253402300799)
        return dates
            .filter { $0 >= min && $0 <= max }
            .sorted()
    }

    private static func isValidUsername(_ name: String) -> Bool {
        guard name.count >= 3, name.count <= 20 else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
        return name.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
