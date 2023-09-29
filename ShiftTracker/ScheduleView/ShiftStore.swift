//
//  ScheduledShiftStore.swift
//  ShiftTracker
//
//  Created by James Poole on 8/07/23.
//

import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class ShiftStore: ObservableObject {
    
    static let shared = ShiftStore()
    
    let shiftManager = ShiftDataManager()
    
    @Published var shifts = [SingleScheduledShift]()
    @Published var previousSelectedShifts = [SingleScheduledShift]()
    @Published var changedShift: SingleScheduledShift?
    @Published var batchDeletedShifts: [SingleScheduledShift]?
    
    @Published var changedJob: Job?
    let shiftDataLoaded = PassthroughSubject<Void, Never>()
    
    func findSingleScheduledShift(_ shift: ScheduledShift?) -> SingleScheduledShift? {
        // looks through the shifts array of SingleScheduledShifts above called shifts, then it finds the one with the matching id and returns it
        guard let shift = shift else { return nil }
        guard let shiftID = shift.id else { return nil }
        return shifts.first { $0.id == shiftID }
        
    }
    
    func shouldIncludeShift(_ shift: ScheduledShift, jobModel: JobSelectionManager) -> Bool {
       if let selectedJobUUID = jobModel.selectedJobUUID {
           return shift.job?.uuid == selectedJobUUID
       }
       return true
   }
    
    func shouldIncludeOldShift(_ shift: OldShift, jobModel: JobSelectionManager) -> Bool {
       if let selectedJobUUID = jobModel.selectedJobUUID {
           return shift.job?.uuid == selectedJobUUID
       }
       return true
   }
    
    func fetchShifts(from scheduledShifts: FetchedResults<ScheduledShift>, and oldShifts: FetchedResults<OldShift>, jobModel: JobSelectionManager){
        
        previousSelectedShifts = []
        for shift in self.shifts {

            previousSelectedShifts.append(shift)
            delete(shift)
        }
        
        print("The fucking shift count is: \(previousSelectedShifts.count)")
        
        var allShifts: [SingleScheduledShift] = []
        
        for shift in scheduledShifts {
            if shouldIncludeShift(shift, jobModel: jobModel) {
                allShifts.append(SingleScheduledShift(shift: shift))
            }
        }
        
        for shift in oldShifts {
            if shouldIncludeOldShift(shift, jobModel: jobModel) {
                allShifts.append(SingleScheduledShift(oldShift: shift))
            }
        }
        
        self.shifts = allShifts.reversed()
        
        //perhaps unncesscary?
        changedShift = self.shifts.first ?? nil
        
        
    }
    
    func delete(_ shift: SingleScheduledShift) {
        
        print("have we even got this far")
        
            if let index = shifts.firstIndex(where: {$0.id == shift.id}) {
                
                print("we reached changedshift")
                
                
                changedShift = shifts.remove(at: index)
            }
        
            
        
        }
    

        func add(_ shift: SingleScheduledShift) {
            
            
            shifts.append(shift)
            changedShift = shift
        }
    
    func update(_ newShift: SingleScheduledShift) {

            if let index = shifts.firstIndex(where: { $0.id == newShift.id }) {
          
                shifts[index] = newShift
            } else {
                print("Shift not found in store.")
            }
        }
    
    func updateOldShift(_ shift: OldShift){
        
        if let index = shifts.firstIndex(where: {$0.id == shift.shiftID}) {
            
            changedShift = shifts.remove(at: index)
            var shiftToUpdate = SingleScheduledShift(oldShift: shift)
            shifts.append(shiftToUpdate)
            changedShift = shiftToUpdate
            
        }
        
        
        
    }
    
    
    func deleteOldShift(_ oldShift: OldShift, in viewContext: NSManagedObjectContext) {
      
        if let matchingShift = self.shifts.first(where: { $0.id == oldShift.shiftID }) {
          
            delete(matchingShift)
            
            
            
        }

    
        shiftManager.deleteShift(oldShift, in: viewContext)
    }
    
    
    
    // delete all older scheduled shifts as they will be populated by actual old shifts
    
    func deleteOldScheduledShifts(in context: NSManagedObjectContext) {
        let currentStartDate = Date().startOfDay

        let fetchRequest: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startDate < %@", currentStartDate as NSDate)

        do {
            let oldShifts = try context.fetch(fetchRequest)
            for shift in oldShifts {
                context.delete(shift)
            }

          
            try context.save()
        } catch {
            print("Failed to fetch shifts: \(error)")
        }
    }

    
    
    
    
}
