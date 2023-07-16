//
//  AddTagView.swift
//  ShiftTracker
//
//  Created by James Poole on 11/07/23.
//

import SwiftUI
import CoreData
import Haptics

struct AddTagView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var tagName = ""
    @State private var tagColor = Color.purple
    @State private var tagAdded = false
    
    @State private var buttonScale: CGFloat = 1.0
    
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
                
                VStack(alignment: .center) {
                    
                    
                    
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
                    .haptics(onChangeOf: selectedTag, type: .soft)
             
                    
                    
                    
                    
                    
                    
                }.padding()
                
                
                
            }
            VStack(alignment: .center){
                
                HStack{
                    
                    
                    CustomTextField(text: $tagName, hint: "Add Tag", leadingIcon: Image(systemName: "number"))
                        .frame(maxHeight: 40)
                    
                    
                    ZStack{
                        Circle()
                            .foregroundStyle(Color("SquaresColor"))
                            .frame(maxHeight: 30)
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
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.5)) {
                            buttonScale = 1.2
                        }
                    
                    
                    
                    if tagName != "" { // prevents empty tags
                        // !!!!!!!!!!!!!!!!! this also needs to check for duplicate names
                        if let selectedTag = selectedTag {
                            
                            updateTag(selectedTag)
                            tagAdded.toggle()
                            clearSelection()
                        } else {
                            addTag()
                            tagAdded.toggle()
                            clearSelection()
                        }
                        
                        
                        
                    } else {
                        
                        // make the button do haptic feedback .error type & jiggle side to side like jobview
                        
                        
                        
                    }
                    
                    // this is for some reason causing the lazy v grid to animate not this button! but keep it here its a feature now it looks sweet >:)
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.5)) {
                            buttonScale = 1.0
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
                    .scaleEffect(buttonScale)
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .haptics(onChangeOf: tagAdded, type: .success)
                
                
            }
            
            }.padding()
            
            
            
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

