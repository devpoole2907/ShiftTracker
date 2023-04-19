//
//  TabBottomView.swift
//  ShiftTracker
//
//  Created by James Poole on 29/03/23.
//

import SwiftUI

struct TabBottomView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let tabbarItems: [TabItemData]
    var height: CGFloat = 85
    @Binding var selectedIndex: Int
    
    var body: some View {
               let backgroundColor: Color = colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : .white
        //let width: CGFloat = horizontalSizeClass == .regular ? UIScreen.main.bounds.width - 32 : UIScreen.main.bounds.width
        //AGIAIN WHO THE FUCKI KNOWD WHY THIS DOESNT FUCKEN WORK ANYMROE!!?@?@?!
        let width: CGFloat = UIScreen.main.bounds.width - 32
        
        HStack {
            Spacer()
            
            ForEach(tabbarItems.indices) { index in
                let item = tabbarItems[index]
                Button {
                    self.selectedIndex = index
                } label: {
                    let isSelected = selectedIndex == index
                    TabItemView(data: item, isSelected: isSelected)
                }//.foregroundColor(.white)
                Spacer()
            }
        }
        .frame(width: width, height: height)
        //.background(backgroundColor)
        //.cornerRadius(horizontalSizeClass == .regular ? 20 : 0) //WHO THE FUCK KNOWS WHY THIS DOESNT FUCKING WORK ANYMORE!?!?!?!??!?!?!?!
        .cornerRadius(12)
        //.shadow(radius: 5, x: 0, y: 4)
    }
}



struct TabBarBottomView_Previews: PreviewProvider {
    static var previews: some View {
        TabBottomView(tabbarItems: [
            TabItemData(image: "HomeIconFinal", selectedImage: "HomeIconFinal", title: "Home", selectedColor: .blue)], selectedIndex: .constant(0))
    }
}
