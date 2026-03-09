//
//  GlassTabBar.swift
//  Widgets
//
//  Created by Rosie on 3/3/26.
//
import SwiftUI
import Foundation

@available(iOS 26.0, *)
struct GlassTabBar: View {
    @Binding var selected: MoodTab
    var onSelect: (MoodTab) -> Void

    @Namespace private var selectionAnimation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MoodTab.allCases, id: \.self) { tab in
                GlassTabItem(
                    tab: tab,
                    isSelected: tab == selected,
                    namespace: selectionAnimation
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                        onSelect(tab)
                    }
                }
            }
        }
        .padding(4)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 60, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 10)
        .accessibilityElement(children: .contain)
    }
}

#Preview("GlassTabBar") {
    GlassTabBarPreview()
        .padding()
        .background(.black.opacity(0.1))
}

@available(iOS 26.0, *)
private struct GlassTabBarPreview: View {
    @State private var selected: MoodTab = .home

    var body: some View {
        GlassTabBar(selected: $selected) { tab in
            selected = tab
        }
        .padding()
    }
}
