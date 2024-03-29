//
//  ActionView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//

import SwiftUI
import Haptics

struct ActionButtonView: View {
    
    @State private var isActionButtonTapped = false
    let title: String
    let backgroundColor: Color
    let textColor: Color
    let icon: String
    let buttonWidth: CGFloat
    let action: () -> Void


    var body: some View {
        Button(action: {
            isActionButtonTapped.toggle()
            action()
        }) {
            VStack(spacing: 10) {
                Image(systemName: icon).customAnimatedSymbol(value: $isActionButtonTapped)
                   .foregroundColor(textColor)
                Text(title)
                    .font(.subheadline)
                    .bold()
                  //  .foregroundColor(textColor)
            }
            .padding(.horizontal, 25)
            .frame(maxWidth: buttonWidth)
            .padding(.vertical, 8)
            .glassModifier(cornerRadius: 20, darker: true)
        }.haptics(onChangeOf: isActionButtonTapped, type: .success)
            .buttonStyle(.scale)
            .listRowBackground(Color.clear)
    }
}
