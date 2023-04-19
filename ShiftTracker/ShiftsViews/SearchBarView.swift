//
//  SearchBarView.swift
//  ShiftTracker
//
//  Created by James Poole on 2/04/23.
//

import SwiftUI

struct SearchBarView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    
    @Binding var text: String
    var body: some View {
        
        let searchColor: Color = colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.3)
        
      
        RoundedRectangle(cornerRadius: 10)
            .fill(searchColor)
            .frame(height: 35)
            .overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        //.padding()
                    TextField("Search", text: $text)
                }
                    .foregroundColor(.white)
                    .padding()
            )
            //.padding([.leading, .trailing], 60)
        
        
        
    }
}

struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        SearchBarView(text: .constant(""))
    }
}
