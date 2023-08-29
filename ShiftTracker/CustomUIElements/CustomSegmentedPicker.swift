//
//  CustomSegmentedPicker.swift
//  ShiftTracker
//
//  Created by James Poole on 29/08/23.
//

import SwiftUI

struct CustomSegmentedPicker: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var selection: StatsMode
    var cornerRadius: CGFloat = 20.0
    var borderWidth: CGFloat = 2.0
    
    var body: some View {
        
        let iconColor = colorScheme == .dark ? Color.gray : Color.black
        
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                
                if let selectedIdx = StatsMode.allCases.firstIndex(of: selection) {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .foregroundColor(.white)
                        //.padding(EdgeInsets(top: borderWidth, leading: borderWidth, bottom: borderWidth, trailing: borderWidth))
                        .frame(width: geo.size.width / CGFloat(StatsMode.allCases.count))
                        .offset(x: geo.size.width / CGFloat(StatsMode.allCases.count) * CGFloat(selectedIdx), y: 0)
                      //  .animation(.spring().speed(1.5), value: )
                       
                }
                
                HStack(spacing: 0) {
                    ForEach(StatsMode.allCases, id: \.self) { mode in
                        Button(action: {
                            withAnimation(.spring().speed(1.5)) {
                                selection = mode
                            }
                        }) {
                            Image(systemName: mode.image)
                              
                                .foregroundStyle(iconColor)
                                .frame(minWidth: 0, maxWidth: .infinity)
                              //  .padding()
                        }
                    }
                }.frame(height: 30)
                
                
            } .frame(maxHeight: 30)
                
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
