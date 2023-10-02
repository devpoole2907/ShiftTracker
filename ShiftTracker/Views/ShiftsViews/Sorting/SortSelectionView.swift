//
//  SortSelectionView.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import SwiftUI

struct SortSelectionView: View {
    
    
    
    @Binding var selectedSortItem: ShiftNSSort
    let sorts: [ShiftNSSort]
    
    var body: some View {
        Menu {
            
            Picker("Sort", selection: $selectedSortItem){
                ForEach(sorts, id: \.self) { sort in
                    
                    Text("\(sort.name)")
                    
                }
            }
            
            
        } label: {
            
            Image(systemName: "line.horizontal.3.decrease.circle").bold()
            
        
            
        }.customAnimatedSymbol(value: $selectedSortItem)
    }
}
