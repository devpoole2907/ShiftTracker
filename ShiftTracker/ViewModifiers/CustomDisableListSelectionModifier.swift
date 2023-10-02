//
//  CustomDisableListSelectionModifier.swift
//  ShiftTracker
//
//  Created by James Poole on 2/10/23.
//

import SwiftUI

struct CustomDisableListSelectionModifier: ViewModifier {
    
    var disabled: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *){
            content.selectionDisabled(disabled)
        } else {
            content // just allow selection on ios 16, not as clean but still will be undeletable
        }
    }
    
}

extension View {
    func customDisableListSelection(disabled: Bool) -> some View{
        self.modifier(CustomDisableListSelectionModifier(disabled: disabled))
    }
}
