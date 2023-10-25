//
//  MockupContinueView.swift
//  ShiftTracker
//
//  Created by James Poole on 25/10/23.
//

import SwiftUI

struct MockupContinueView: View {
    var body: some View {
        
        VStack(alignment: .center, spacing: 10){
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 100)
                .bold().foregroundStyle(Color.gray)
                .padding(.top)
            
            Text("BETA")
                .bold()
                .font(.title3)
                .roundedFontDesign()
                
                .multilineTextAlignment(.center)
            Text("Please be aware this is a preview build and features may not be reflective of the final release.")
                .multilineTextAlignment(.center)
                .roundedFontDesign()
                .font(.callout)
                .padding(.bottom, 5)

        }
            .padding()
            .glassModifier(cornerRadius: 20)
            .padding(.horizontal, 40)
        
    }
}

#Preview {
    MockupContinueView()
}
