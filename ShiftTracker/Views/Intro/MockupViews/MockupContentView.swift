//
//  MockupContentView.swift
//  ShiftTracker
//
//  Created by James Poole on 25/09/23.
//

import SwiftUI

struct MockupContentView: View {
    
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    var body: some View {
     
          
            
        VStack(spacing: 0) {
                Text("\(currencyFormatter.string(from: NSNumber(value: 0.00)) ?? "")") .font(.system(size: 60).monospacedDigit())
                    .fontWeight(.bold).roundedFontDesign()
                
                HStack(spacing: 2){
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 15).monospacedDigit())
                        .bold()
                   
                    RoundedRectangle(cornerRadius: 4).frame(width: 50, height: 20).opacity(0.7)
                }
                  
            HStack(alignment: .center, spacing: 3) {
                
               
                
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4).frame(width: 20, height: 20)
                    if index == 1 || index == 3 {
                        Text(":")
                            .font(.system(size: 20, weight: .bold).monospacedDigit()) .roundedFontDesign().opacity(0.5)
                    }
                }
                
            }.padding()
            
            Text("Start Shift")
                .roundedFontDesign()
                .bold()
                
                .padding(.vertical, 7)
                .padding(.horizontal, 10)
              
                .padding(5).background(.ultraThinMaterial).cornerRadius(15)
            }.foregroundStyle(.gray)
        
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
            
        
    }
}

#Preview {
    MockupContentView()
}
