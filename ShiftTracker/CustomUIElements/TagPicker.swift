//
//  TagPicker.swift
//  ShiftTracker
//
//  Created by James Poole on 25/07/23.
//

import SwiftUI

struct TagPicker: View {
    
    @FetchRequest(sortDescriptors: []) private var tags: FetchedResults<Tag>
    
    @Binding var selectedTags: Set<Tag>
    
    init(_ selectedTags: Binding<Set<Tag>>){
        _selectedTags = selectedTags
    }
    
    var body: some View {
        VStack(alignment: .center) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                                ForEach(tags, id: \.self) { tag in
                                    Button(action: {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    }) {
                                        Text("#\(tag.name ?? "")")
                                            .bold()
                                            .font(.system(size: 15))
                                            .fontDesign(.rounded)
                                            //.frame(maxWidth: tag.name?.lowercased() == "overtime" ? 100 : .infinity)
                                            .frame(width: 75)
                                        
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue, opacity: selectedTags.contains(tag) ? 1.0 : 0.5))
                                    
                                }
                            }
                     
                            .haptics(onChangeOf: selectedTags, type: .soft)
        }
    }
}


