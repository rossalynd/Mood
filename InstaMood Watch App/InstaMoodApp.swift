//
//  InstaMoodApp.swift
//  InstaMood Watch App
//
//  Created by Rosie on 3/3/26.
//
import SwiftUI

@main
struct MoodWatchApp: App {
    
    @StateObject var moodStore = HealthKitMoodStore()
    
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(moodStore)
        }
    }
}
