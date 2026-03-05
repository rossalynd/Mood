//
//  WatchMoodPicker.swift
//  Widgets
//
//  Created by Rosie on 3/4/26.
//

import SwiftUI
import HealthKit

struct WatchMoodPicker: View {

    @EnvironmentObject var moodStore: HealthKitMoodStore
    @Environment(\.dismiss) private var dismiss

    var onSaved: () -> Void

    private let quickMoods: [HKStateOfMind.Label] = [
        .happy,
        .calm,
        .content,
        .excited,
        .indifferent,
        .drained,
        .anxious,
        .stressed,
        .sad,
        .angry
    ]

    var body: some View {

        List {

            ForEach(quickMoods, id: \.self) { label in

                Button {

                    Task {

                        try? await moodStore.saveMood(
                            valence: label.defaultValence,
                            kind: .momentaryEmotion,
                            labels: [label]
                        )

                        onSaved()
                        dismiss()
                    }

                } label: {

                    HStack {

                        Image(label.displayName)
                            .frame(width: 24)

                        Text(label.displayName)

                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Mood")
    }
}
