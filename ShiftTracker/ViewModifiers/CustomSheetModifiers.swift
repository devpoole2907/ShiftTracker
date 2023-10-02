//
//  CustomSheetModifiers.swift
//  ShiftTracker
//
//  Created by James Poole on 2/10/23.
//

import SwiftUI

struct CustomSheetBackgroundModifier: ViewModifier {
    
    var ultraThin: Bool = true
    
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationBackground(ultraThin ? .ultraThinMaterial : .thinMaterial)
        } else {
            content
        }
    }
    
    
}


extension View {
    func customSheetBackground(ultraThin: Bool = true) -> some View {
        self.modifier(CustomSheetBackgroundModifier(ultraThin: ultraThin))
    }
}

struct CustomSheetRadius: ViewModifier {
    var radius: CGFloat
    
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *){
            content.presentationCornerRadius(radius)
        } else {
            content
        }
    }
    
    
}


extension View {
    func customSheetRadius(_ radius: CGFloat = 25) -> some View {
        self.modifier(CustomSheetRadius(radius: radius))
    }
}

struct CustomSheetBackgroundInteraction: ViewModifier {
    
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *){
            content.presentationBackgroundInteraction(.enabled)
        } else {
            content
        }
    }
    
    
}

extension View {
    func customSheetBackgroundInteraction() -> some View {
        self.modifier(CustomSheetBackgroundInteraction())
    }
}

