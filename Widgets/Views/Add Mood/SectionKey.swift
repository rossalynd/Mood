//
//  SectionKey.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import SwiftUI
import HealthKit

@available(iOS 26.0, *)
enum SectionKey: Hashable {
    case context
    case note
    case journal
    case sharing
    case media
    case weather
}

@available(iOS 26.0, *)
struct PremiumMoodGridCell: View {
    let mood: MoodItem
    let isSelected: Bool
    let action: () -> Void

    @State private var bump = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(mood.level.color.opacity(isSelected ? 0.60 : 0.30))
                        .frame(width: 52, height: 52)

                    mood.emoji
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }

                Text(mood.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                  

                
            }
            .frame(maxWidth: .infinity, minHeight: 124)
            
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(isSelected ? 0.14 : 0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? mood.level.color.opacity(0.95) : .white.opacity(0.08),
                        lineWidth: isSelected ? 1.6 : 1
                    )
            )
            .scaleEffect(bump ? 1.09 : 1.0)
        }
        .buttonStyle(.plain)
        .onChange(of: isSelected) { _, newValue in
            guard newValue else { return }
            bump = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                bump = false
            }
        }
        .animation(.easeOut(duration: 0.12), value: bump)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isSelected)
    }
}

@available(iOS 26.0, *)
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? .white.opacity(0.18) : .white.opacity(0.08))
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(isSelected ? 0.24 : 0.10), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

@available(iOS 26.0, *)
struct TagWrapView: View {
    let tags: [String]
    @Binding var selectedTags: Set<String>

    private let rows = [GridItem(.adaptive(minimum: 88), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: rows, alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Button {
                    toggle(tag)
                } label: {
                    Text(tag)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedTags.contains(tag)
                            ? .instablue.opacity(0.16)
                            : .instapurple.opacity(0.08)
                        )
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.10), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}

@available(iOS 26.0, *)
struct MediaRow: View {
    let item: MoodMediaItem
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.type == .photo ? "photo.fill" : "video.fill")
                .foregroundStyle(.secondary)

            Text(item.url)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

extension View {
    func cardStyle(radius: CGFloat, material: Material) -> some View {
        self
            .padding(18)
            .liquidGlassCard(cornerRadius: radius, material: material)
    }

    func inputStyle() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                .white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    ZStack{
        LiquidBackdrop()
        MoodPickerSection(viewModel: AddMoodViewModel())
            
    }
}

