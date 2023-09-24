//
//  CustomSegmentedPicker.swift
//  ShiftTracker
//
//  Created by James Poole on 29/08/23.
//

import SwiftUI

struct CustomSegmentedPicker<Item: SegmentedItem>: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var selection: Item
    
    var items: [Item]
    
    var cornerRadius: CGFloat = 20.0
    var borderWidth: CGFloat = 2.0
    
    var body: some View {
        
        let iconColor = colorScheme == .dark ? Color.gray : Color.black
        
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                
                if let selectedIdx = items.firstIndex(of: selection) {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .foregroundColor(.white)
                        //.padding(EdgeInsets(top: borderWidth, leading: borderWidth, bottom: borderWidth, trailing: borderWidth))
                        .frame(width: geo.size.width / CGFloat(items.count))
                        .offset(x: geo.size.width / CGFloat(items.count) * CGFloat(selectedIdx), y: 0)
                      //  .animation(.spring().speed(1.5), value: )
                       
                }
                
                HStack(spacing: 0) {
                                    ForEach(items, id: \.self) { item in
                                        Button(action: {
                                            withAnimation(.spring().speed(1.5)) {
                                                selection = item
                                            }
                                        }) {
                                            switch item.contentType {
                                            case .image(let imageName):
                                                Image(systemName: imageName)
                                                    .foregroundStyle(iconColor)
                                                    .frame(minWidth: geo.size.width / CGFloat(items.count), maxWidth: .infinity)
                                            case .text(let text):
                                                Text(text)
                                                    .bold()
                                                    .roundedFontDesign()
                                                    .font(.footnote)
                                                    .foregroundColor(iconColor)
                                                    .frame(minWidth: geo.size.width / CGFloat(items.count), maxWidth: .infinity)
                                               
                                            }
                                        
                                        }
                                    }
                                }
                                .frame(height: 30)
                                
                            }
                            .frame(maxHeight: 30)
                            
                        }
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
