//
//  SchedulingViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 8/07/23.
//

import Foundation
import SwiftUI
import CoreData

@MainActor
class SchedulingViewModel: ObservableObject {
    

    func deleteShift(_ shift: SingleScheduledShift, in scheduledShifts: FetchedResults<ScheduledShift>, with shiftStore: ScheduledShiftStore, using viewContext: NSManagedObjectContext){
        
        
        
        if let shiftToDelete = scheduledShifts.first(where: { $0.id == shift.id }) {
            shiftStore.delete(shift)
            viewContext.delete(shiftToDelete)
            
            do {
                print("Successfully deleted the scheduled shift.")
                try viewContext.save()
                
                
            } catch {
                print("Failed to delete the corresponding shift.")
                
            }
            
        }
    }
    
    func cancelRepeatingShiftSeries(shift: SingleScheduledShift, in scheduledShifts: FetchedResults<ScheduledShift>, with shiftStore: ScheduledShiftStore, using viewContext: NSManagedObjectContext) {
        guard let repeatID = shift.repeatID else { return }
        
        do {
            for scheduledShift in scheduledShifts {
                guard let scheduledShiftRepeatID = scheduledShift.newRepeatID else { return }
                if repeatID == scheduledShiftRepeatID  {
                    
                    print("repeatID")
                    
                    shiftStore.delete(shift)
                    viewContext.delete(scheduledShift)
                    try viewContext.save()
                }
                
            }
            //cancelNotifications(for: futureShifts)
            
        } catch {
            print("Error canceling repeating shift series: \(error)")
        }
    }
    
    
    
    
    
}
