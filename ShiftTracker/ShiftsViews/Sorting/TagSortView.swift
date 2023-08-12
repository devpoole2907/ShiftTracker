//
//  TagSortView.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import SwiftUI

struct TagSortView: View {
    
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Tag.tagID, ascending: true)
        ]
    )
    private var tags: FetchedResults<Tag>
    
    @Binding var selectedFilters: Set<TagFilter>
    

    var body: some View {
        
        let filters = TagFilter.filters(from: Array(tags))
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(filters, id: \.self) { filter in
                    Button(action: {
                        if self.selectedFilters.contains(filter) {
                            self.selectedFilters.remove(filter)
                        } else {
                            self.selectedFilters.insert(filter)
                        }
                    }) {
                        Text("\(filter.name)")
                            .bold()
                            .frame(minWidth: 0, maxWidth: .infinity)

                       
                    }
                    .buttonStyle(.bordered)
                    .tint(filter.color)
                    .opacity(selectedFilters.contains(filter) ? 1.0 : 0.5)
                }
            }
            .padding()
        }
    }
}
