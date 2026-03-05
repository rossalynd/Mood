//
//  ProfileView.swift
//  Widgets
//
//  Created by Rosie on 3/3/26.
//

import SwiftUI

// MARK: - ProfileView (Skeleton)

@available(iOS 26.0, *)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // TODO: Inject stores / auth / user model
    // @EnvironmentObject var authStore: AuthStore
    // @EnvironmentObject var moodStore: HealthKitMoodStore
    // @EnvironmentObject var friendsStore: FriendsStore

 

    // MARK: Placeholder state
    @State private var displayName: String = "Rosie"
    @State private var username: String = "@mood"
    @State private var selectedAvatarColor: Color = .gray

    @State private var notificationsEnabled = true
    @State private var dailyReminderEnabled = false
    @State private var dailyReminderTime = Date()

    @State private var healthSyncEnabled = true
    @State private var lockScreenWidgetEnabled = true
    @State private var friendsEnabled = false
    @State private var isSignedIn = false

    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var showFriends = false
    @State private var showExport = false
    @State private var showAbout = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            
            LiquidBackdrop()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    profileHeaderCard
                    
                    quickStatsCard
                    
                    preferencesCard
                    
                    featuresCard
                    
                    accountCard
                    
                    supportCard
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            
            
            .sheet(isPresented: $showEditProfile) {
                PlaceholderSheet(title: "Edit Profile")
            }
            .sheet(isPresented: $showFriends) {
                PlaceholderSheet(title: "Friends")
            }
            .sheet(isPresented: $showExport) {
                PlaceholderSheet(title: "Export Data")
            }
            .sheet(isPresented: $showAbout) {
                PlaceholderSheet(title: "About")
            }
            .sheet(isPresented: $showPaywall) {
                PlaceholderSheet(title: "Upgrade")
            }
        }
        
    }

    // MARK: - Header

    private var profileHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(selectedAvatarColor.opacity(0.25))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.headline)
                    Text(username)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showEditProfile = true
                } label: {
                    Text("Edit")
                }
                .buttonStyle(.bordered)
            }

            // TODO: Optional tagline / status
            Text("Your space to track moods, patterns, and progress.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        
    }

    // MARK: - Quick Stats

    private var quickStatsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("At a glance")
                .font(.headline)

            // TODO: Replace with real stats
            VStack(spacing: 10) {
                statRow(title: "Streak", value: "3 days", systemImage: "bolt")
                statRow(title: "This month", value: "24 check-ins", systemImage: "calendar")
                statRow(title: "Most common mood", value: "Calm 😌", systemImage: "face.smiling")
            }
            .font(.subheadline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Preferences

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preferences")
                .font(.headline)

            VStack(spacing: 0) {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Notifications", systemImage: "bell")
                }
                .padding(.vertical, 10)

                Divider()

                Toggle(isOn: $dailyReminderEnabled) {
                    Label("Daily reminder", systemImage: "alarm")
                }
                .padding(.vertical, 10)

                if dailyReminderEnabled {
                    DatePicker("Reminder time", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .padding(.bottom, 10)
                }

                Divider()

                Toggle(isOn: $healthSyncEnabled) {
                    Label("Apple Health sync", systemImage: "heart")
                }
                .padding(.vertical, 10)

                Divider()

                Toggle(isOn: $lockScreenWidgetEnabled) {
                    Label("Lock Screen widget", systemImage: "rectangle.inset.filled")
                }
                .padding(.vertical, 10)
            }
            .font(.subheadline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Features / Social / Premium

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Features")
                .font(.headline)

            VStack(spacing: 10) {
                Toggle(isOn: $friendsEnabled) {
                    Label("Friends (optional)", systemImage: "person.2")
                }
                .font(.subheadline)

                HStack(spacing: 10) {
                    Button {
                        showFriends = true
                    } label: {
                        Label("Manage friends", systemImage: "person.crop.circle.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        // TODO: Share app link / invite flow
                    } label: {
                        Label("Invite", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Upgrade", systemImage: "sparkles")
                        Spacer()
                        Text("Placeholder")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Account

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Account")
                .font(.headline)

            VStack(spacing: 10) {
                HStack {
                    Label("Status", systemImage: "person.badge.key")
                    Spacer()
                    Text(isSignedIn ? "Signed in" : "Not signed in")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                HStack(spacing: 10) {
                    Button {
                        // TODO: Sign in / create account
                    } label: {
                        Text(isSignedIn ? "Manage account" : "Sign in (optional)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        // TODO: Sign out / delete local data etc.
                    } label: {
                        Text("Sign out")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isSignedIn)
                }

                Divider()

                Button {
                    showExport = true
                } label: {
                    HStack {
                        Label("Export data", systemImage: "square.and.arrow.up")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)

                Button(role: .destructive) {
                    // TODO: Delete data action + confirmation
                } label: {
                    HStack {
                        Label("Delete all data", systemImage: "trash")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Support / About

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Support")
                .font(.headline)

            VStack(spacing: 10) {
                Button {
                    // TODO: Contact support mail composer / link
                } label: {
                    HStack {
                        Label("Contact support", systemImage: "envelope")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)

                Button {
                    // TODO: FAQ / Help
                } label: {
                    HStack {
                        Label("Help / FAQ", systemImage: "questionmark.circle")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)

                Button {
                    showAbout = true
                } label: {
                    HStack {
                        Label("About", systemImage: "info.circle")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)

                Divider()

                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0 (placeholder)")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Helpers

    private func statRow(title: String, value: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Placeholder Sheet

private struct PlaceholderSheet: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("\(title) Placeholder")
                    .font(.title3.weight(.semibold))
                Text("Replace this with your real view.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
