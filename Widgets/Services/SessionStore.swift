import Foundation
import FirebaseAuth

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var user: User?

    private nonisolated(unsafe) var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { _, user in
            Task { @MainActor in
                self.user = user
            }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }
}