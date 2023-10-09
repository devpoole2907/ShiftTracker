//
//  CustomSearchableModifier.swift
//  ShiftTracker
//
//  Created by James Poole on 9/10/23.
//

import SwiftUI

struct CustomSearchableModifier: ViewModifier { //do not use, has issues in nav bar "zooming"
    
    @Binding var searchText: String
    @Binding var isPresented: Bool
    var prompt: String

    
    func body(content: Content) -> some View {
        
        if #available(iOS 17.0, *) {
            content.searchable(text: $searchText, isPresented: $isPresented, prompt: prompt)
            
            
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            isPresented.toggle()
                        }){
                            Image(systemName: "magnifyingglass").bold()
                        }
                        
                    }
                }
            
        } else {
            content.searchable(text: $searchText, prompt: prompt)
        }
    }
    
    
}

extension View {
    func customSearchable(searchText: Binding<String>, isPresented: Binding<Bool>, prompt: String) -> some View {
        self.modifier(CustomSearchableModifier(searchText: searchText, isPresented: isPresented, prompt: prompt))
    }
}
