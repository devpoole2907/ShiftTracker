//
//  CustomAnimatedSymbolModifier.swift
//  ShiftTracker
//
//  Created by James Poole on 2/10/23.
//

import SwiftUI

struct CustomAnimatedSymbolModifier<U:Hashable>: ViewModifier {
    
    @Binding var value: U
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *){
            content.symbolEffect(.bounce, value: value)
        } else {
            content
        }
    }
}

extension View {
    func customAnimatedSymbol<U: Hashable>(value: Binding<U>) -> some View {
        self.modifier(CustomAnimatedSymbolModifier(value: value))
    }
}
