//
//  TrailingCloseButton.swift
//  ShiftTracker
//
//  Created by James Poole on 7/10/23.
//

import SwiftUI

struct TrailingCloseButton: ViewModifier {
    
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CloseButton()
            }
        }
    }
    
}

extension View {
    func trailingCloseButton() -> some View {
        self.modifier(TrailingCloseButton())
    }
}
