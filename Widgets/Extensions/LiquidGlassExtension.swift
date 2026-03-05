//
//  LiquidGlassExtension.swift
//  Widgets
//
//  Created by Rosie on 3/3/26.
//

import Foundation
import SwiftUI
extension View {
    func liquidGlassCard(cornerRadius: CGFloat, material: Material) -> some View {
        self
            .background(material, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 8)
    }
}
