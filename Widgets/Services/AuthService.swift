//
//  AuthService.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//

@preconcurrency import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import Security
import Combine

@MainActor
final class AuthService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isSignedIn = false
    @Published var currentUser: User?
    @Published var phoneVerificationID: String?

    private var authListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isSignedIn = (user != nil)
            }
        }
    }

    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    func emailCreateAccount(email: String, password: String) async {
        errorMessage = nil
        successMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            currentUser = result.user
            isSignedIn = true
            successMessage = "Account created successfully."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func emailSignIn(email: String, password: String) async {
        errorMessage = nil
        successMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = result.user
            isSignedIn = true
            successMessage = "Signed in successfully."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        errorMessage = nil
        successMessage = nil

        do {
            try Auth.auth().signOut()
            currentUser = nil
            isSignedIn = false
            phoneVerificationID = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPhoneFlow() {
        phoneVerificationID = nil
        errorMessage = nil
        successMessage = nil
    }

    func startPhoneVerification(phoneNumber: String) async {
        errorMessage = nil
        successMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            phoneVerificationID = verificationID
            successMessage = "Verification code sent."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmPhoneCode(_ code: String) async {
        errorMessage = nil
        successMessage = nil
        isLoading = true
        defer { isLoading = false }

        guard let verificationID = phoneVerificationID else {
            errorMessage = "Missing verification session. Please start again."
            return
        }

        do {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: code
            )

            let result = try await Auth.auth().signIn(with: credential)
            currentUser = result.user
            isSignedIn = true
            phoneVerificationID = nil
            successMessage = "Phone number verified successfully."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        errorMessage = nil
        successMessage = nil

        let nonce = Self.randomNonceString()
        currentNonce = nonce

        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil
        successMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            switch result {
            case .failure(let error):
                errorMessage = error.localizedDescription

            case .success(let authorization):
                guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    errorMessage = "Unable to read Apple ID credential."
                    return
                }

                guard let nonce = currentNonce else {
                    errorMessage = "Invalid Apple sign-in state. Please try again."
                    return
                }

                guard let identityToken = appleIDCredential.identityToken else {
                    errorMessage = "Unable to fetch identity token."
                    return
                }

                guard let idTokenString = String(data: identityToken, encoding: .utf8) else {
                    errorMessage = "Unable to serialize identity token."
                    return
                }

                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName
                )

                let authResult = try await Auth.auth().signIn(with: credential)
                currentUser = authResult.user
                isSignedIn = true
                successMessage = "Signed in with Apple successfully."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension AuthService {
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        var result = ""
        result.reserveCapacity(length)

        var remainingLength = length
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed.")
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
