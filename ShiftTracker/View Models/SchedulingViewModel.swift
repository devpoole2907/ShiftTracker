//
//  SchedulingViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 8/07/23.
//

import Foundation
import SwiftUI
import CoreData
import EventKit

@MainActor
class SchedulingViewModel: ObservableObject {
    
    @Published var shouldScrollToNextShift = true
    @Published var selectedDays = Array(repeating: false, count: 7)
    // for notifications
    @Published var notifyMe = true
    @Published var selectedReminderTime: ReminderTime = .fifteenMinutes
    
    @Published var selectedShiftToEdit: ScheduledShift?
    @Published var selectedShiftToDupe: OldShift?
    @Published var shiftForExport: OldShift?
    
    @Published var isEmpty: Bool = false
    
    @Published var displayEvents = false
    
    @Published var displayedOldShifts: [OldShift] = []
    
    @Published var deleteJobAlert = false
    @Published var jobToDelete: Job?
    
    @Published var activeSheet: ActiveScheduleSheet?
    
    @Published var dateSelected: DateComponents? = Date().startOfDay.dateComponents
    
    init() {
        self.dateSelected = Date().startOfDay.dateComponents
    }
    
    private let notificationManager = ShiftNotificationManager.shared
    
    func fetchShifts(allShifts: FetchedResults<OldShift>) {
        let selectedDate = dateSelected?.date ?? Date()
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!
        withAnimation {
            displayedOldShifts = allShifts.filter { ($0.shiftStartDate! as Date) >= startOfDay && ($0.shiftStartDate! as Date) < endOfDay }
        }
    }
    
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
            deleteEventFromCalendar(eventIdentifier: shiftToDelete.calendarEventID ?? "")
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
    
    func deleteShift(_ shift: ScheduledShift, with shiftStore: ShiftStore, using viewContext: NSManagedObjectContext) {
        
        let shiftToDelete = shift
        cancelNotification(for: shiftToDelete)
        deleteEventFromCalendar(eventIdentifier: shiftToDelete.calendarEventID ?? "")
        viewContext.delete(shiftToDelete)
        if let singleShift = shiftStore.findSingleScheduledShift(shift) {
            shiftStore.delete(singleShift)
        } else {
            print("failed to find single shfit")
        }
        
        saveShifts(in: viewContext)
      
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
                                    tags: correspondingSingleShift.tags, isComplete: correspondingSingleShift.isComplete))
                                
                                
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
    
    func cancelRepeatingShiftSeries(shift: ScheduledShift, with shiftStore: ShiftStore, using viewContext: NSManagedObjectContext) {
        let repeatID = shift.repeatIdString ?? ""
        let shiftDate = shift.startDate ?? Date()

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
                                tags: correspondingSingleShift.tags, isComplete: correspondingSingleShift.isComplete))

                            batchDeleted.append(correspondingSingleShift)
                            
                           
                            

                        } else {
                            shiftStore.delete(correspondingSingleShift)
                            batchDeleted.append(correspondingSingleShift)
                            viewContext.delete(shiftToDelete)
                            cancelNotification(for: shiftToDelete)
                            if let eventIdentifier = shiftToDelete.calendarEventID {
                                print("removing calendar event of repeating shift")
                                    deleteEventFromCalendar(eventIdentifier: eventIdentifier)
                                
                            }
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

    func createScheduledShift(startDate: Date, endDate: Date, shiftID: UUID, repeatID: String, job: Job, selectedTags: Set<Tag>, enableRepeat: Bool, payMultiplier: Double, multiplierEnabled: Bool, breakReminder: Bool, breakReminderTime: TimeInterval, in viewContext: NSManagedObjectContext) -> ScheduledShift {
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
        newShift.breakReminder = breakReminder
        newShift.breakReminderTime = breakReminderTime
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
    


    func saveRepeatingShiftSeries(startDate: Date, endDate: Date, repeatEveryWeek: Bool, repeatID: String, job: Job, shiftStore: ShiftStore, selectedTags: Set<Tag>, selectedRepeatEnd: Date, enableRepeat: Bool, payMultiplier: Double, multiplierEnabled: Bool, breakReminder: Bool, breakReminderTime: TimeInterval, in viewContext: NSManagedObjectContext) {
        var currentStartDate = incrementDate(startDate, by: .day, value: 1)
        var currentEndDate = incrementDate(endDate, by: .day, value: 1)
        
        var repeatingShifts = [ScheduledShift]()
        
        while currentStartDate <= selectedRepeatEnd {
            if selectedDays[getDayOfWeek(date: currentStartDate) - 1] {
                let shiftID = UUID()
                
                let shift = createScheduledShift(startDate: currentStartDate, endDate: currentEndDate, shiftID: shiftID, repeatID: repeatEveryWeek ? repeatID : UUID().uuidString, job: job, selectedTags: selectedTags, enableRepeat: enableRepeat, payMultiplier: payMultiplier, multiplierEnabled: multiplierEnabled, breakReminder: breakReminder, breakReminderTime: breakReminderTime, in: viewContext)
                let singleShift = SingleScheduledShift(shift: shift)
                
                repeatingShifts.append(shift)
                shiftStore.add(singleShift)
            }
            
            currentStartDate = incrementDate(currentStartDate, by: .day, value: 1)
            currentEndDate = incrementDate(currentEndDate, by: .day, value: 1)
        }
        
        saveShifts(in: viewContext)
    }
    
    // used to update future repeating shifts if the shift is repeating and is edited
    
    func updateRepeatingShiftSeries(shiftToUpdate: SingleScheduledShift, newStartDate: Date, newEndDate: Date, newTags: Set<Tag>, newMultiplierEnabled: Bool, newPayMultiplier: Double, newReminderTime: TimeInterval, newNotifyMe: Bool, newBreakReminder: Bool, newBreakReminderTime: TimeInterval, with shiftStore: ShiftStore, using viewContext: NSManagedObjectContext) {
        
        let repeatID = shiftToUpdate.repeatID
        let shiftDate = shiftToUpdate.startDate
        
        let calendar = Calendar.current
        
        // day difference between startdate and enddate, because the enddate could be on the following day. this will cause trouble if we ignore the date components when updating (because we donrt want shifts rescheudled to the same day as the one edited)
        let dayDifference = calendar.dateComponents([.day], from: newStartDate, to: newEndDate).day!
        
        let request: NSFetchRequest<NSFetchRequestResult> = ScheduledShift.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "repeatIdString == %@", repeatID),
            NSPredicate(format: "startDate >= %@", shiftDate as NSDate)
        ])

        do {
            if let shiftsToUpdate = try viewContext.fetch(request) as? [ScheduledShift] {
                print("Number of repeating shifts found: \(shiftsToUpdate.count)")
                for shift in shiftsToUpdate {
                    if let correspondingSingleShift = shiftStore.shifts.first(where: { $0.id == shift.id }) {

                        guard var shiftStartDate = shift.startDate else { print("we got returned ")
                            return }
                       
                        
                        // Update only time components, keep date components intact (see above)
                        shiftStartDate = calendar.date(bySettingHour: calendar.component(.hour, from: newStartDate), minute: calendar.component(.minute, from: newStartDate), second: calendar.component(.second, from: newStartDate), of: shiftStartDate)!
                                           
                                           // add  day difference to the new end date
                                           let shiftedEndDate = calendar.date(byAdding: .day, value: dayDifference, to: shiftStartDate)!
                                           let shiftEndDate = calendar.date(bySettingHour: calendar.component(.hour, from: newEndDate), minute: calendar.component(.minute, from: newEndDate), second: calendar.component(.second, from: newEndDate), of: shiftedEndDate)!
                        
                        shift.startDate = shiftStartDate
                        shift.endDate = shiftEndDate
                        shift.tags = NSSet(array: Array(newTags))
                        shift.multiplierEnabled = newMultiplierEnabled
                        shift.reminderTime = newReminderTime
                        shift.payMultiplier = newPayMultiplier
                        shift.notifyMe = newNotifyMe
                        shift.breakReminder = newBreakReminder
                        shift.breakReminderTime = newBreakReminderTime
                        
                        
                        if let eventIdentifier = shift.calendarEventID {
                            if shift.id != shiftToUpdate.id {
                                deleteEventFromCalendar(eventIdentifier: eventIdentifier)
                                addShiftToCalendar(shift: shift, viewContext: viewContext) { (success, error, eventID) in
                                    
                                    
                                    if success {
                                        
                                    } else {
                                        print("Failed to add shift to calendar: \(String(describing: error?.localizedDescription))")
                                    }
                                    
                                }}
                        }
                        
                          

                        let updatedSingleShift = SingleScheduledShift(shift: shift)
                        shiftStore.update(updatedSingleShift)
                    }
                }

     
                try viewContext.save()
                print("Successfully updated the scheduled shifts.")
                
            }
        } catch {
            print("Failed to update the corresponding shifts.")
        }
    }


    // function for calendar event adding:
    
    func addShiftToCalendar(shift: ScheduledShift, viewContext: NSManagedObjectContext, completion: @escaping (Bool, Error?, String?) -> Void) {
        let eventStore = EKEventStore()
        

        
        let processEvent: () -> Void = {
            let event = EKEvent(eventStore: eventStore)
            event.title = "Work shift at \(shift.job!.name!)"
            event.startDate = shift.startDate
            event.endDate = shift.endDate
            event.calendar = eventStore.defaultCalendarForNewEvents
            if let jobLocation = shift.job?.locations?.first as? String {
                event.location = ("\(jobLocation)")
            } else {
                print("job had no location")
            }
            
            // save event
            do {
                try eventStore.save(event, span: .thisEvent)
                let eventID = event.eventIdentifier
                completion(true, nil, eventID)
            } catch let error {
                print("Failed to save event: \(error)")
                completion(false, error, nil)
            }
        }
        
        let permissionDenied: (Error?) -> Void = { error in
            print("Calendar access denied.")
            completion(false, error, nil)
        }
        
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { (granted, error) in
                granted ? processEvent() : permissionDenied(error)
            }
        } else {
            eventStore.requestAccess(to: .event) { (granted, error) in
                granted ? processEvent() : permissionDenied(error)
            }
        }
    }

    func addEventKitID(shift: ScheduledShift, eventID: String?) {
        shift.calendarEventID = eventID
    }
    
    
    // test function for calendar event deletion

    func deleteEventFromCalendar(eventIdentifier: String) {
        let eventStore = EKEventStore()


        if #available(iOS 17.0, *) {
            eventStore.requestWriteOnlyAccessToEvents { (granted, error) in
                if !granted {
                    print("Failed to get write access to calendar: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Fetch the event using its identifier
                if let event = eventStore.event(withIdentifier: eventIdentifier) {
                    do {
                        // Remove the event from the calendar
                        try eventStore.remove(event, span: .thisEvent)
                        print("Successfully removed event from calendar.")
                    } catch let error as NSError {
                        print("Failed to remove event: \(error)")
                    }
                } else {
                    print("Event not found")
                }
            }
        } else {
            // Fallback on earlier versions

            eventStore.requestAccess(to: .event) { (granted, error) in
                    if !granted {
                        print("Failed to get write access to calendar: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }

                    // Fetch the event using its identifier
                    if let event = eventStore.event(withIdentifier: eventIdentifier) {
                        do {
                            // Remove the event from the calendar
                            try eventStore.remove(event, span: .thisEvent)
                            print("Successfully removed event from calendar.")
                        } catch let error as NSError {
                            print("Failed to remove event: \(error)")
                        }
                    } else {
                        print("Event not found")
                    }
                }
            
            
        }
        
        
        
        
        
    }
    
    
}
