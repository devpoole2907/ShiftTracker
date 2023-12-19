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
    var title: String? 
    
    init(editMode: Binding<EditMode>, action: @escaping () -> Void, title: String? = nil) {
        self._editMode = editMode
        self.action = action
        self.title = title
    }

    var body: some View {
        Button(action: {
            withAnimation {
                editMode = (editMode == .active) ? .inactive : .active
                action()
            }
        }) {
            
                if let buttonTitle = title {
                    HStack {
                        Image(systemName: "ellipsis.circle")
                        Text(buttonTitle)
                     }
                } else {
                
                Text(editMode == .active ? "Done" : "Edit")
            }
        }
    }
}
