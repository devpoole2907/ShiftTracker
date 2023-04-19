//
//  TabItemView.swift
//  ShiftTracker
//
//  Created by James Poole on 29/03/23.
//

import SwiftUI

struct TabItemView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let data: TabItemData
    let isSelected: Bool
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)
               let backgroundColor: Color = colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : .white
        
        VStack {
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            if data.title == "Shifts" {
                Image(isSelected ? data.selectedImage : data.image)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isSelected ? 24 : 24, height: isSelected ? 24 : 24)
                    .animation(.default)
                    .foregroundColor(isSelected ? data.selectedColor : textColor)
            }
            else {
                Image(isSelected ? data.selectedImage : data.image)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isSelected ? 25 : 25, height: isSelected ? 25 : 25)
                    .animation(.default)
                    .foregroundColor(isSelected ? data.selectedColor : textColor)
            }
            //Spacer().frame(height: 4)
            
            Text(data.title)
                .foregroundColor(isSelected ? data.selectedColor : textColor)
                .bold()
                .font(.caption)
        }.padding(.horizontal, 10)
    }
}

struct TabItemView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TabItemView(data: TabItemData(image: "HomeIconFinal", selectedImage: "SettingsIconFinal", title: "Home", selectedColor: .blue), isSelected: false)
                .previewLayout(.sizeThatFits)
                .padding()
            
            TabItemView(data: TabItemData(image: "HomeIconFinal", selectedImage: "SettingsIconFinal", title: "Home", selectedColor: .red), isSelected: true)
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}
