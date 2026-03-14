//
//  FriendsListView.swift
//  Widgets
//
//  Created by Rosie on 3/14/26.
//


import SwiftUI

struct FriendsListView: View {
    @StateObject private var viewModel = FriendsListViewModel()

    var body: some View {
        ScrollView {
            ForEach(viewModel.friends) { friend in
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.displayName)
                            .font(.headline)

                        Text("@\(friend.username)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Remove", role: .destructive) {
                        Task { await viewModel.remove(friend: friend) }
                    }
                }
            }

            if viewModel.friends.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No Friends Yet",
                    systemImage: "person.2",
                    description: Text("Once you add friends, they'll appear here.")
                )
            }
        }
        .navigationTitle("Friends")
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }
}
