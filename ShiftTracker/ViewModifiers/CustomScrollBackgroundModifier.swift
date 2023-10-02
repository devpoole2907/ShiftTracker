//
//  CustomScrollBackgroundModifier.swift
//  ShiftTracker
//
//  Created by James Poole on 2/10/23.
//

import SwiftUI

// applies hidden scroll background only if in dark mode

struct CustomScrollBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        Group {
            if colorScheme == .dark {
                content.scrollContentBackground(.hidden)
            } else {
                content
            }
        }
    }
}

extension View {
    func customScrollBackgroundModifier() -> some View {
        self.modifier(CustomScrollBackgroundModifier())
    }
}
