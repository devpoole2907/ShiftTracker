//
//  CustomTabView.swift
//  ShiftTracker
//
//  Created by James Poole on 29/03/23.
//

import SwiftUI

struct CustomTabView<Content: View>: View {
    
    let tabs: [TabItemData]
    @Binding var selectedIndex: Int
    @ViewBuilder let content: (Int) -> Content
    
    var body: some View {
        GeometryReader { geometry in
        ZStack {
            VStack{
            TabView(selection: $selectedIndex) {
                ForEach(tabs.indices) { index in
                    content(index)
                        .tag(index)
                }
            }
            Spacer()
            }
            
            VStack {
                Spacer()
                TabBottomView(tabbarItems: tabs, selectedIndex: $selectedIndex)
            }.ignoresSafeArea(.keyboard) 
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
            .padding(.bottom, 8)
        }
    }
    }
}

struct CustomTabView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTabs = [
            TabItemData(image: "HomeIconFinal", selectedImage: "HomeIconFinal", title: "Home", selectedColor: .red),
            TabItemData(image: "SettingsIconFinal", selectedImage: "SettingsIconFinal", title: "Settings", selectedColor: .blue),
        ]
        
        CustomTabView(tabs: sampleTabs, selectedIndex: .constant(0)) { index in
            switch index {
            case 0:
                Text("Home")
            case 1:
                Text("Search")
            default:
                EmptyView()
            }
        }
    }
}
