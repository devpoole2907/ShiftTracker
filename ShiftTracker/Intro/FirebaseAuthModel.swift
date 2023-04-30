//
//  FirebaseAuthModel.swift
//  ShiftTracker
//
//  Created by James Poole on 29/04/23.
//

import Foundation
import SwiftUI
import Firebase
import CryptoKit
import AuthenticationServices
import FirebaseAuth

class FirebaseAuthModel: ObservableObject {
    @Published var userIsLoggedIn: Bool = false
    
    fileprivate var currentNonce: String?
    private var handle: AuthStateDidChangeListenerHandle?

    func checkUserLoginStatus() {
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            self.userIsLoggedIn = user != nil
            print("User login status changed. Logged in: \(self.userIsLoggedIn)")
        }
    }


    func stopListening() {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            userIsLoggedIn = false
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    // apple sign in stuff
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }

    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest){
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
        
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>){
        if case .failure(let failure) = result {
            print(failure.localizedDescription)
        }
        else if case .success(let success) = result {
            if let appleIDCredential = success.credential as? ASAuthorizationAppleIDCredential{
                guard let nonce = currentNonce else {
                    fatalError("Invalid state")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("unable to fetch id token")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("some shit went wrong")
                    return
                }
                
                let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
                
                Task {
                    do {
                        let result = try await Auth.auth().signIn(with: credential)
                    } catch {
                        print("error signing in with apple")
                    }
                }
                
            }
        }
    }

    
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
      }

      return String(nonce)
    }
    
    // anon sign in stuff
    
    func signInAnonymously() {
        Auth.auth().signInAnonymously { (authResult, error) in
            if let error = error {
                print("Error signing in anonymously: \(error.localizedDescription)")
                return
            }

            // Successful anonymous sign in
            print("Signed in anonymously")
        }
    }

        
    
}
