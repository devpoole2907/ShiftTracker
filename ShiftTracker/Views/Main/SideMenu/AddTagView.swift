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
    
    @StateObject var tagModel = AddTagViewModel()
    
    @FetchRequest(sortDescriptors: []) private var tags: FetchedResults<Tag>
    
    var isEditing: Bool {
        tagModel.selectedTag != nil
    }
    
    var buttonTitle: String {
        isEditing ? "Update Tag" : "Add Tag"
    }
    
    var body: some View {
        
        NavigationStack {
            ScrollView {
                
                tagGrid
                
                
                
            }
            VStack(alignment: .center){
                
                textFieldColorPicker
                
                actionButtons
                
            }.padding()
            
            
            
                .navigationTitle("Tags")
                .navigationBarTitleDisplayMode(.inline)
            
                .toolbar {
                    
                    ToolbarItem(placement: .topBarTrailing){
                        CloseButton()
                    }
                }
            
        }
        
        
        
        
    }
    
    var tagGrid: some View {
        
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        
        return VStack(alignment: .center) {
            
            LazyVGrid(columns: columns) {
                ForEach(tags, id: \.self) { tag in
                    Button(action: {
                        tagModel.tagButtonAction(tag)
                    }) {
                        Text("#\(tag.name ?? "")")
                            .bold()
                            .roundedFontDesign()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue, opacity: tagModel.selectedTag == tag ? 1.0 : 0.5))
                    
                }
                
            }
            .padding(10)
            
            .haptics(onChangeOf: tagModel.selectedTag, type: .soft)
            
            .scaleEffect(tagModel.buttonScale)
            
            
            
            
            
        }.glassModifier(cornerRadius: 20)
            .padding()
    }
    
    var textFieldColorPicker: some View {
        return HStack{
            
            
            CustomTextField(text: $tagModel.tagName, hint: "Add Tag", leadingIcon: !(tagModel.selectedTag?.editable ?? true) ? "exclamationmark.triangle.fill" : "number")
                .frame(maxHeight: 40)
                .shake(times: tagModel.tagShakeTimes)
                .disabled((!(tagModel.selectedTag?.editable ?? true)))
            
            
            ZStack{
                Circle()
                    .foregroundStyle(Color("SquaresColor"))
                    .frame(maxHeight: 30)
                ColorPicker("", selection: $tagModel.tagColor, supportsOpacity: false)
                    .padding()
                    .labelsHidden()
                
            }
        }
    }
    
    var actionButtons: some View {
        return HStack{
            
            if let selectedTag = tagModel.selectedTag {
                
                ActionButtonView(title: "Delete", backgroundColor: colorScheme == .dark ? .white : .black, textColor: !selectedTag.editable ? .gray : .red, icon: "trash.fill", buttonWidth: .infinity, action: {
                    tagModel.deleteTagButtonAction(tag: selectedTag, in: viewContext){
                        hideKeyboard()
                    }
                    
                })   .disabled(!selectedTag.editable)
                    .opacity(!selectedTag.editable ? 0.5 : 1.0)
                
                
                
            }
            
            ActionButtonView(title: buttonTitle, backgroundColor: colorScheme == .dark ? .white : .black, textColor: colorScheme == .dark ? .white : .black, icon: "tag.fill", buttonWidth: .infinity, action: {
                
                tagModel.addTagButtonAction(tags: tags, in: viewContext)
                
                
            }).buttonStyle(.plain)
                .haptics(onChangeOf: tagModel.tagAdded, type: .success)
                .haptics(onChangeOf: tagModel.tagShakeTimes, type: .error)
            
        }
    }
    
}

