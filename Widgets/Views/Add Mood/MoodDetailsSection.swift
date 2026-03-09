//
//  MoodDetailsSection.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import SwiftUI
import HealthKit

@available(iOS 26.0, *)
struct MoodDetailsSection: View {
    @ObservedObject var viewModel: AddMoodViewModel
    

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            

            detailSection(
                .context,
                title: "Context",
                subtitle: "What is influencing your mood?"
            ) {
                MoodTagSelectorView(
                    suggestedTags: viewModel.suggestedTags,
                    selectedTags: $viewModel.selectedContextTags,
                    customTags: $viewModel.customMoodTags
                )
                .id(viewModel.suggestedTags)
            }

            detailSection(
                .note,
                title: "Note",
                subtitle: "Write what is contributing to this mood."
            ) {
                TextField("What’s going on right now?", text: $viewModel.note, axis: .vertical)
                    .lineLimit(4...8)
                    .inputStyle()
            }

            detailSection(
                .journal,
                title: "Journal",
                subtitle: "Capture a deeper reflection for this check-in."
            ) {
                VStack(spacing: 12) {
                 

                    TextField("Journal reflection", text: $viewModel.journalAnswer, axis: .vertical)
                        .lineLimit(5...10)
                        .inputStyle()
                }
            }

            detailSection(
                .media,
                title: "Media",
                subtitle: "Attach links now, or replace this with photo/video pickers later."
            ) {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        TextField("Photo URL", text: $viewModel.newPhotoURL)
                            .inputStyle()

                        Button("Add") {
                            viewModel.addPhotoURL()
                        }
                        .buttonStyle(.glass)
                    }

                    HStack(spacing: 10) {
                        TextField("Video URL", text: $viewModel.newVideoURL)
                            .inputStyle()

                        Button("Add") {
                            viewModel.addVideoURL()
                        }
                        .buttonStyle(.glass)
                    }

                    if !viewModel.mediaItems.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(viewModel.mediaItems) { item in
                                MediaRow(item: item) {
                                    viewModel.removeMedia(item)
                                }
                            }
                        }
                    }
                }
            }

            detailSection(.weather, title: "Weather Snapshot", subtitle: "Store optional weather context with the entry.") {
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.isLoadingWeather {
                        ProgressView("Loading weather…")
                    } else if let error = viewModel.weatherErrorMessage {
                        Text("Weather unavailable")
                            .font(.subheadline.weight(.semibold))

                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Button("Try Again") {
                            Task {
                                await viewModel.loadWeather()
                            }
                        }
                        .buttonStyle(.glass)
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "\(viewModel.weatherConditionCode).fill")

                            if let temp = viewModel.weatherTempC {
                                Text("\(temp, specifier: "%.1f")°F")
                            } else {
                                Text("—")
                            }
                        }
                    }
                }
                .task {
                    await viewModel.loadWeather()
                }
            }
        }
        .cardStyle(radius: viewModel.cardRadius, material: .regularMaterial)
    }

    @ViewBuilder
    private func detailSection<Content: View>(
        _ key: SectionKey,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    viewModel.toggleSection(key)
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)

                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: viewModel.expandedSections.contains(key) ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if viewModel.expandedSections.contains(key) {
                content()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}
