//
//  RoundedSquareView.swift
//  ShiftTracker
//
//  Created by James Poole on 21/03/23.
//

import SwiftUI

struct RoundedSquareView: View {
    var text: String
    var count: String
    var color: Color
    var imageColor: Color
    var systemImageName: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        
        let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)
        let headerColor: Color = colorScheme == .dark ? .white : .black
        
        
        HStack { // added HStack to horizontally align image and text
            
            VStack(alignment: .leading){
                Image(systemName: systemImageName)
                
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                    .foregroundColor(imageColor)
                    .padding(.horizontal, 2)
                    .padding(.top, 2)
                    .dynamicTypeSize(.small)
                Spacer()
                Text(text)
                    .dynamicTypeSize(.small)
                    .foregroundColor(subTextColor)
                    .font(.headline)
                    .bold()
                    .padding(.horizontal, 2)
                    .padding(.top, 2)
                Spacer().frame(height: 1)
            }
            .padding(2)
            Spacer()
            VStack{
                Text(count)
                    .dynamicTypeSize(.small)
                    .foregroundColor(headerColor)
                    .font(.title2)
                    .bold()
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    
                Spacer()
            }
        }
        .padding(5)
        .background(color)
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
        
        
    }
}

struct RoundedSquareView_Previews: PreviewProvider {
    static var previews: some View {
        RoundedSquareView(text: "Preview Text", count: "3", color: .blue, imageColor: .orange, systemImageName: "square.and.arrow.up")
            .previewLayout(.fixed(width: 400, height: 200)) // Change the width and height as per your requirement
    }
}

