//
//  ShakeModifier.swift
//  ShiftTracker
//
//  Created by James Poole on 5/07/23.
//

import SwiftUI

struct Shake: AnimatableModifier {
    var times: CGFloat = 0
    var amplitude: CGFloat = 5
    
    var animatableData: CGFloat {
        get { times }
        set { times = newValue }
    }
    
    func body(content: Content) -> some View {
        content.offset(x: sin(times * .pi * 2) * amplitude)
    }
}

extension View {
    func shake(times: CGFloat) -> some View {
        self.modifier(Shake(times: times))
    }
}
