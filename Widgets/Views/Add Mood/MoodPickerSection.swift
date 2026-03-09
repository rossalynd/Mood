//
//  MoodPickerSection.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import SwiftUI
import HealthKit

@available(iOS 26.0, *)
struct MoodPickerSection: View {
    @ObservedObject var viewModel: AddMoodViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            searchBar
            pickerControls

            if viewModel.visibleMoods.isEmpty {
                ContentUnavailableView(
                    "No moods found",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search or filter.")
                )
                .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: viewModel.moodColumns, spacing: 12) {
                    ForEach(viewModel.visibleMoods) { mood in
                        PremiumMoodGridCell(
                            mood: mood,
                            isSelected: viewModel.selectedLabel == mood.label
                        ) {
                            viewModel.selectMood(mood)
                        }
                    }
                }
            }
        }
        .cardStyle(radius: viewModel.cardRadius, material: .ultraThinMaterial)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search moods", text: $viewModel.query)
                .textInputAutocapitalization(.never)

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.clearQuery()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .inputStyle()
    }

    private var pickerControls: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MoodFilter.allCases) { option in
                        FilterChip(
                            title: option.title,
                            isSelected: viewModel.filter == option
                        ) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                viewModel.filter = option
                            }
                        }
                    }
                }
            }

            Picker("Sort", selection: $viewModel.moodSort) {
                Text("By Level").tag(MoodSort.byLevel)
                Text("A–Z").tag(MoodSort.alphabetical)
            }
            .pickerStyle(.segmented)
        }
    }
}
