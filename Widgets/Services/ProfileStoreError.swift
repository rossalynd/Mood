//
//  ProfileStoreError.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//

import Foundation
import FirebaseAuth
@preconcurrency import FirebaseFirestore

enum ProfileStoreError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "No signed-in user was found."
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

        let docRef = db.collection("users").document(user.uid)
        let now = Date()

        let existingSnapshot = try await docRef.getDocument()
        let existingData = existingSnapshot.data()
        let existingProfile = existingData.flatMap(UserProfile.init(from:))

        let profile = UserProfile(
            uid: user.uid,
            email: user.email,
            username: data.username,
            displayName: data.displayName,
            emotionSymbol: data.emotionSymbol,
            moodGoalPerWeek: data.moodGoalPerWeek,
            reminderTimes: sanitizeReminderDates(data.reminderTimes),
            hasCompletedSetup: true,
            createdAt: existingProfile?.createdAt ?? now,
            updatedAt: now
        )

        try await docRef.setData(profile.firestoreData(), merge: true)
        
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
            updates["reminderTimes"] = reminderTimes.map { Timestamp(date: $0) }
        }

        try await db.collection("users").document(uid).setData(updates, merge: true)
        await loadCurrentUserProfile()
    }
    private func sanitizeReminderDates(_ dates: [Date]) -> [Date] {
        // Firestore Timestamp supports roughly years 0001...9999, but we’ll keep it practical.
        // This also strips any old “year 1” values created by DateComponents.
        let min = Date(timeIntervalSince1970: 0) // 1970-01-01
        let max = Date(timeIntervalSince1970: 253402300799) // 9999-12-31
        return dates.filter { $0 >= min && $0 <= max }.sorted()
    }
}
