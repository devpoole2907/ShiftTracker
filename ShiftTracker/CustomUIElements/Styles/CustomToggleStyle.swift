//
//  OrangeToggleStyle.swift
//  ShiftTracker
//
//  Created by James Poole on 2/04/23.
//

import Foundation
import SwiftUI

struct CustomToggleStyle: ToggleStyle {
    
    @EnvironmentObject var themeColors: ThemeDataManager
    
    @Environment(\.isEnabled) var isEnabled
    
    @Environment(\.colorScheme) var colorScheme

    
    func makeBody(configuration: Configuration) -> some View {
        
         let lightGradientColors = [
            Color.white.opacity(0.3),
            Color.white.opacity(0.1),
            Color.white.opacity(0.1),
            Color.white.opacity(0.4),
            Color.white.opacity(0.5),
        ]
        
         let darkGradientColors = [
            Color.gray.opacity(0.2),
            Color.gray.opacity(0.1),
            Color.gray.opacity(0.1),
            Color.gray.opacity(0.3),
            Color.gray.opacity(0.2),
        ]
        
        let tickColor: Color = colorScheme == .dark ? .black : .black
        
        let gradientColors = colorScheme == .dark ? darkGradientColors : lightGradientColors
        
        HStack {
            configuration.label
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(configuration.isOn ? themeColors.customUIColor : Color.gray.opacity(0.25))
                    .frame(width: 48, height: 28)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: -2, y: -2)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(width: 48, height: 28)
                    .overlay {
                        //if colorScheme == .light {
                            RoundedRectangle(cornerRadius: 15)
                             .stroke(LinearGradient(colors: gradientColors,
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing))
                       // }
                    }
                
                Circle()
                    .fill(Color.white)
                    .padding(.all, 3)
                    .frame(width: 48, height: 28)
                    .overlay(
                        Image(systemName: configuration.isOn ? "checkmark" : "")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .font(Font.title.weight(.black))
                            .frame(width: 8, height: 8, alignment: .center)
                            .foregroundStyle(configuration.isOn ? tickColor : Color.gray.opacity(0.25))
                    )
                    .offset(x: configuration.isOn ? 10 : -10, y: 0)
                    .animation(Animation.linear(duration: 0.2))
                    .opacity(isEnabled ? 1.0 : 0.5)
            }
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }

}


