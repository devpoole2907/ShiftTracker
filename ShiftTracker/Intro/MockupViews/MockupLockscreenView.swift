//
//  MockupLockscreenView.swift
//  ShiftTracker
//
//  Created by James Poole on 24/09/23.
//

import SwiftUI

struct MockupLockscreenView: View {
    
    @State private var switchView: Bool = true
    
    var body: some View {
     
            VStack(spacing: 0) {
         
                VStack(spacing: 0){
                    HStack {
                        RoundedRectangle(cornerRadius: 4).frame(width: 60, height: 10)
                        if switchView {
                            Text("$42.65").bold().font(.subheadline)
                        } else {
                            Text("No current shift").bold().font(.subheadline)
                        }
                        
                    }
                    Text("9:41").bold()
                        .font(.system(size: 72))
                    
                    //.font(.largeTitle)
                   
                    
                }
                HStack(spacing: 20) {
                    
                    if switchView {
                        
                        VStack(alignment: .leading){
                            Text("Shift Duration:")
                            Text(Date().addingTimeInterval(-400), style: .timer)
                        } .font(.caption)
                            .bold()
                            .padding(5).background(.ultraThinMaterial).cornerRadius(5)
                        
                        VStack(alignment: .leading){
                            Text("Current Pay:")
                            Text("$42.65")
                        } .font(.caption)
                            .bold()
                            .padding(5).background(.ultraThinMaterial).cornerRadius(5)
                        
                    } else {
                        
                        
                        Text("No current shift")
                            .font(.caption)
                            .bold()
                            .padding(5).background(.ultraThinMaterial).cornerRadius(5)
                        
                        
                        Text("No current shift")
                            .font(.caption)
                            .bold()
                            .padding(5).background(.ultraThinMaterial).cornerRadius(5)
                        
                    }
                    
                }
                
            }     .foregroundStyle(.gray)
        
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
            
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
                            withAnimation {
                                switchView.toggle()
                            }
                        }
                    }
        
        
    }
}

#Preview {
    MockupLockscreenView()
}
