//
//  LockedView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/05/23.
//

import SwiftUI
import LocalAuthentication

struct LockedView: View {
    @Binding var isAuthenticated: Bool
    
    @Environment(\.colorScheme) var colorScheme

    private func authenticateUser() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock ShiftTracker"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        isAuthenticated = false
                    } else {
                        // Handle the authentication error here if needed
                    }
                }
            }
        } else {
            // Handle the case where biometric authentication is not available
        }
    }

    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .black : .white
        
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.largeTitle)
            
            Text("ShiftTracker is locked.")
                .font(.title)
                .bold()
                .padding(.bottom, 20)
            Spacer()
            Button(action: {
                authenticateUser()
            }) {
                Text("Unlock")
                    .font(.title)
                    .bold()
                    .frame(maxWidth: UIScreen.main.bounds.width - 80)
                    
            }
            .padding()
            .foregroundColor(textColor)
                .bold()
                .background(Color.accentColor)
                .cornerRadius(20)
        }.onAppear{
            authenticateUser()
        }
    }
}

struct LockedView_Previews: PreviewProvider {
    static var previews: some View {
        LockedView(isAuthenticated: .constant(true))
    }
}
