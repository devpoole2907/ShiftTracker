//
//  ThemeColorPicker.swift
//  testEnvironment
//
//  Created by Louis Kolodzinski on 4/07/23.
//

import SwiftUI

struct ThemeColorPicker: View {
    
    @Binding var selectedColor: Color
    @State private var selectedColorScale: CGFloat = 1.0
    
    let jobColors = [
        Color.pink, Color.green, Color.blue, Color.purple, Color.orange, Color.cyan]
    var body: some View {
    HStack(spacing: 0){
        ForEach(1...6, id: \.self) { index in
            let color = jobColors[index - 1]
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay(content: {
                    if color == selectedColor{
                        Image(systemName: "circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption.bold())
                    }
                })
                .scaleEffect(color == selectedColor ? selectedColorScale : 1.0)
                .onTapGesture {
                    withAnimation{
                        selectedColor = color
                        selectedColorScale = 1.1
                    }
                }
                .frame(maxWidth: .infinity)
        }
        Divider()
            .frame(height: 20)
            .padding(.leading)
        ColorPicker("", selection: $selectedColor, supportsOpacity: false)
            .padding()
    }
    .glassModifier(cornerRadius: 20, darker: true)
   
    .padding(.horizontal)
   
    
}
}
struct CustomColorPickView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeColorPicker(selectedColor: .constant(.blue))
    }
}
