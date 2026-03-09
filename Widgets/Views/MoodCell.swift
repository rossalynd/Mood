//
//  MoodCell.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//
import Foundation
import SwiftUI

@available(iOS 26.0, *)
struct MoodCell: View {
    let mood: MoodItem
    let isSelected: Bool

    @State private var bump = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(isSelected ? 0.16 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                isSelected
                                ? mood.level.color.opacity(0.9)
                                : .white.opacity(0.08),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )

                VStack(spacing: 8) {
                    Circle()
                        .fill(mood.level.color.opacity(isSelected ? 0.30 : 0.18))
                        .frame(width: 44, height: 44)
                        .overlay {
                            mood.emoji
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                        }

                    Text(mood.displayName)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 6)
                }
                .padding(.vertical, 10)
            }
        }
        .scaleEffect(bump ? 1.05 : 1.0)
        .onChange(of: isSelected) { _, newValue in
            guard newValue else { return }
            bump = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                bump = false
            }
        }
        .animation(.easeOut(duration: 0.12), value: bump)
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isSelected)
    }
}
