//
//  StreakCountView.swift
//  Widgets
//
//  Created by Rosie on 3/4/26.
//
import SwiftUI
import HealthKit

@available(iOS 26.0, *)
struct StreakPill: View {
    @EnvironmentObject var moodStore: HealthKitMoodStore

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
            Text("\(moodStore.streak.current)")
                .font(.headline.weight(.semibold))
        }
        
        .padding(.vertical, 8)
        
    }
}

@available(iOS 26.0, *)
#Preview {
    
   StreakPill()
        .environmentObject(HealthKitMoodStore())
        .environmentObject(DeepLinkRouter())
      
}
