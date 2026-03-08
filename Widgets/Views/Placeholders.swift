//
//  Placeholders.swift
//  Widgets
//
//  Created by Rosie on 3/3/26.
//

import Foundation
import SwiftUI


// MARK: - Placeholder Types
struct QuickMood: Identifiable {
    let id = UUID()
    let assetName: String
    let label: String
}

struct MoodToolItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let path: HomeRoute
}

// MARK: - Placeholder “Full Screen” Push Views
@available(iOS 26.0, *)
struct PlaceholderPushView: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Text("\(title)")
                .font(.largeTitle.bold())
            Text("Replace this with your real view.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

