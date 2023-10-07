//
//  AddTagViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 7/10/23.
//

import Foundation
import CoreData
import SwiftUI

class AddTagViewModel: ObservableObject {
    @Published var tagName = ""
    @Published var tagColor = Color.purple
    @Published var tagAdded = false
    
    @Published var tagShakeTimes: CGFloat = 0
    
    @Published var buttonScale: CGFloat = 1.0
    
    @Published var selectedTag: Tag? = nil
    
    func isTagNameDuplicate(tags: FetchedResults<Tag>) -> Bool {
        return tags.contains(where: { $0.name?.lowercased() == self.tagName.lowercased() })
        }
    
    func tagButtonAction(_ tag: Tag){
        if selectedTag == tag {
            withAnimation {
                selectedTag = nil
                tagName = ""
                
            }
            
        } else {
            withAnimation {
                selectedTag = tag
                tagName = tag.name ?? ""
                tagColor = Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue)
            }
        }
    }
    
    func addTagButtonAction(tags: FetchedResults<Tag>, in viewContext: NSManagedObjectContext) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.5)) {
                buttonScale = 1.2
            }
        
        
        
        if tagName != "" && tagName.count <= 8 && !isTagNameDuplicate(tags: tags) { // prevents empty tags & long names, duplicate names
       
            if let selectedTag = selectedTag {
                withAnimation {
                    updateTag(selectedTag, in: viewContext)
                    tagAdded.toggle()
                    clearSelection()
                }
            } else {
                withAnimation {
                    addTag(in: viewContext)
                    tagAdded.toggle()
                    clearSelection()
                }
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
    }
    
    func deleteTagButtonAction(tag: Tag, in viewContext: NSManagedObjectContext, completion: () -> Void){
        withAnimation {
            deleteTag(tag, in: viewContext)
            clearSelection()
        }
    }
    
    func addTag(in viewContext: NSManagedObjectContext) {
        let newTag = Tag(context: viewContext)
        newTag.name = tagName
        newTag.editable = true
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
    
    private func updateTag(_ tag: Tag, in viewContext: NSManagedObjectContext){
        
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
    
    private func deleteTag(_ tag: Tag, in viewContext: NSManagedObjectContext) {
        viewContext.delete(tag)
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    
    
    
     func clearSelection() {
        selectedTag = nil
        tagName = ""
        tagColor = Color.purple
    }
    
    
}
