//
//  AuthManager.swift
//  ShiftTracker
//
//  Created by James Poole on 12/10/23.
//

import Foundation
import LocalAuthentication

struct AuthManager {

    func authenticateUser() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Unlock ShiftTracker"
                return await withCheckedContinuation { continuation in
                    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                        continuation.resume(returning: success)
                    }
                }
            } else {
                
                    return false
                
            }
    }
    
    
}
