//
//  TabBarView.swift
//  ShiftTracker
//
//  Created by James Poole on 21/03/23.
//

import SwiftUI

struct TabBarView: View {
    var tabbarItems: [String]
 
    @State var selectedIndex = 0
 
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(tabbarItems.indices, id: \.self) { index in
 
                        Text(tabbarItems[index])
                            .font(.subheadline)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .foregroundColor(selectedIndex == index ? .white : .black)
                            .background(Capsule().foregroundColor(selectedIndex == index ? .purple : .clear))
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    selectedIndex = index
                                }
                            }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(25)
 
        }
 
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
 
        TabBarView(tabbarItems: [ "Random", "Travel", "Wallpaper", "Food", "Interior Design" ]).previewDisplayName("TabBarView")
    }
}
