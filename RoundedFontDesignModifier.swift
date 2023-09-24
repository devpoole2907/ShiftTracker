//
//  RoundedFontDesignModifier.swift
//  ShiftTracker
//
//  Created by James Poole on 24/09/23.
//

import Foundation
import SwiftUI

struct CustomFontDesignModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.1, *){
            content.fontDesign(.rounded)
        } else {
            content
        }
    }
}

extension View {
    func roundedFontDesign() -> some View {
        self.modifier(CustomFontDesignModifier())
    }
}

