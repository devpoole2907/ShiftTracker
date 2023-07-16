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
class ScheduledShiftStore: ObservableObject {
    
    @Published var shifts = [SingleScheduledShift]()
    @Published var previousSelectedShifts = [SingleScheduledShift]()
    @Published var changedShift: SingleScheduledShift?
    @Published var batchDeletedShifts: [SingleScheduledShift]?
    
    @Published var changedJob: Job?
    let shiftDataLoaded = PassthroughSubject<Void, Never>()
    
    func shouldIncludeShift(_ shift: ScheduledShift, jobModel: JobSelectionManager) -> Bool {
       if let selectedJobUUID = jobModel.selectedJobUUID {
           return shift.job?.uuid == selectedJobUUID
       }
       return true
   }
    
    func fetchShifts(from shifts: FetchedResults<ScheduledShift>, jobModel: JobSelectionManager){
        
        previousSelectedShifts = []
        for shift in self.shifts {

            previousSelectedShifts.append(shift)
            delete(shift)
        }
        
        print("The fucking shift count is: \(previousSelectedShifts.count)")
        
        var allShifts: [SingleScheduledShift] = []
        
        for shift in shifts {
            if shouldIncludeShift(shift, jobModel: jobModel) {
                allShifts.append(SingleScheduledShift(shift: shift))
            }
        }
        
        self.shifts = allShifts.reversed()
        
        //perhaps unncesscary?
        changedShift = self.shifts.first ?? nil
        
        
    }
    
    func delete(_ shift: SingleScheduledShift) {
        
        print("have we even got this far")
        
          //  let thisShift = SingleScheduledShift(shift: shift)
            if let index = shifts.firstIndex(where: {$0.id == shift.id}) {
                
                print("we reached changedshift")
                
                
                changedShift = shifts.remove(at: index)
            }
        
            
        
        }

        func add(_ shift: SingleScheduledShift) {
            
            
            //let thisShift = SingleScheduledShift(shift: shift)
            shifts.append(shift)
            changedShift = shift
        }
    
    
    
    
    
}
