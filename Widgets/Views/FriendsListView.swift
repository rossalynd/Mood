//
//
//  FriendsListView.swift
//  Widgets
//
//  Created by Rosie on 3/14/26.
//

import SwiftUI

struct FriendsListView: View {
    @Binding var path: NavigationPath
    @StateObject private var viewModel = FriendsListViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.friends) { friend in
                    Button {
                        path.append(HomeRoute.friendProfile(uid: friend.uid))
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: friend.emotionSymbol)
                                .font(.title3)
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text("@\(friend.username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Remove", role: .destructive) {
                                Task { await viewModel.remove(friend: friend) }
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding()
                        .background(
                            .thinMaterial,
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.friends.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Friends Yet",
                        systemImage: "person.2",
                        description: Text("Once you add friends, they'll appear here.")
                    )
                    .padding(.top, 40)
                }
            }
            .padding()
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
