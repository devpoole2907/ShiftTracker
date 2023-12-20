//
//  ContextMenuPreview.swift
//  ShiftTracker
//
//  Created by James Poole on 19/12/23.
//

import Foundation
import UIKit
import SwiftUI
import CoreData

struct ContextMenuPreview: UIViewRepresentable {
    var shift: OldShift
    var themeManager: ThemeDataManager
    var navigationState: NavigationState
    var viewContext: NSManagedObjectContext
    var deleteAction: () -> Void
    var duplicateAction: () -> Void
    var editAction: (() -> Void)?
    @Binding var editMode: EditMode
    var action: () -> Void
    
     private var enableEdit = false
    
    
    init(shift: OldShift, themeManager: ThemeDataManager, navigationState: NavigationState, viewContext: NSManagedObjectContext, deleteAction: @escaping () -> Void, duplicateAction: @escaping () -> Void, editAction: (() -> Void)? = nil, editMode: Binding<EditMode>? = nil, action: @escaping () -> Void) {
        self.shift = shift
        self.themeManager = themeManager
        self.navigationState = navigationState
        self.viewContext = viewContext
        self.deleteAction = deleteAction
        self.duplicateAction = duplicateAction
        
        if let editingMode = editMode {
            
            self._editMode = editingMode
            
            self.enableEdit = true
            
            } else {
            
                self.enableEdit = false
            
            }
        
        
        self.editAction = editAction
        self.action = action
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        let interaction = UIContextMenuInteraction(delegate: context.coordinator)
        view.addInteraction(interaction)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, viewContext: viewContext)
    }
    
    class Coordinator: NSObject, UIContextMenuInteractionDelegate {
        var parent: ContextMenuPreview
        var viewContext: NSManagedObjectContext
        
        init(parent: ContextMenuPreview, viewContext: NSManagedObjectContext) {
            self.parent = parent
            self.viewContext = viewContext
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: {
                let detailVC = UIHostingController(rootView:
                                                    
                                                    
                                                    DetailView(shift: self.parent.shift, isContextPreview: true)
                    .environmentObject(self.parent.themeManager)
                    .environmentObject(self.parent.navigationState)
                    .padding(.top)
                )
                return detailVC
            }, actionProvider: { suggestedActions in
                
                var actions = [UIAction]()
                
              
                
           // in the end, all actions should only be accessible if we arent editing 
                if self.parent.editMode == .inactive {
                    
                    let deleteUIAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                        // Perform delete action
                        self.parent.deleteAction()
                    }
                    
                    actions.append(deleteUIAction)
                    
                    let duplicateUIAction = UIAction(title: "Duplicate", image: UIImage(systemName: "doc.on.doc.fill")) { action in
                        self.parent.duplicateAction()
                    }
                    
                    actions.append(duplicateUIAction)
                    
                    let editUIAction = UIAction(title: "More", image: UIImage(systemName: "ellipsis.circle")) { action in
                        
                    withAnimation {
                        self.parent.editMode = (self.parent.editMode == .active) ? .inactive : .active
                    }
                        
                        if let editAction = self.parent.editAction {
                            editAction()
                        }
                        
                        
                    }
                    if self.parent.enableEdit {
                    actions.append(editUIAction)
                    }
                    
                }

                
                
                
                
                // Combine actions into a UIMenu
                return UIMenu(title: "", children: actions)
            })
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
            animator.addCompletion {
                self.parent.action()
            }
        }
    }
}
