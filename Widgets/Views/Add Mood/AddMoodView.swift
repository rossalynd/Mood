//
//  AddMoodView.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import SwiftUI
import HealthKit
import WidgetKit

@available(iOS 26.0, *)
struct AddMoodView: View {
    @EnvironmentObject private var moodStore: HealthKitMoodStore
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var firestoreMoodStore: MoodFirestoreService
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = AddMoodViewModel()
    @State private var showSignIn = false
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LiquidBackdrop()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    AddMoodHeaderView()

                    if viewModel.expandHero {
                        SelectedMoodHeroCard(
                            selectedMoodItem: viewModel.selectedMoodItem,
                            cardRadius: viewModel.cardRadius
                        ) {
                            viewModel.expandHero = false
                        }
                    } else {
                        MoodPickerSection(viewModel: viewModel)
                    }

                    if auth.isSignedIn {
                        VisibilityPickerSection(visibility: $viewModel.visibility)
                        MoodDetailsSection(viewModel: viewModel)
                    } else {
                        SignInPromptCard(cardRadius: viewModel.cardRadius) {
                            showSignIn = true
                           }
                    }

                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            if viewModel.canSave {
                SaveMoodBar(
                    canSave: viewModel.canSave,
                    isSaving: viewModel.isSaving,
                    selectedMoodItem: viewModel.selectedMoodItem,
                    visibility: viewModel.visibility
                ) {
                    Task {
                        
                        await viewModel.saveMood(using: moodStore, auth: auth)
                        if viewModel.didSaveSuccessfully {
                            dismiss()
                        }
                    }
                }
            }
            
        }
        .autocorrectionDisabled(false)
        .textInputAutocapitalization(.sentences)
        .alert("Couldn't save mood", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .sheet(isPresented: $showSignIn) {
            SignInSheetView()
                .environmentObject(auth)
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    RootShellView()
        .environmentObject(HealthKitMoodStore())
        .environmentObject(AuthService())
        .environmentObject(DeepLinkRouter())
}
