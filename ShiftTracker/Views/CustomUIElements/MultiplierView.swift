//
//  MultiplierView.swift
//  ShiftTracker
//
//  Created by James Poole on 9/10/23.
//

import SwiftUI

struct MultiplierView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var payMultiplier: Double
    
    
    var body: some View {
        HStack {
            Text("x\(payMultiplier, specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(.white)
                .bold()
                .roundedFontDesign()
            
            
        }.padding(5).background {
            RoundedRectangle(cornerRadius: 8).fill(Color(colorScheme == .dark ? .systemGray5 : .systemGray))
        }
        .padding(.leading, 8)
    }
}

#Preview {
    MultiplierView(payMultiplier: .constant(1.25))
}
