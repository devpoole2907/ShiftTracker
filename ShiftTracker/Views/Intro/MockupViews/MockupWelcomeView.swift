//
//  MockupWelcomeView.swift
//  ShiftTracker
//
//  Created by James Poole on 25/10/23.
//

import SwiftUI

struct MockupWelcomeView: View {
    
    var body: some View {
        
        ZStack(alignment: .bottomTrailing){
            Image(systemName: "hourglass")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .scaledToFit()
                .opacity(0.8)
            
            
            Image(systemName: "deskclock.fill")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .scaledToFit()
                .offset(x: 50)
                .offset(y: 75)
                .frame(width: 160, height: 250)
              
        }
        .frame(maxWidth: 200)
        .frame(maxHeight: 200)
            .foregroundStyle(.gray)
        
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
    }
}

#Preview {
    MockupWelcomeView()
}
