//
//  AppleAuthView.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//


import SwiftUI
import AuthenticationServices



struct AppleAuthView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        VStack(spacing: 12) {
            
            
            SignInWithAppleButton(.signIn) { request in
                auth.prepareAppleRequest(request)
            } onCompletion: { result in
                Task {
                    await auth.handleAppleCompletion(result)
                }
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
