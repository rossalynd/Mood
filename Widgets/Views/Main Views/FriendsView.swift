//
//  FriendsView.swift
//  Widgets
//
//  Created by Rosie on 3/3/26.
//
import SwiftUI
import Foundation
@available(iOS 26.0, *)
struct FriendsView: View {
    @Binding var path: NavigationPath
    var body: some View {
        ZStack {
            LiquidBackdrop().ignoresSafeArea()
            FriendSearchView()
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top) {
            HStack {
                Text("Friends").font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            .background(.thinMaterial)
            .overlay(alignment: .bottom) { Divider().opacity(0.25) }
        }
    }
}


#Preview {
    @Previewable @State var path = NavigationPath()
    FriendsView(path: $path)
}
