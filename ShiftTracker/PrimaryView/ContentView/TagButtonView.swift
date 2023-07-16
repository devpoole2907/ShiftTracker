//
//  TagButtonView.swift
//  ShiftTracker
//
//  Created by James Poole on 11/07/23.
//

import SwiftUI
import CoreData

struct TagButtonView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: ContentViewModel
    @FetchRequest(sortDescriptors: []) private var tags: FetchedResults<Tag>
    
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .center) {
            ForEach(chunks(of: Array(tags), size: 3), id: \.self) { row in
                HStack {
                    ForEach(row, id: \.self) { tag in
                        Button(action: {
                            if let tagId = tag.tagID {
                                if viewModel.selectedTags.contains(tagId) {
                                    viewModel.selectedTags.remove(tagId)
                                } else {
                                    viewModel.selectedTags.insert(tagId)
                                }
                            }
                        }) {
                            Text("#\(tag.name ?? "")")
                                .bold()
                                
                        }
                        .buttonStyle(.bordered)
                        .tint(Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue, opacity: 1.0))
                        .opacity(viewModel.selectedTags.contains(tag.tagID!) ? 1 : 0.5)
                       
                    }
                }
            }
        }
    }
    
    // Function to split the array into chunks
    private func chunks(of array: [Tag], size: Int) -> [[Tag]] {
            stride(from: 0, to: array.count, by: size).map {
                Array(array[$0 ..< min($0 + size, array.count)])
            }
        }
    
    
    
    
}
