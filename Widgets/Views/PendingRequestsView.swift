//
//  PendingRequestsView.swift
//  Widgets
//
//  Created by Rosie on 3/14/26.
//


import SwiftUI

struct PendingRequestsView: View {
    @StateObject private var viewModel = PendingRequestsViewModel()

    var body: some View {
        VStack {
            FriendSearchView()
            ScrollView {
                if !viewModel.incoming.isEmpty {
                    Section("Incoming") {
                        ForEach(viewModel.incoming) { request in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(request.username.map { "@\($0)" } ?? request.fromUID)
                                        .font(.headline)
                                    
                                    Text("Sent you a friend request")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Button("Decline", role: .destructive) {
                                        Task { await viewModel.decline(request) }
                                    }
                                    
                                    Button("Accept") {
                                        Task { await viewModel.accept(request) }
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                    }
                }
                
                if !viewModel.outgoing.isEmpty {
                    Section("Outgoing") {
                        ForEach(viewModel.outgoing) { request in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(request.username.map { "@\($0)" } ?? request.toUID)
                                        .font(.headline)
                                    
                                    Text("Pending")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Cancel") {
                                    Task { await viewModel.cancel(request) }
                                }
                            }
                        }
                    }
                }
                
                if viewModel.incoming.isEmpty && viewModel.outgoing.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Pending Requests",
                        systemImage: "person.2.slash",
                        description: Text("You don't have any friend requests right now.")
                    )
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Friend Requests")
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
