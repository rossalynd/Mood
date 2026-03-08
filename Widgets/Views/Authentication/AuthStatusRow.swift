//
//  AuthStatusRow.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//


import SwiftUI

struct AuthStatusRow: View {
    let isLoading: Bool
    let errorMessage: String?
    let successMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Working…")
                        .foregroundStyle(.secondary)
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            if let successMessage {
                           Text(successMessage)
                               .font(.subheadline)
                               .foregroundStyle(.green)
                               .frame(maxWidth: .infinity, alignment: .leading)
                       }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
