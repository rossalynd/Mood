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
                .frame(width: .infinity, height: .infinity)   // important
                .ignoresSafeArea()
                .opacity(0.05)
        }
    }
}
