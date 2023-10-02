//
//  CustomListSectionSpacingModifier.swift
//  ShiftTracker
//
//  Created by James Poole on 2/10/23.
//

import SwiftUI

struct CustomListSectionSpacingModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *){
            content.listSectionSpacing(.compact)
        } else {
            content
        }
    }
}

extension View {
    
    func customSectionSpacing() -> some View {
        self.modifier(CustomListSectionSpacingModifier())
    }
    
}
