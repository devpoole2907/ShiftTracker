//
//  OldShiftSwipeActions.swift
//  ShiftTracker
//
//  Created by James Poole on 22/12/23.
//

import SwiftUI

struct OldShiftSwipeActions: View {
    
    let deleteAction: () -> Void
    let duplicateAction: () -> Void
    
    var body: some View {
        Button(action:
            
            deleteAction
            
        ){
            Image(systemName: "trash")
        }
        
        .tint(.red)
        
        Button(action:
            
            duplicateAction
            
        ){
            Image(systemName: "plus.square.fill.on.square.fill")
        }.tint(.gray)
    }
}

