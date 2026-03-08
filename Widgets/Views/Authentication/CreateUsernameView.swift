//
//  CreateUsernameView.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//


import SwiftUI

@MainActor
struct CreateUsernameView: View {
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            Text("Choose a username")
                .font(.title2.bold())

            Text("Friends will search for you by this.")
                .foregroundStyle(.secondary)

            TextField("username", text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task {
                    errorMessage = nil
                    isLoading = true
                    defer { isLoading = false }

                    do {
                        try await UsernameService.claimUsername(username)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    if isLoading { ProgressView() }
                    Text("Continue")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(isLoading || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
}
