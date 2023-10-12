//
//  AnimatedButton.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI

struct AnimatedButton: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    
    let action: () -> Void
    var title: String
    var backgroundColor: Color
    var isDisabled: Bool

    var body: some View {
        
        Button(action: action) {
            Text(title)
                .frame(minWidth: getRect().width / 3 - 10)
                .bold()
                .padding()

        }.glassModifier(cornerRadius: 20)
        .buttonStyle(.scale)
        .disabled(isDisabled)
        .frame(maxWidth: .infinity)

    }
}
