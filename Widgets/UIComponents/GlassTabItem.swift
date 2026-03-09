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
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 22, weight: .semibold))

                Text(tab.title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .background {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 65, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 65, style: .continuous)
                                    .stroke(.white.opacity(0.18), lineWidth: 1)
                            )
                            .glassEffect()
                            
                            .matchedGeometryEffect(id: "selectedTabBackground", in: namespace)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("GlassTabItem Selected") {
    @Namespace var ns

    return GlassTabItem(
        tab: .home,
        isSelected: true,
        namespace: ns,
        action: {}
    )
    .padding()
    .background(.black.opacity(0.1))
}
