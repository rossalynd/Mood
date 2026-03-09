//
//  SignInPromptCard.swift
//  Widgets
//
//  Created by Rosie on 3/9/26.
//

import SwiftUI

@available(iOS 26.0, *)
struct SignInPromptCard: View {
    let cardRadius: CGFloat
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .blue.opacity(0.24),
                                    .purple.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)

                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.95))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sign in to add more detail")
                        .font(.headline)

                    Text("Add notes, context, journal reflections, weather, and photos to capture the full moment.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            FeaturePreviewRow()
        }
        .cardStyle(radius: cardRadius, material: .regularMaterial)
        .overlay {
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
        .onTapGesture(perform: onTap)
    }
}

@available(iOS 26.0, *)
private struct FeaturePreviewRow: View {
    private let items: [FeaturePreviewItem] = [
        .init(title: "Notes", systemImage: "note.text"),
        .init(title: "Photos", systemImage: "photo"),
        .init(title: "Weather", systemImage: "cloud.sun"),
        .init(title: "Journal", systemImage: "book.closed")
    ]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(items) { item in
                VStack(spacing: 6) {
                    Image(systemName: item.systemImage)
                        .font(.caption.weight(.semibold))

                    Text(item.title)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                }
                .foregroundStyle(.primary.opacity(0.82))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.white.opacity(0.08), in: Capsule())
            }

            Spacer(minLength: 0)
        }
    }
}

@available(iOS 26.0, *)
private struct FeaturePreviewItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
}
