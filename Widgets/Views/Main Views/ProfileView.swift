import SwiftUI
import PhotosUI

@available(iOS 26.0, *)
struct ProfileView: View {
    @Binding var path: NavigationPath

    @State private var shouldShowSetup = false
    @State private var showSignIn = false

    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var profileStore: ProfileStore

    var body: some View {
        ZStack {
            LiquidBackdrop()
                .ignoresSafeArea()
            ScrollView{
                VStack(spacing: 18) {
                    if auth.isSignedIn {
                        signedInContent
                    } else {
                        signedOutPremiumPrompt
                    }
                }.padding(.horizontal, 20)
                    .padding(.bottom, 60)
                    .padding(.top, 16)
            }
            
        }
       
        .navigationBarHidden(true)
        
        .task {
            guard auth.isSignedIn else { return }
            await profileStore.loadCurrentUserProfile()
            presentSetupIfNeeded()
        }
        .onChange(of: auth.isSignedIn) { _, isSignedIn in
            Task {
                if isSignedIn {
                    await profileStore.loadCurrentUserProfile()
                }
                presentSetupIfNeeded()
            }
        }
        .sheet(isPresented: $shouldShowSetup) {
            AccountSetupView { data in
                Task {
                    do {
                        print("Current UID:", auth.currentUser?.uid ?? "nil")
                        try await profileStore.saveAccountSetup(data)
                        shouldShowSetup = false
                    } catch {
                        print("Failed to save profile:", error.localizedDescription)
                    }
                }
            }
        }
        .sheet(isPresented: $showSignIn) {
            SignInSheetView()
                .environmentObject(auth)
        }
    }
    // MARK: - Present Setup
    private func presentSetupIfNeeded() {
            shouldShowSetup = auth.isSignedIn && !(profileStore.profile?.hasCompletedSetup ?? false)
        }

        private var signedInContent: some View {
            VStack(spacing: 16) {
                if let profile = profileStore.profile {
                    Text(profile.displayName)
                        .font(.title2.bold())

                    Text("@\(profile.username)")
                        .foregroundStyle(.secondary)

                    Button("Edit Profile") {
                        shouldShowSetup = true
                    }
                    .buttonStyle(.borderedProminent)
                } else if profileStore.isLoading {
                    ProgressView()
                } else {
                    Button {
                        shouldShowSetup = true
                    } label: {
                        Label("Complete Account Setup", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }

   



    // MARK: - Signed Out Premium Prompt

    private var signedOutPremiumPrompt: some View {
        
        VStack(spacing: 20) {
            

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    )

                VStack(spacing: 20) {
                    ZStack(alignment: .center) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.22),
                                        .white.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 84, height: 84)
                            
                        
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 68, weight: .medium))
                                .foregroundStyle(.white)
                                .padding()
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(.white)
                                
                            
                        }
                    }
                    .padding(.top, 30)
                

                    VStack(spacing: 8) {
                        Text("Unlock Your Profile")
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)

                        Text("Sign in to save your account, personalize your mood journey, and access everything across devices.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    VStack(spacing: 12) {
                        premiumBenefitRow(
                            icon: "icloud.fill",
                            title: "Sync everywhere",
                            subtitle: "Keep your profile and mood experience available across your devices."
                        )

                        premiumBenefitRow(
                            icon: "sparkles",
                            title: "Personalized experience",
                            subtitle: "Set up your name, preferences, reminders, and profile details."
                        )

                        premiumBenefitRow(
                            icon: "lock.shield.fill",
                            title: "Private and secure",
                            subtitle: "Keep your account connected to a secure sign-in method."
                        )
                    }

                    Button {
                        showSignIn = true
                    } label: {
                        HStack {
                            Image(systemName: "person.fill.badge.plus")
                            Text("Sign In / Create Account")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 4)

                    Text("Create your account to access your full profile experience.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
            .shadow(color: .black.opacity(0.10), radius: 24, y: 10)
            
            
            .padding(.top, 20)
           
           

           
            
        }
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
       
        
    }

    // MARK: - Reusable Row

    private func premiumBenefitRow(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.10))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ProfileView(path: .constant(NavigationPath()))
        .environmentObject(AuthService())
        .environmentObject(ProfileStore())
}
