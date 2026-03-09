//
//  MoodTagSelectorView.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import SwiftUI

struct MoodTagSelectorView: View {
    let suggestedTags: [String]
       @Binding var selectedTags: Set<String>
       @Binding var customTags: [String]

    @State private var customTagText: String = ""
    @State private var searchText: String = ""

    private var filteredTags: [String] {
        let merged = Array(Set(suggestedTags + customTags))

        let filtered: [String]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filtered = merged
        } else {
            filtered = merged.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered.sorted { lhs, rhs in
            let lhsSelected = selectedTags.contains(lhs)
            let rhsSelected = selectedTags.contains(rhs)

            if lhsSelected != rhsSelected {
                return lhsSelected && !rhsSelected
            }

            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            
                
                header
                searchBar
            
            tagCloud
            addCustomTagRow

            
        }
        
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: selectedTags)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: filteredTags)
    }

    private var header: some View {
        HStack(alignment: .top) {
            

            Spacer()

            if !selectedTags.isEmpty {
                Button("Clear") {
                    selectedTags.removeAll()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search tags", text: $searchText)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var tagCloud: some View {
        TagFlowLayout(spacing: 10) {
            ForEach(filteredTags, id: \.self) { tag in
                PremiumTagPill(
                    title: tag,
                    isSelected: selectedTags.contains(tag)
                ) {
                    toggle(tag)
                }
            }
        }
    }

    private var addCustomTagRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.secondary)

                TextField("Add custom tag", text: $customTagText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onSubmit {
                        addCustomTag()
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )

            Button {
                addCustomTag()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(cleanedCustomTag.isEmpty ? Color.white.opacity(0.08) : Color.white.opacity(0.16))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(cleanedCustomTag.isEmpty)
            .opacity(cleanedCustomTag.isEmpty ? 0.5 : 1)
        }
    }

    private var selectedTagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Selected")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(selectedTags).sorted(), id: \.self) { tag in
                        HStack(spacing: 8) {
                            Text(tag)
                                .font(.subheadline.weight(.medium))

                            Button {
                                selectedTags.remove(tag)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.10))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.03))
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
    }

    private var cleanedCustomTag: String {
        customTagText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func toggle(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    private func addCustomTag() {
        let newTag = cleanedCustomTag
        guard !newTag.isEmpty else { return }

        let alreadyExists =
            suggestedTags.contains(where: { $0.caseInsensitiveCompare(newTag) == .orderedSame }) ||
            customTags.contains(where: { $0.caseInsensitiveCompare(newTag) == .orderedSame })

        if !alreadyExists {
            customTags.append(newTag)
        }

        selectedTags.insert(newTag)
        customTagText = ""
        searchText = ""
    }
}
