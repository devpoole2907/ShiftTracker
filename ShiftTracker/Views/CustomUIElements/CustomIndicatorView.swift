//
//  CustomIndicatorView.swift
//  ShiftTracker
//
//  Created by James Poole on 29/04/23.
//

import SwiftUI

struct CustomIndicatorView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var totalPages: Int
    var currentPage: Int
    var inActiveTint: Color = Color.gray.opacity(0.5)
    
    
    var body: some View {
        
        let activeTint: Color = colorScheme == .dark ? Color.white : Color.black
        
        HStack(spacing: 8){
            ForEach(0..<totalPages, id: \.self){
                Circle()
                .fill(currentPage == $0 ? activeTint : inActiveTint)
                .frame(width: 4, height: 4)
            }
        }
    }
}

