//
//  ScaleButtonStyle.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import SwiftUI

public struct ScaleButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.65 : 1)
            .brightness(configuration.isPressed ? -0.35 : 0)
       
        
            .animation(.easeInOut(duration: 0.6), value: configuration.isPressed)
            
    }
}

public extension ButtonStyle where Self == ScaleButtonStyle {
    static var scale: ScaleButtonStyle {
        ScaleButtonStyle()
    }
}
