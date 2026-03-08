//
//  SignInSheetView.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//

import SwiftUI

struct SignInSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthService

    @State private var selectedMethod: AuthMethod? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumSignInBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection

                        AuthStatusRow(
                            isLoading: auth.isLoading,
                            errorMessage: auth.errorMessage,
                            successMessage: auth.successMessage
                        )

                        VStack(spacing: 12) {
                            ExpandableAuthCard(
                                title: "Email",
                                subtitle: "Sign in or create an account with email",
                                icon: "envelope.fill",
                                isExpanded: selectedMethod == .email,
                                action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                        toggle(.email)
                                    }
                                }
                            ) {
                                EmailPasswordAuthView()
                                    .environmentObject(auth)
                            }

                            ExpandableAuthCard(
                                title: "Phone",
                                subtitle: "Use a verification code to continue",
                                icon: "phone.fill",
                                isExpanded: selectedMethod == .phone,
                                action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                        toggle(.phone)
                                    }
                                }
                            ) {
                                PhoneAuthView()
                                    .environmentObject(auth)
                            }

                            ExpandableAuthCard(
                                title: "Apple",
                                subtitle: "Fast, private, and secure",
                                icon: "apple.logo",
                                isExpanded: selectedMethod == .apple,
                                action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                        toggle(.apple)
                                    }
                                }
                            ) {
                                AppleAuthView()
                                    .environmentObject(auth)
                            }
                        }

                        continueWithoutAccountButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .onChange(of: auth.isSignedIn) { _, signedIn in
                if signedIn {
                    dismiss()
                }
            }
        }
    }

    private func toggle(_ method: AuthMethod) {
        selectedMethod = selectedMethod == method ? nil : method
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.22),
                                Color.purple.opacity(0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 74, height: 74)

                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 32, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)
            }
            .padding(.top, 6)

            VStack(spacing: 8) {
                Text("Welcome back")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("Choose a sign-in method to continue.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var continueWithoutAccountButton: some View {
        Button {
            dismiss()
        } label: {
            VStack(spacing: 4) {
                Text("Continue without signing in")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("You can create an account later in Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16))
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }
}

private enum AuthMethod {
    case email
    case phone
    case apple
}

struct ExpandableAuthCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let isExpanded: Bool
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white.opacity(0.10))
                            .frame(width: 44, height: 44)

                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(18)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .overlay(Color.white.opacity(0.08))

                    VStack(spacing: 14) {
                        content
                    }
                    .padding(18)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 22, y: 10)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isExpanded)
    }
}

struct PremiumSignInBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.accentColor.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: -120, y: -260)

            Circle()
                .fill(Color.purple.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 110)
                .offset(x: 150, y: -180)

            Circle()
                .fill(Color.blue.opacity(0.08))
                .frame(width: 240, height: 240)
                .blur(radius: 100)
                .offset(x: 80, y: 320)
        }
    }
}

#Preview {
    SignInSheetView()
        .environmentObject(AuthService.preview)
}

extension AuthService {
    @MainActor
    static let preview: AuthService = {
        let service = AuthService()
        service.errorMessage = nil
        service.successMessage = nil
        service.isLoading = false
        return service
    }()
}
