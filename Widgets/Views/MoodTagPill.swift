//
//  MoodTagPill.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import SwiftUI

struct MoodTagPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.primary.opacity(0.85) : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isSelected)
    }
}
import SwiftUI

struct PremiumTagPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(background)
            .overlay(border)
            .clipShape(Capsule())
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .shadow(color: .black.opacity(isSelected ? 0.12 : 0), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
    }

    private var background: some View {
        Capsule()
            .fill(
                isSelected
                ? Color.primary.opacity(0.88)
                : Color.white.opacity(0.08)
            )
    }

    private var border: some View {
        Capsule()
            .stroke(
                isSelected
                ? Color.white.opacity(0.16)
                : Color.white.opacity(0.10),
                lineWidth: 1
            )
    }
}
