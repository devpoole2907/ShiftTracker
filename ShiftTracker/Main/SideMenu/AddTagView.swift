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
    
    @State private var tagShakeTimes: CGFloat = 0
    
    @State private var buttonScale: CGFloat = 1.0
    
    @State private var selectedTag: Tag? = nil
    
    @FetchRequest(sortDescriptors: []) private var tags: FetchedResults<Tag>
    
    var isEditing: Bool {
        selectedTag != nil
    }
    
    var buttonTitle: String {
        isEditing ? "Update Tag" : "Add Tag"
    }
    
    private func isTagNameDuplicate() -> Bool {
        return tags.contains(where: { $0.name?.lowercased() == tagName.lowercased() })
        }
    
    var body: some View {
        
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        
        NavigationStack {
            ScrollView {
                
                VStack(alignment: .center) {
                    
                    LazyVGrid(columns: columns) {
                        ForEach(tags, id: \.self) { tag in
                            Button(action: {
                                if selectedTag == tag {
                                    selectedTag = nil
                                    tagName = ""
                          
                                    
                                    
                                } else {
                                    selectedTag = tag
                                    tagName = tag.name ?? ""
                                    tagColor = Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue)
                                }
                            }) {
                                Text("#\(tag.name ?? "")")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue, opacity: selectedTag == tag ? 1.0 : 0.5))
                            
                        }
                        
                    }
                    .padding(10)
                    
                    .haptics(onChangeOf: selectedTag, type: .soft)
             
                    
                    
                    
                    
                    
                    
                }.background(Color("SquaresColor"))
                .cornerRadius(12)
                .padding()
                
                
                
            }
            VStack(alignment: .center){
                
                HStack{
                    
                    
                    CustomTextField(text: $tagName, hint: "Add Tag", leadingIcon: "number")
                        .frame(maxHeight: 40)
                        .shake(times: tagShakeTimes)
                    
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
                
                if let selectedTag = selectedTag {
                    Button(action: {
                        
                        deleteTag(selectedTag)
                        clearSelection()
                        hideKeyboard()
                        
                    }) {
                        
                        
                        HStack{
                            Image(systemName: "trash")
                            Text("Delete")
                                .bold()
                        } .padding()
                            .frame(maxWidth: .infinity)
                            .background((selectedTag.name?.lowercased() == "late" || selectedTag.name?.lowercased() == "overtime" || selectedTag.name?.lowercased() == "night") ? .gray : .red)
                        
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .opacity((selectedTag.name?.lowercased() == "late" || selectedTag.name?.lowercased() == "overtime" || selectedTag.name?.lowercased() == "night") ? 0.5 : 1.0)
                    }.listRowSeparator(.hidden)
                    
                        .disabled(selectedTag.name?.lowercased() == "late" || selectedTag.name?.lowercased() == "overtime" || selectedTag.name?.lowercased() == "night")
                       
                }
                
                
                Button(action: {
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.5)) {
                            buttonScale = 1.2
                        }
                    
                    
                    
                    if tagName != "" && tagName.count <= 8 && !isTagNameDuplicate() { // prevents empty tags & long names, duplicate names
                   
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
                        
                        withAnimation(.linear(duration: 0.4)) {
                            tagShakeTimes += 2
                        }
                        
                    }
                    
                    // this is for some reason causing the lazy v grid to animate not this button! but keep it here its a feature now it looks sweet >:)
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.5)) {
                            buttonScale = 1.0
                        }
                    
                    
                }) {
                    Text(buttonTitle)
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(colorScheme == .dark ? .white : .black)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .cornerRadius(20)
                        .contentShape(Rectangle())
                }.listRowSeparator(.hidden)
                    
                    
                    
                    .scaleEffect(buttonScale)
                    .buttonStyle(.plain)
                    
                    .haptics(onChangeOf: tagAdded, type: .success)
                    .haptics(onChangeOf: tagShakeTimes, type: .error)
                
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
        tagColor = Color.purple
    }
}

