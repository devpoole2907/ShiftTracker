//
//  AddTagView.swift
//  ShiftTracker
//
//  Created by James Poole on 11/07/23.
//

import SwiftUI
import CoreData

struct AddTagView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var tagName = ""
    @State private var tagColor = Color.white
    
    @State private var selectedTag: Tag? = nil
    
    @FetchRequest(sortDescriptors: []) private var tags: FetchedResults<Tag>
    
    var isEditing: Bool {
            selectedTag != nil
        }
        
        var buttonTitle: String {
            isEditing ? "Update Tag" : "Add Tag"
        }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                LazyVStack (alignment: .center) {
                    
                    
                    
                    // for each tag, display tag button, make only one selectable at a time
                    
                    // display in a 3 column grid, use swiftui grid built in
                    
                    //when tag is selected, it can be deleted
                    // when tag is selected, set tagName to the tags .name property
                    // tag buttons should also be able to be deleted
                    
                    
                    //TagButtonView()
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(tags, id: \.self) { tag in
                            Button(action: {
                                if selectedTag == tag {
                                                                    selectedTag = nil
                                    tagName = ""
                                    tagColor = .white
                                                                    
                                                            
                                                                } else {
                                                                    selectedTag = tag
                                                                    tagName = tag.name ?? ""
                                                                    tagColor = Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue)
                                                                }
                            }) {
                                Text("#\(tag.name ?? "")")
                                    .bold()
                            }
                            .buttonStyle(.bordered)
                            .tint(Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue, opacity: selectedTag == tag ? 1.0 : 0.5))
                        }
                        
                    }
                    .padding(10)
                    .background(Color("SquaresColor"))
                    .cornerRadius(12)
                    
                    .padding(.bottom, 30)
                    
                    HStack{
                        
                        
                        CustomTextField(text: $tagName, hint: "Add Tag", leadingIcon: Image(systemName: "number"))
                            .frame(maxHeight: 50)
                        
                        
                        ZStack{
                            Circle()
                                .foregroundStyle(Color("SquaresColor"))
                                .frame(maxHeight: 50)
                            ColorPicker("", selection: $tagColor, supportsOpacity: false)
                                .padding()
                                .labelsHidden()
                                
                        }
                    }
                    
                    HStack{
                        
                        if selectedTag != nil {
                            Button(action: {
                                guard let selectedTag = selectedTag else { return }
                                
                                deleteTag(selectedTag)
                                clearSelection()
                                
                                
                            }) {
                                
                                
                                HStack{
                                    Image(systemName: "trash")
                                    Text("Delete")
                                        .bold()
                                }
                            }.listRowSeparator(.hidden)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.red)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                        
                        
                        Button(action: {
                            
                            
                            if let selectedTag = selectedTag {
                                
                                updateTag(selectedTag)
                                clearSelection()
                            } else {
                                addTag()
                                clearSelection()
                            }
                                
                                
                            
                            
                            
                        }) {
                            Text(buttonTitle)
                                .bold()
                        }.listRowSeparator(.hidden)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(colorScheme == .dark ? .white : .black)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .cornerRadius(20)
                        
                        
                    }
                }.padding()
                
                
                
            }
            
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                
                ToolbarItem{
                    
                    CloseButton(action: {dismiss()})
                }
                ToolbarItemGroup(placement: .keyboard){
                    Spacer()
                    
                    Button("Done"){
                        
                        hideKeyboard()
                        
                    }
                }
                
            }
            
        }
        
        
        
        
    }
    
    private func addTag() {
        let newTag = Tag(context: viewContext)
        newTag.name = tagName
        newTag.tagID = UUID()
        let rgb = UIColor(tagColor).rgbComponents
        newTag.colorRed = Double(rgb.0)
        newTag.colorGreen = Double(rgb.1)
        newTag.colorBlue = Double(rgb.2)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func updateTag(_ tag: Tag){
        
        tag.name = tagName
        let tagUIColor = UIColor(tagColor)
        tag.colorRed = Double(tagUIColor.rgbComponents.0)
        tag.colorGreen = Double(tagUIColor.rgbComponents.1)
        tag.colorBlue = Double(tagUIColor.rgbComponents.2)
        
        do {
            
            try viewContext.save()
            
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
    }
    
    private func deleteTag(_ tag: Tag) {
            viewContext.delete(tag)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    
    


private func clearSelection() {
        selectedTag = nil
        tagName = ""
        tagColor = Color.white
    }
}

