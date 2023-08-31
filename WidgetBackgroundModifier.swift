//
//  WidgetBackgroundModifier.swift
//  ShiftTracker
//
//  Created by James Poole on 31/08/23.
//

import SwiftUI

struct WidgetBackgroundModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        
        if #available(iOS 17.0, *) {
            content
                .containerBackground(.ultraThinMaterial, for: .widget)
        } else {
            content
            .padding(.horizontal, 5)
    
            .padding(.vertical, 15)
        
        }
        
        
    }
}


extension View {
    func widgetBackgroundModifier() -> some View {
        self.modifier(WidgetBackgroundModifier())
    }
}
