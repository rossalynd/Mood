//
//  EmailPasswordAuthView.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//


import SwiftUI

struct EmailPasswordAuthView: View {
    @EnvironmentObject var auth: AuthService

    enum Mode: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Create Account"
    }

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 12) {
            

            Picker("", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            SecureField("Password", text: $password)
                .textContentType(mode == .signUp ? .newPassword : .password)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                Task {
                    let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    let p = password
                    if mode == .signIn {
                        await auth.emailSignIn(email: e, password: p)
                    } else {
                        await auth.emailCreateAccount(email: e, password: p)
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    Text(mode.rawValue)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(auth.isLoading || email.isEmpty || password.isEmpty)
        }
    }
}
