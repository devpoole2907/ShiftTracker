//
//  SecurityController.swift
//  ShiftTracker
//
//  Created by James Poole on 22/03/23.
//

import SwiftUI
import LocalAuthentication

// MARK: - Security Controller

@MainActor
class SecurityController: ObservableObject {
    
    // MARK: - Variables
    
    var error: NSError?
    
    @Published var isLocked = false
    @Published var isAppLockEnabled: Bool = UserDefaults.standard.object(forKey: "isAppLockEnabled") as? Bool ?? false
    
}

extension SecurityController {
    
    func authenticate() {
        let context = LAContext()
        let reason = "Authenticate yourself to unlock Locker"
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                Task { @MainActor in
                    if success {
                        self.isLocked = false
                    }
                }
            }
        }
    }
    
}

extension SecurityController {
    
    func appLockStateChange(_ isEnabled: Bool) {
        let context = LAContext()
        let reason = "Authenticate to toggle App Lock"
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                Task { @MainActor in
                    if success {
                        self.isLocked = false
                        self.isAppLockEnabled = isEnabled
                        UserDefaults.standard.set(self.isAppLockEnabled, forKey: "isAppLockEnabled")
                    }
                }
            }
        }
    }
        
}

extension SecurityController {
    
    func showLockedViewIfEnabled() {
        if isAppLockEnabled {
            isLocked = true
            authenticate()
        } else {
            isLocked = false
        }
    }
    
    func lockApp() {
        if isAppLockEnabled {
            isLocked = true
        } else {
            isLocked = false
        }
    }
    
}
