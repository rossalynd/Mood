//
//  AddMoodHeaderView.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import SwiftUI
import HealthKit

@available(iOS 26.0, *)
struct AddMoodHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How are you feeling?")
                .font(.title2.bold())

            Text("Capture how you feel with as much or as little detail as you want.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(iOS 26.0, *)
struct SelectedMoodHeroCard: View {
    let selectedMoodItem: MoodItem?
    let cardRadius: CGFloat
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((selectedMoodItem?.level.color ?? .white).opacity(0.18))
                    .frame(width: 58, height: 58)

                if let selectedMoodItem {
                    selectedMoodItem.emoji
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                } else {
                    Image(systemName: "face.smiling")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedMoodItem?.displayName ?? "No mood selected")
                    .font(.headline)

                
            }

            Spacer()
        }
        .cardStyle(radius: cardRadius, material: .regularMaterial)
        .onTapGesture(perform: onTap)
    }


}

@available(iOS 26.0, *)
struct VisibilityPickerSection: View {
    @Binding var visibility: MoodPrivacy

    var body: some View {
        Picker("Visibility", selection: $visibility) {
            ForEach(MoodPrivacy.allCases) { option in
                Label(option.displayName, systemImage: option.icon)
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
    }
}

@available(iOS 26.0, *)
struct SaveMoodBar: View {
    let canSave: Bool
    let isSaving: Bool
    let selectedMoodItem: MoodItem?
    let visibility: MoodPrivacy
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Divider()
                .overlay(.white.opacity(0.08))

            Button(action: action) {
                ZStack {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        
                            VStack(spacing: 3) {
                                Text("Save Mood")
                                    .font(.headline)
                                
                                if let selectedMoodItem {
                                    Text("\(selectedMoodItem.displayName) • \(visibility.displayName)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .disabled(!canSave)
            .padding(.horizontal)
            .padding(.bottom, 14)
        }
        
    }
}
