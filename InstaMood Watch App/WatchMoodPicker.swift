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

    private let quickMoods = AppleMoodLabels.all
        .filter { $0.level == .veryPositive || $0.level == .veryNegative }
    

    var body: some View {

        List {

            ForEach(
                AppleMoodLabels.all
                    .sorted { $0.level.sortRank > $1.level.sortRank },
                id: \.self
            ) { label in
                
                Button {

                    Task {
                        let moodID = "mood_\(UUID().uuidString.lowercased())"

                        let metadata: [String: Any] = [
                            HKMetadataKeySyncIdentifier: moodID,
                            HKMetadataKeySyncVersion: 1,
                            MoodMetadataKeys.appMoodID: moodID,
                            MoodMetadataKeys.deviceId: DeviceID.current()
                        ]
                        
                        try? await moodStore.saveMood(
                            valence: label.defaultValence,
                            kind: .momentaryEmotion,
                            labels: [label],
                            metadata: metadata
                        )

                        onSaved()
                        dismiss()
                    }

                } label: {

                    HStack(spacing: 10) {

                        Image(label.displayName)
                            .resizable()
                            .frame(width: 50, height: 50)
                            
                            
                            .foregroundStyle(label.level.color)

                        Text(label.displayName)

                        Spacer()
                    }
                }
                
            }
        }
        .navigationTitle("Mood")
    }
}

#Preview {
    WatchMoodPicker(onSaved: { })
}
