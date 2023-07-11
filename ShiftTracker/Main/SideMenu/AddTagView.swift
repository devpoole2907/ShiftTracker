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
    @State private var tagName = ""
    @State private var tagColor = Color.white
    
    var body: some View {
        VStack {
            TextField("Enter Tag", text: $tagName)
                .textFieldStyle(.roundedBorder)
                .padding()
                .overlay(Text("#").padding(.leading), alignment: .leading)
            
            ColorPicker("Choose Color", selection: $tagColor)
                .padding()
            
            Button(action: {
                addTag()
            }) {
                Text("Add Tag")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
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
}


