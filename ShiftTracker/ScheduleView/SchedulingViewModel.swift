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
    

    func deleteShift(_ shift: SingleScheduledShift, with shiftStore: ScheduledShiftStore, using viewContext: NSManagedObjectContext){
        
        let request: NSFetchRequest<NSFetchRequestResult> = ScheduledShift.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", shift.id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            
            if let shiftToDelete = results.first as? ScheduledShift {
                shiftStore.delete(shift)
                viewContext.delete(shiftToDelete)
                cancelNotification(for: shiftToDelete)
                
                do {
                    print("Successfully deleted the scheduled shift.")
                    try viewContext.save()
                    
                    
                } catch {
                    print("Failed to delete the corresponding shift.")
                    
                }
                
            }
        } catch {
            
            print("Failed to fetch the corresponding shift to delete.")
            
        }
        
        
    }
    
    
    
    func cancelRepeatingShiftSeries(shift: SingleScheduledShift, with shiftStore: ScheduledShiftStore, using viewContext: NSManagedObjectContext) {
        guard let repeatID = shift.repeatID else { return }
        let shiftDate = shift.startDate
        
        let request: NSFetchRequest<NSFetchRequestResult> = ScheduledShift.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "newRepeatID == %@", repeatID as CVarArg),
            NSPredicate(format: "startDate > %@", shiftDate as NSDate)
        ])

        var batchDeleted = [SingleScheduledShift]()
        
        do {
                if let shiftsToDelete = try viewContext.fetch(request) as? [ScheduledShift] {
                    for shiftToDelete in shiftsToDelete {
                        if let correspondingSingleShift = shiftStore.shifts.first(where: { $0.id == shiftToDelete.id }) {
                           
                            
                            
                            shiftStore.delete(correspondingSingleShift)
                            batchDeleted.append(correspondingSingleShift)
                            viewContext.delete(shiftToDelete)
                            cancelNotification(for: shiftToDelete)
                           
                            
                            
                        }
                    }

                    print("Successfully deleted the scheduled shifts.")
                    try viewContext.save()
                    shiftStore.batchDeletedShifts = batchDeleted
                    
                }
            } catch {
                print("Failed to delete the corresponding shifts.")
            }
            
    }
    
    
    func cancelNotification(for scheduledShift: ScheduledShift) {
        let identifier = "ScheduledShift-\(scheduledShift.objectID)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    
}
