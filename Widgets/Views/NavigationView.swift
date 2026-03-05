//
//  NavigationView.swift
//  Widgets
//
//  Created by Rosie on 3/3/26.
//

import Foundation
import SwiftUI

// MARK: - Home Routes (push full-screen inside the same NavigationStack)
enum HomeRoute: Hashable {
    case logMood
    case settings
    case profile
    case insights
    case friends
}

// MARK: - App Tabs (custom glass tab bar)
enum MoodTab: Hashable, CaseIterable {
    case home, insights, friends, profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .insights: return "Insights"
        case .friends: return "Friends"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .insights: return "chart.line.uptrend.xyaxis"
        case .friends: return "person.2.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

// MARK: - Root Shell (NavigationStack + custom glass tab bar)
@available(iOS 26.0, *)
struct RootShellView: View {
    @State private var path = NavigationPath()
    @State private var selectedTab: MoodTab = .home
    @State private var showAddMood = false

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                ZStack(alignment: .bottom) {
                    
                    // The currently selected tab content
                    tabContent
                        .padding(.top, 50)
                        .overlay(alignment: .bottom) {
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .black.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(maxWidth: .infinity, maxHeight: 30)
                        }
                    
                    ZStack {
                        GlassTabBar(selected: $selectedTab) { tab in
                            
                            if tab == selectedTab {
                                
                                if !path.isEmpty { path.removeLast(path.count) }
                            } else {
                                selectedTab = tab
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 40)
                        
                        
                            
                            
                    }
                    .shadow(radius: 10)
                    
                    
                }
                .ignoresSafeArea()
                
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .logMood:
                        AddMoodView()
                    case .settings:
                        SettingsView()
                    case .profile:
                        ProfileView(path: $path)
                    case .insights:
                        InsightsView(path: $path)
                    case .friends:
                        FriendsView(path: $path)
                    }
                }
            }
            
            
        }
        
        
        
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView(path: $path, selectedTab: $selectedTab, showAddMood: $showAddMood)
        case .insights:
            InsightsView(path: $path)
        case .friends:
            FriendsView(path: $path)
        case .profile:
            ProfileView(path: $path)
        }
    }
    
    
}


@available(iOS 26.0, *)
#Preview {
    RootShellView()
        .environmentObject(HealthKitMoodStore())
        .environmentObject(DeepLinkRouter())
}
