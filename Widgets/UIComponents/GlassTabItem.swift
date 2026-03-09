//
//  GlassTabItem.swift
//  Widgets
//
//  Created by Rosie on 3/3/26.
//
import SwiftUI

@available(iOS 26.0, *)
struct GlassTabItem: View {
    let tab: MoodTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(tab.title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
        .background(
            Group {
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.clear)
                }
                
            }
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isSelected)
        
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
