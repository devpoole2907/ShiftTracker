//
//  LockedView.swift
//  ShiftTracker
//
//  Created by James Poole on 22/03/23.
//
import SwiftUI

// MARK: - Locked View
struct LockedView: View {
    
    // MARK: - Variables
    
    @EnvironmentObject var securityController: SecurityController
    
    // MARK: - Body
    
    var body: some View {
        Button("Unlock") {
            securityController.authenticate()
        }
    }
}

// MARK: - Preview
struct LockedView_Previews: PreviewProvider {
    static var previews: some View {
        LockedView()
    }
}

