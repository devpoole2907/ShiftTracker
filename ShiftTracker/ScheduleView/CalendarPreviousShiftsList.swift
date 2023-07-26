//
//  CalendarPreviousShiftsList.swift
//  ShiftTracker
//
//  Created by James Poole on 24/07/23.
//

import SwiftUI
import CoreData


struct CalendarPreviousShiftsList: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    @EnvironmentObject var shiftStore: ShiftStore
    
    @EnvironmentObject var savedPublisher: ShiftSavedPublisher
    


    
    let shiftManager = ShiftDataManager()
    
    @Binding var dateSelected: DateComponents?
    @Binding var navPath: NavigationPath
    @Binding var displayedOldShifts: [OldShift]

    

    
    
    
    
    var body: some View {
        
        if !displayedOldShifts.isEmpty {
            ForEach(displayedOldShifts.filter({ shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) }), id: \.objectID) { shift in
                
                NavigationLink(value: shift) {
                    
                    ShiftDetailRow(shift: shift)
                    
                    
                }
                
                
                .navigationDestination(for: OldShift.self) { shift in
                    
                    
                    DetailView(shift: shift, presentedAsSheet: false, navPath: $navPath).navigationTitle(shift.job?.name ?? "Shift Details").environmentObject(savedPublisher)
                    
                    
                }
                
                
                
                .swipeActions {
                    Button(role: .destructive) {
                        shiftStore.deleteOldShift(shift, in: viewContext)
                        
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                
                
                
            }
            
            
        } else {
            
            Text("No previous shifts found for this date.")
                .bold()
                .padding()
            
        }
            

        
    }
    

    
    
}


