//
//  FriendSearchViewModel.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//


import Foundation

//
//  FriendSearchViewModel.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//

import Foundation

@MainActor
final class FriendSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [UsernameLookup] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            results = try await FriendSearchService.searchUsers(prefix: trimmed)
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }

        isLoading = false
    }
}
