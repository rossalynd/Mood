//
//  FriendProfileView.swift
//  Widgets
//
//  Created by Rosie on 3/14/26.
//


import SwiftUI

struct FriendProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FriendProfileViewModel
    @State private var isRemovingFriend = false
    @State private var showRemoveConfirmation = false

    init(viewModel: FriendProfileViewModel) {
            _viewModel = StateObject(wrappedValue: viewModel)
        }

        init(friendUID: String) {
            _viewModel = StateObject(wrappedValue: FriendProfileViewModel(friendUID: friendUID))
        }

    var body: some View {
        
        ZStack {
            LiquidBackdrop()
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                if let data = viewModel.data {
                    VStack(spacing: 20) {
                        headerSection(data)
                        latestMoodSection(data)
                        insightsSection(data)
                        recentMoodsSection(data)
                    }
                    .padding()
                } else if viewModel.isLoading {
                    VStack(spacing: 14) {
                        ProgressView()
                        Text("Loading profile...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    ContentUnavailableView(
                        "Couldn’t Load Profile",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text(viewModel.errorMessage ?? "Something went wrong.")
                    )
                    .padding(.top, 80)
                }
            }
            
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
            .confirmationDialog(
                "Remove friend?",
                isPresented: $showRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove Friend", role: .destructive) {
                    Task {
                        await removeFriend()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("They’ll be removed from your friends list.")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil && !viewModel.isLoading)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func removeFriend() async {
        isRemovingFriend = true
        defer { isRemovingFriend = false }

        do {
            try await viewModel.removeFriend()
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func headerSection(_ data: FriendProfileViewData) -> some View {
        VStack(spacing: 12) {
            
           
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 100, height: 100)
                    Image(systemName: data.emotionSymbol ?? "face.smiling")
                        .font(.system(size: 70, weight: .thin))
                        .foregroundStyle(data.headerMoodColor)
                        
                }
               
                VStack(spacing: 4) {
                    
                    
                    Text(data.displayName)
                        .font(.title2.weight(.semibold))
                    
                    Text("@\(data.username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let friendsSince = data.friendsSince {
                        Text("Friends since \(friendsSince.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            
            HStack(spacing: 10) {
                Label("Friends", systemImage: "person.2.fill")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())

                Button {
                    showRemoveConfirmation = true
                } label: {
                    Group {
                        if isRemovingFriend {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("Remove", systemImage: "person.fill.xmark")
                                .font(.caption.weight(.medium))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                }
                .disabled(isRemovingFriend)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        
    }

    private func latestMoodSection(_ data: FriendProfileViewData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest shared mood")
                .font(.headline)

            if let mood = data.latestMood {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(mood.emoji)
                            .resizable()
                            .frame(width: 48, height: 48)
                            .foregroundStyle(mood.moodColor)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(moodTitle(mood))
                                .font(.title3.weight(.semibold))

                            Text(mood.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                Text("No friend-visible moods yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
    }

    private func insightsSection(_ data: FriendProfileViewData) -> some View {
        HStack(spacing: 12) {
            insightCard(title: "Shared", value: "\(data.totalSharedCount)")
            insightCard(title: "Streak", value: "\(data.streakCount)")
            insightCard(title: "Top Mood", value: data.topMoodLabel ?? "—")
        }
    }

    private func insightCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func recentMoodsSection(_ data: FriendProfileViewData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent moods")
                .font(.headline)

            if data.recentMoods.isEmpty {
                Text("Nothing shared yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(data.recentMoods, id: \.id) { mood in
                        HStack(spacing: 12) {
                            Image(mood.emoji)
                                .resizable()
                                .frame(width: 48, height: 48)
                                .foregroundStyle(mood.moodColor)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(moodTitle(mood))
                                    .font(.subheadline.weight(.semibold))

                                Text(mood.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            moodPrivacyBadge(mood.visibility)
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    private func moodTitle(_ mood: SharedMoodSummary) -> String {
        mood.moodKey
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    private func moodPrivacyBadge(_ visibility: String) -> some View {
        let title: String
        let systemImage: String

        switch visibility {
        case "public":
            title = "Public"
            systemImage = "globe"
        case "friends":
            title = "Friends"
            systemImage = "person.2.fill"
        default:
            title = "Private"
            systemImage = "lock.fill"
        }

        return Label(title, systemImage: systemImage)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
    }
}



#Preview {
    FriendProfileView(viewModel: .preview())
}
