//
//  SelectableButton.swift
//  ShiftTracker
//
//  Created by Louis Kolodzinski on 9/07/23.
//

import SwiftUI

struct SelectableButton<Content: View>: View {
    let id: Int
    let content: Content
    let action: () -> Void
    @Binding var selectedButton: Int?
     var showDetail = false
    
    init(id: Int, selectedButton: Binding<Int?>, @ViewBuilder content: () -> Content, action: @escaping () -> Void){
        
        self.id = id
        self.content = content()
        self._selectedButton = selectedButton
        self.action = action
        
        
    }
    
    
    var body: some View {
        
        Button(action: {
            
            action()
            
            self.selectedButton = self.id
        }) {
            content.opacity(selectedButton == id ? 1 : 0.5)
        }.buttonStyle(.bordered)
            .tint(.gray.opacity(0.5))
            .cornerRadius(12, antialiased: true)
            .scaleEffect(showDetail ? 1.5 : 1)
            .animation(.spring(), value: showDetail)
           
            
        
        
        
    }
    
    
    
    
    
}
