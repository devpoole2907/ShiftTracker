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
    
    @Published var shouldScrollToNextShift = true
    @Published var selectedDays = Array(repeating: false, count: 7)
    // for notifications
    @Published var notifyMe = true
    @Published var selectedReminderTime: ReminderTime = .fifteenMinutes
    
    private let notificationManager = ShiftNotificationManager.shared
    
    func fetchScheduledShift(id: UUID, in viewContext: NSManagedObjectContext) -> ScheduledShift? {
        let request: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            let results = try viewContext.fetch(request)
            return results.first
        } catch {
            // handle the error
            return nil
        }
    }
    

    func deleteShift(_ shift: SingleScheduledShift, with shiftStore: ShiftStore, using viewContext: NSManagedObjectContext) {
        
        if let shiftToDelete = fetchScheduledShift(id: shift.id, in: viewContext) {
            cancelNotification(for: shiftToDelete)
            viewContext.delete(shiftToDelete)
            shiftStore.delete(shift)
            
            do {
                print("Successfully deleted the scheduled shift.")
                try viewContext.save()
            } catch {
                print("Failed to delete the corresponding shift.")
            }
        } else {
            print("Failed to fetch the corresponding shift to delete.")
        }
    }

    
    func deleteOldShift(_ shift: SingleScheduledShift, with shiftStore: ShiftStore, using viewContext: NSManagedObjectContext){
        
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
    
    
    
    
    
    func cancelRepeatingShiftSeries(shift: SingleScheduledShift, with shiftStore: ShiftStore, using viewContext: NSManagedObjectContext) {
        let repeatID = shift.repeatID
        let shiftDate = shift.startDate
        
        let request: NSFetchRequest<NSFetchRequestResult> = ScheduledShift.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "repeatIdString == %@", repeatID),
            NSPredicate(format: "startDate >= %@", shiftDate as NSDate)
        ])

        var batchDeleted = [SingleScheduledShift]()
        
        do {
            
            
                if let shiftsToDelete = try viewContext.fetch(request) as? [ScheduledShift] {
                    print("Number of repeating shifts found: \(shiftsToDelete.count)")
                    for shiftToDelete in shiftsToDelete {
                        if let correspondingSingleShift = shiftStore.shifts.first(where: { $0.id == shiftToDelete.id }) {
                           
                            if shiftToDelete.startDate == shiftDate {
                                
                                shiftToDelete.isRepeating = false
                                shiftStore.delete(correspondingSingleShift)
                                shiftStore.add(SingleScheduledShift(
                                    startDate: correspondingSingleShift.startDate,
                                    endDate: correspondingSingleShift.endDate,
                                    id: correspondingSingleShift.id,
                                    job: correspondingSingleShift.job!,
                                    isRepeating: false,
                                    repeatID: repeatID,
                                    reminderTime: correspondingSingleShift.reminderTime,
                                    notifyMe: correspondingSingleShift.notifyMe,
                                    tags: correspondingSingleShift.tags))
                                
                                
                                batchDeleted.append(correspondingSingleShift)
                                
                            } else {
                                
                                shiftStore.delete(correspondingSingleShift)
                                batchDeleted.append(correspondingSingleShift)
                                viewContext.delete(shiftToDelete)
                                cancelNotification(for: shiftToDelete)
                                
                            }
                            
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
    
    func incrementDate(_ date: Date, by interval: Calendar.Component, value: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: interval, value: value, to: date)!
    }

    func createScheduledShift(startDate: Date, endDate: Date, shiftID: UUID, repeatID: String, job: Job, selectedTags: Set<Tag>, enableRepeat: Bool, payMultiplier: Double, multiplierEnabled: Bool, in viewContext: NSManagedObjectContext) -> ScheduledShift {
        let newShift = ScheduledShift(context: viewContext)
        newShift.startDate = startDate
        newShift.endDate = endDate
        newShift.id = shiftID
        newShift.repeatIdString = repeatID
        newShift.isRepeating = enableRepeat
        newShift.reminderTime = selectedReminderTime.timeInterval
        newShift.notifyMe = notifyMe
        newShift.job = job
        newShift.tags = NSSet(array: Array(selectedTags))
        newShift.payMultiplier = payMultiplier
        newShift.multiplierEnabled = multiplierEnabled
        return newShift
    }
    
    func saveShifts(in viewContext: NSManagedObjectContext) {
        do {
            try viewContext.save()
                notificationManager.scheduleNotifications()
            
        } catch {
            print("Error saving shifts: \(error.localizedDescription)")
        }
    }
    


    func saveRepeatingShiftSeries(startDate: Date, endDate: Date, repeatEveryWeek: Bool, repeatID: String, job: Job, shiftStore: ShiftStore, selectedTags: Set<Tag>, selectedRepeatEnd: Date, enableRepeat: Bool, payMultiplier: Double, multiplierEnabled: Bool, in viewContext: NSManagedObjectContext) {
        var currentStartDate = incrementDate(startDate, by: .day, value: 1)
        var currentEndDate = incrementDate(endDate, by: .day, value: 1)
        
        var repeatingShifts = [ScheduledShift]()
        
        while currentStartDate <= selectedRepeatEnd {
            if selectedDays[getDayOfWeek(date: currentStartDate) - 1] {
                let shiftID = UUID()
                
                let shift = createScheduledShift(startDate: currentStartDate, endDate: currentEndDate, shiftID: shiftID, repeatID: repeatEveryWeek ? repeatID : UUID().uuidString, job: job, selectedTags: selectedTags, enableRepeat: enableRepeat, payMultiplier: payMultiplier, multiplierEnabled: multiplierEnabled, in: viewContext)
                let singleShift = SingleScheduledShift(shift: shift)
                
                repeatingShifts.append(shift)
                shiftStore.add(singleShift)
            }
            
            currentStartDate = incrementDate(currentStartDate, by: .day, value: 1)
            currentEndDate = incrementDate(currentEndDate, by: .day, value: 1)
        }
        
        saveShifts(in: viewContext)
    }

    
    
}
