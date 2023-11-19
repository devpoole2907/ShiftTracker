//
//  CustomEditButton.swift
//  ShiftTracker
//
//  Created by James Poole on 19/11/23.
//

import Foundation
import SwiftUI

// custom edit button which can also be passed an action and uses the editmode environment variable

struct CustomEditButton: View {
    @Binding var editMode: EditMode
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation {
                editMode = (editMode == .active) ? .inactive : .active
                
                
                action()
            }
        }) {
            Text(editMode == .active ? "Done" : "Edit")
        }
    }
}
