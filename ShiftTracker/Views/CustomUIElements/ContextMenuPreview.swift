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
    var actionsArray: [UIAction]
    @Binding var editMode: EditMode
    var action: () -> Void
    
     private var enableEdit = false
    
    
    init(shift: OldShift, themeManager: ThemeDataManager, navigationState: NavigationState, viewContext: NSManagedObjectContext, actionsArray: [UIAction], editMode: Binding<EditMode>? = nil, action: @escaping () -> Void) {
        self.shift = shift
        self.themeManager = themeManager
        self.navigationState = navigationState
        self.viewContext = viewContext
        self.actionsArray = actionsArray
        
        
        self.enableEdit = false
        self._editMode = Binding.constant(.inactive)
        if let editingMode = editMode {
            
            self._editMode = editingMode
            
            self.enableEdit = true
            
            } 
        
        
        self.action = action
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.layer.cornerRadius = 12
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
                
                
                
                let editUIAction = UIAction(title: "More", image: UIImage(systemName: "ellipsis.circle")) { action in
                    
                withAnimation {
                    self.parent.editMode = (self.parent.editMode == .active) ? .inactive : .active
                }
                    
            
                    
                    
                }
              
                               
                               // Add actions from the actionsArray if not editing
                               if self.parent.editMode == .inactive {
                                   actions.append(contentsOf: self.parent.actionsArray)
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
