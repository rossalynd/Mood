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

    var body: some View {
        HStack(spacing: 6) {
            ForEach(MoodTab.allCases, id: \.self) { tab in
                GlassTabItem(
                    tab: tab,
                    isSelected: tab == selected
                ) {
                    onSelect(tab)
                }
            }
        }
        .padding(10)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 10)
        .accessibilityElement(children: .contain)
    }
}
