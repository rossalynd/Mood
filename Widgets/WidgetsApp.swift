//
//  WidgetsApp.swift
//  Widgets
//
//  Created by Rosie on 2/14/26.
//

import SwiftUI
import SwiftData

@available(iOS 26.0, *)
@main
struct WidgetsApp: App {
    @StateObject private var moodStore = HealthKitMoodStore()
    @StateObject private var router = DeepLinkRouter()

    var body: some Scene {
        WindowGroup {
           RootShellView()
                .environmentObject(moodStore)
                .environmentObject(router)
                .onOpenURL { url in
                    if url.scheme == "moodwidget", url.host == "addMood" {
                        router.openAddMood = true
                    }
                }

        }
    }
}

import SwiftUI

final class DeepLinkRouter: ObservableObject {
    @Published var openAddMood = false
}

