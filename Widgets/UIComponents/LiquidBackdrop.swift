//
//  LiquidBackdrop.swift
//  Widgets
//
//  Created by Rosie on 3/3/26.
//

import Foundation
import SwiftUI
// MARK: - Backdrop
struct LiquidBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.instablue),
                    Color(.instapurple)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image("stars")
                .resizable()
                
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .opacity(0.05)
                .clipped()
        }
    }
}
