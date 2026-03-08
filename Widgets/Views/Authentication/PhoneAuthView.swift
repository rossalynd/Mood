//
//  PhoneAuthView.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//


import SwiftUI

struct PhoneAuthView: View {
    @EnvironmentObject var auth: AuthService

    @State private var phoneNumber = ""
    @State private var code = ""

    var isAwaitingCode: Bool { auth.phoneVerificationID != nil }
    
    private func normalizeToE164(_ raw: String, defaultCountryCode: String = "+1") -> String? {
        // Keep '+' and digits; everything else is removed.
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let filtered = raw.unicodeScalars.filter { allowed.contains($0) }
        var cleaned = String(String.UnicodeScalarView(filtered))
        
        // If it doesn't start with '+', assume default country code.
        if !cleaned.hasPrefix("+") {
            // Remove any non-digits and prepend default country code
            let digitsOnly = cleaned.filter { $0.isNumber }
            guard !digitsOnly.isEmpty else { return nil }
            cleaned = defaultCountryCode + digitsOnly
        } else {
            // Already starts with '+': strip any non-digits after '+'
            let plus = "+"
            let digits = cleaned.dropFirst().filter { $0.isNumber }
            cleaned = plus + digits
        }
        
        // Basic sanity: E.164 length is max 15 digits after '+'
        let digitsCount = cleaned.dropFirst().count
        guard digitsCount >= 8 && digitsCount <= 15 else {
            return nil
        }
        return cleaned
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                

                if isAwaitingCode {
                    Button("Start over") {
                        auth.resetPhoneFlow()
                        code = ""
                    }
                    .font(.subheadline)
                }
            }

            if !isAwaitingCode {
                TextField("Phone number (e.g. +1 207…)", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    Task {
                        let raw = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let e164 = normalizeToE164(raw) {
                            print(e164)
                            await auth.startPhoneVerification(phoneNumber: e164)
                        } else {
                            // You might expose an error via AuthService or show a local alert/toast
                            // For now you could log or set a local state error.
                            
                            print("Invalid phone number format")
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Send code").fontWeight(.semibold)
                        Spacer()
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(auth.isLoading || phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            } else {
                TextField("6-digit code", text: $code)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    Task {
                        let c = code.trimmingCharacters(in: .whitespacesAndNewlines)
                        await auth.confirmPhoneCode(c)
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Verify").fontWeight(.semibold)
                        Spacer()
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(auth.isLoading || code.trimmingCharacters(in: .whitespacesAndNewlines).count < 4)
            }
        }
    }
}
