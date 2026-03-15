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
            
                
                
            FriendsListView(path: $path)
                
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top) {
            HStack {
                Text("Friends").font(.headline)
                Spacer()
                Button {
                    path.append(HomeRoute.pendingFriends)
                } label: {
                    Image(systemName: "person.2")
                        .font(Font.system(size: 30))
                        .foregroundColor(.secondary)
                }
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
