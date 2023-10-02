//
//  JobIconView.swift
//  ShiftTracker
//
//  Created by James Poole on 28/09/23.
//

import SwiftUI

struct JobIconView: View {
    
    var icon: String
    var color: Color
    var font: Font
    var padding: CGFloat = 10
    
    
    var body: some View {
        Image(systemName: icon)
           
            .font(font)
            
            .shadow(color: .white, radius: 0.7)
            .padding(padding)
            .foregroundStyle(Color.white)
            .background{
                Circle().foregroundStyle(color.gradient).shadow(color: color, radius: 2)
            }
    }
}

#Preview {
    JobIconView(icon: "briefcase.fill", color: Color.pink, font: .callout)
}
