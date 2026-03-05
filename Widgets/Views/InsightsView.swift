//
//  InsightsView.swift
//  Widgets
//
//  Created by Rosie on 3/3/26.
//

import Foundation
import SwiftUI
@available(iOS 26.0, *)
struct InsightsView: View {
    @Binding var path: NavigationPath
    var body: some View {
        ZStack {
            LiquidBackdrop().ignoresSafeArea()
            Text("Insights Placeholder")
                .font(.title2.weight(.semibold))
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top) {
            HStack {
                Text("Insights").font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            .background(.thinMaterial)
            .overlay(alignment: .bottom) { Divider().opacity(0.25) }
        }
    }
}
