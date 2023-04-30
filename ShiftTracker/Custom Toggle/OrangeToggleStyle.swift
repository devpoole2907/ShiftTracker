//
//  OrangeToggleStyle.swift
//  ShiftTracker
//
//  Created by James Poole on 2/04/23.
//

import Foundation
import SwiftUI

struct OrangeToggleStyle: ToggleStyle {
    
    @Environment(\.isEnabled) var isEnabled

    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .frame(width: 50, height: 30)
                .foregroundColor(configuration.isOn ? Color.accentColor : Color.gray.opacity(0.25))
                .overlay(
                    Circle()
                        .foregroundColor(.white)
                        .padding(.all, 3)
                        
                        .overlay(
                            Image(systemName: configuration.isOn ? "checkmark" : "")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .font(Font.title.weight(.black))
                                                            .frame(width: 8, height: 8, alignment: .center)
                                                            .foregroundColor(configuration.isOn ? .accentColor : .gray)
                        )
                        .offset(x: configuration.isOn ? 10 : -10, y: 0)
                        .animation(Animation.linear(duration: 0.2))
                    
                )
                .opacity(isEnabled ? 1.0 : 0.5)
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}
