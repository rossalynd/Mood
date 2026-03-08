//
//  ProfileStore.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class ProfileStore1: ObservableObject {
    @Published private(set) var username: String? = nil
    @Published private(set) var isLoading = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening(uid: String) {
        listener?.remove()
        isLoading = true

        listener = db.collection("users").document(uid).addSnapshotListener { [weak self] snap, _ in
            guard let self else { return }
            Task { @MainActor in
                self.isLoading = false
                self.username = snap?.data()?["username"] as? String
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        username = nil
    }
}
