//
//  KeyboardDoneButton.swift
//  ShiftTracker
//
//  Created by James Poole on 7/10/23.
//

import SwiftUI

struct KeyboardDoneButton: View {
    var body: some View {
      
            Spacer()
            
            Button("Done"){
                hideKeyboard()
            }
        
    }
}

#Preview {
    KeyboardDoneButton()
}
