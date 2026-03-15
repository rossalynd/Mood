//
//  FriendSearchView.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//

//
//  FriendSearchView.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//

import SwiftUI

struct FriendSearchView: View {
    @StateObject private var viewModel = FriendSearchViewModel()
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 16) {
            TextField("Search by username", text: $viewModel.query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .onChange(of: viewModel.query) { _, _ in
                    searchTask?.cancel()

                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        guard !Task.isCancelled else { return }
                        await viewModel.search()
                    }
                }
                .onSubmit {
                    searchTask?.cancel()
                    Task { await viewModel.search() }
                }

            if viewModel.isLoading {
                ProgressView()
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            if !viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !viewModel.isLoading,
               viewModel.results.isEmpty,
               viewModel.errorMessage == nil {
                ContentUnavailableView(
                    "No Users Found",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("Try a different username.")
                )
            } else {
                List(viewModel.results, id: \.uid) { user in
                    HStack(spacing: 12) {
                        Image(systemName: user.emotionSymbol ?? "person.crop.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("@\(user.username)")
                                .font(.headline)
                        }

                        Spacer()

                        relationshipButton(for: user)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .padding()
        .onDisappear {
            searchTask?.cancel()
        }
    }

    @ViewBuilder
    private func relationshipButton(for user: UsernameLookup) -> some View {
        switch user.relationshipState {
        case .me:
            Text("You")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

        case .none:
            Button("Add") {
                Task {
                    
                    await viewModel.sendRequest(to: user) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

        case .pendingOutgoing:
            Button("Pending") {
                Task { await viewModel.cancelRequest(to: user) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

        case .pendingIncoming:
            Menu {
                Button("Accept") {
                    Task { await viewModel.acceptRequest(from: user) }
                }

                Button("Decline", role: .destructive) {
                    Task { await viewModel.declineRequest(from: user) }
                }
            } label: {
                Text("Respond")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

        case .friends:
            Text("Friends")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
        }
    }
}
