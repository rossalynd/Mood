//
//  RootView.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//


import SwiftUI
import WidgetKit
import Foundation

import SwiftUI
import WidgetKit
import Foundation

struct RootView: View {
    @StateObject private var session = SessionStore()
    @StateObject private var profile = ProfileStore()
    @StateObject private var moodStore = HealthKitMoodStore()
    @StateObject private var router = DeepLinkRouter()
    @StateObject private var auth = AuthService()

    var body: some View {
        RootShellView()
            .environmentObject(moodStore)
            .environmentObject(router)
            .environmentObject(auth)
            .environmentObject(session)
            .environmentObject(profile)

            .onOpenURL { url in
                if url.scheme == "moodwidget", url.host == "addMood" {
                    router.openAddMood = true
                }
            }

            .onAppear {
                if let uid = session.user?.uid {
                    profile.startListening(uid: uid)
                }
            }

            .onChange(of: session.user?.uid) { oldValue, newValue in
                if let uid = newValue {
                    profile.startListening(uid: uid)
                } else {
                    profile.stopListening()
                }
            }
    }
}
