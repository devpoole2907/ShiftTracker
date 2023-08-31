//
//  GlassModifier.swift
//  ShiftTracker
//
//  Created by James Poole on 31/08/23.
//

import SwiftUI

struct GlassModifier: ViewModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    private let cornerRadius: CGFloat
    private let applyModifier: Bool
    private let applyPadding: Bool
    private let darker: Bool
    private let padding: Double
    
    private let lightGradientColors = [
        Color.white.opacity(0.3),
        Color.white.opacity(0.1),
        Color.white.opacity(0.1),
        Color.white.opacity(0.4),
        Color.white.opacity(0.5),
    ]
    
    private let darkGradientColors = [
        Color.gray.opacity(0.2),
        Color.gray.opacity(0.1),
        Color.gray.opacity(0.1),
        Color.gray.opacity(0.3),
        Color.gray.opacity(0.2),
    ]
    
    init(_ cornerRadius: CGFloat = 16, applyModifier: Bool = false, applyPadding: Bool = true, darker: Bool = false, padding: Double = 5) {
        self.cornerRadius = cornerRadius
        self.applyModifier = applyModifier // optionally we can pass this a boolean, to determine whether to apply the modifier or not (e.g detailview being presented as a sheet or not boolean, we dont want to apply glass if its not a sheet)
        self.applyPadding = applyPadding
        self.darker = darker
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        
        let gradientColors = colorScheme == .dark ? darkGradientColors : lightGradientColors
        
        
        if applyModifier {
            content.background{
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(darker ? Material.thinMaterial : Material.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(LinearGradient(colors: gradientColors,
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing), lineWidth: 1.0)
                
                
            }
            
            .padding(.horizontal, applyPadding ? padding : 0)
            
        } else {
            content
                .background(Color("SquaresColor"),in:
                                RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        
    }
    
    
}

extension View {
    func glassModifier(cornerRadius: CGFloat = 12, applyModifier: Bool = true, applyPadding: Bool = true, darker: Bool = false, padding: Double = 5) -> some View {
        self.modifier(GlassModifier(cornerRadius, applyModifier: applyModifier, applyPadding: applyPadding, darker: darker))
    }
}
