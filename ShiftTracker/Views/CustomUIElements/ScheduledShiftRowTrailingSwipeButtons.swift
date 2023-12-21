//
//  ScheduledShiftRowSwipeButtons.swift
//  ShiftTracker
//
//  Created by James Poole on 29/09/23.
//

import SwiftUI
import CoreData
import PopupView

struct ScheduledShiftRowSwipeButtons: View {
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    @EnvironmentObject var shiftStore: ShiftStore
    
    @Environment(\.managedObjectContext) var viewContext
    
    @ObservedObject var shift: ScheduledShift
    
    var showText: Bool = false
    
    var body: some View {
        Group {
        Button(action: {
            withAnimation {
                scheduleModel.deleteShift(shift, with: shiftStore, using: viewContext)
                
            }
        }){
            HStack {
                if showText {
                    Text("Delete")
                }
                Image(systemName: "trash")
            }
        }.tint(Color.red)
        
        
        Button(action: {
            scheduleModel.selectedShiftToEdit = shift
        }){
            HStack{
                if showText {
                    Text("Edit")
                }
                Image(systemName: "pencil")
            }
        }.tint(Color.gray)
     
        
        Button(action: {
            if shift.calendarEventID == nil { // an event doesnt exist in the calendar
                
                // if shift is repeating, ask to add all future ones
                
                if shift.isRepeating {
                    CustomTripleActionPopup(action: {
                        scheduleModel.addShiftToCalendar(shift: shift, viewContext: viewContext) { (success, error, eventID) in
                            if success {
                                print("Successfully added shift to calendar")
                                scheduleModel.addEventKitID(shift: shift, eventID: eventID)
                                scheduleModel.saveShifts(in: viewContext)
                            } else {
                                print("Failed to add shift to calendar: \(String(describing: error?.localizedDescription))")
                            }
                        }
                    }, secondAction: {
                        
                        // make this its own func
                        
                        if let repeatID = shift.repeatIdString, let startDate = shift.startDate {
                            
                            let request: NSFetchRequest<NSFetchRequestResult> = ScheduledShift.fetchRequest()
                            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                NSPredicate(format: "repeatIdString == %@", repeatID),
                                NSPredicate(format: "startDate >= %@", startDate as NSDate)
                            ])
                            
                            do {
                                if let shiftsToSync = try viewContext.fetch(request) as? [ScheduledShift] {
                                    print("Number of repeating shifts found: \(shiftsToSync.count)")
                                    for shift in shiftsToSync {
                                        
                                        if shift.calendarEventID == nil {
                                            
                                            scheduleModel.addShiftToCalendar(shift: shift, viewContext: viewContext) { (success, error, eventID) in
                                                if success {
                                                    print("Successfully added shift to calendar")
                                                    
                                                    scheduleModel.addEventKitID(shift: shift, eventID: eventID)
                                                    scheduleModel.saveShifts(in: viewContext)
                                                } else {
                                                    print("Failed to add shift to calendar: \(String(describing: error?.localizedDescription))")
                                                }
                                            }
                                        }
                                        
                                    }
                                }
                                
                                
                                try viewContext.save()
                                print("Successfully synced the scheduled shifts with the system calendar.")
                                
                                
                            } catch {
                                print("Failed to update the corresponding shifts.")
                            }
                            
                        }
                        
                        
                    }, title: "Add shift to system calendar?", firstActionText: "Just this one", secondActionText: "All repeating shifts").showAndStack()
                    
                } else {
                    
                    // else add single
                    
                    scheduleModel.addShiftToCalendar(shift: shift, viewContext: viewContext) { (success, error, eventID) in
                        if success {
                            print("Successfully added shift to calendar")
                            scheduleModel.addEventKitID(shift: shift, eventID: eventID)
                            scheduleModel.saveShifts(in: viewContext)
                        } else {
                            print("Failed to add shift to calendar: \(String(describing: error?.localizedDescription))")
                        }
                    }
                }
                
                
            }
            else { // one does exist
                
                
                // if shift is repeating, ask to remove all future repeating ones
                
                if shift.isRepeating {
                    CustomTripleActionPopup(action: {
                        
                        scheduleModel.deleteEventFromCalendar(eventIdentifier: shift.calendarEventID ?? "")
                        shift.calendarEventID = nil
                        scheduleModel.saveShifts(in: viewContext)
                        
                    }, secondAction: {
                        
                        // make this its own func
                        
                        if let repeatID = shift.repeatIdString, let startDate = shift.startDate {
                            
                            let request: NSFetchRequest<NSFetchRequestResult> = ScheduledShift.fetchRequest()
                            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                NSPredicate(format: "repeatIdString == %@", repeatID),
                                NSPredicate(format: "startDate >= %@", startDate as NSDate)
                            ])
                            
                            do {
                                if let shiftsToSync = try viewContext.fetch(request) as? [ScheduledShift] {
                                    print("Number of repeating shifts found: \(shiftsToSync.count)")
                                    for shift in shiftsToSync {
                                        
                                        scheduleModel.deleteEventFromCalendar(eventIdentifier: shift.calendarEventID ?? "")
                                        shift.calendarEventID = nil
                                        scheduleModel.saveShifts(in: viewContext)
                                        
                                        
                                    }
                                }
                                
                                
                                try viewContext.save()
                                print("Successfully synced the scheduled shifts with the system calendar.")
                                
                                
                            } catch {
                                print("Failed to update the corresponding shifts.")
                            }
                            
                        }
                        
                        
                    }, title: "Remove shift from system calendar?", firstActionText: "Just this one", secondActionText: "All repeating shifts").showAndStack()
                } else {
                    
                    // else deletes calendar event for this one only.
                    
                    scheduleModel.deleteEventFromCalendar(eventIdentifier: shift.calendarEventID ?? "")
                    shift.calendarEventID = nil
                    scheduleModel.saveShifts(in: viewContext)
                }
            }
        }){
            HStack {
                if showText {
                    Text(shift.calendarEventID == nil ? "Add to Calendar" : "Remove from Calendar")
                }
                Image(systemName: shift.calendarEventID == nil ? "calendar.badge.plus" : "calendar.badge.minus")
            }
        }.tint(Color(red: Double(shift.job?.colorRed ?? 0.0), green: Double(shift.job?.colorGreen ?? 0.0), blue: Double(shift.job?.colorBlue ?? 0.0)))
        if shift.isRepeating {
            Button(action: {
                CustomConfirmationAlert(action: {
                    withAnimation {
                        scheduleModel.cancelRepeatingShiftSeries(shift: shift, with: shiftStore, using: viewContext)
                    }
                }, title: "End all future repeating shifts for this shift?").showAndStack()
            }){
                HStack {
                    if showText {
                        Text("End Repeat")
                    }
                    Image(systemName: "clock.arrow.2.circlepath")
                }
            }
            .tint(Color.indigo)
        }
    } .disabled(shift.isComplete)
}
}
