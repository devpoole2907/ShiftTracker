//
//  AnimatedButton.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI

struct AnimatedButton: View {
    @Binding var isTapped: Bool
    @Binding var activeSheet: ActiveSheet?
    
    @Environment(\.colorScheme) var colorScheme
    
    var activeSheetCase: ActiveSheet
    var title: String
    var backgroundColor: Color
    var isDisabled: Bool

    var body: some View {
        
        let foregroundColor: Color = colorScheme == .dark ? .black : .white
        
        Button(action: {
            self.activeSheet = activeSheetCase
        }) {
            Text(title)
                .frame(minWidth: UIScreen.main.bounds.width / 3)
                .bold()
                .padding()
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(18)
        }
        .buttonStyle(.scale)
        .disabled(isDisabled)
        .frame(maxWidth: .infinity)
        //.scaleEffect(isTapped ? 1.1 : 1)
       // .animation(.easeInOut(duration: 0.3))
    }
}
