//
//  MockupLockscreenView.swift
//  ShiftTracker
//
//  Created by James Poole on 24/09/23.
//

import SwiftUI

struct MockupLockscreenView: View {
    var body: some View {
     
            VStack(spacing: 0) {
         
                VStack(spacing: 0){
                    HStack {
                        RoundedRectangle(cornerRadius: 4).frame(width: 60, height: 10)
                        
                        Text("$42.65").bold().font(.subheadline)
                        
                    }
                    Text("9:41").bold()
                        .font(.system(size: 72))
                    
                    //.font(.largeTitle)
                   
                    
                }
                HStack(spacing: 20) {
                    VStack(alignment: .leading){
                        Text("Shift Duration:")
                        Text(Date(), style: .timer)
                    } .font(.caption)
                        .bold()
                        .padding(5).background(.ultraThinMaterial).cornerRadius(5)
                    
                    Text("No current shift")
                        .font(.caption)
                        .bold()
                        .padding(5).background(.ultraThinMaterial).cornerRadius(5)
                    
                }
                
            }     .foregroundStyle(.gray)
            
        
        
    }
}

#Preview {
    MockupLockscreenView()
}
