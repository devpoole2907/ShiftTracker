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
                .padding(.vertical, 22)
                .padding(.horizontal, 8)
               
        
        }
        
        
    }
}


extension View {
    func widgetBackgroundModifier() -> some View {
        self.modifier(WidgetBackgroundModifier())
    }
}
