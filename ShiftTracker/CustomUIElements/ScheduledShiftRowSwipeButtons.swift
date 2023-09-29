//
//  ScheduledShiftRowSwipeButtons.swift
//  ShiftTracker
//
//  Created by James Poole on 29/09/23.
//

import SwiftUI

struct ScheduledShiftRowSwipeButtons: View {
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    @EnvironmentObject var shiftStore: ShiftStore
    
    
    
    @Environment(\.managedObjectContext) var viewContext
    
    @ObservedObject var shift: ScheduledShift
    
    
    var body: some View {
        Button(role: .destructive) {
            withAnimation {
                scheduleModel.deleteShift(shift, with: shiftStore, using: viewContext)
                
            }
        } label: {
            Image(systemName: "trash")
        }
        Button(role: .none){
            scheduleModel.selectedShiftToEdit = shift
        } label: {
            Image(systemName: "pencil")
        }
 
        Button(role: .none){
           
            if shift.calendarEventID == nil { // an event doesnt exist in the calendar
                
                scheduleModel.addShiftToCalendar(shift: shift, viewContext: viewContext) { (success, error, eventID) in
                    if success {
                        print("Successfully added shift to calendar")
                        scheduleModel.addEventKitID(shift: shift, eventID: eventID)
                        scheduleModel.saveShifts(in: viewContext)
                    } else {
                        print("Failed to add shift to calendar: \(String(describing: error?.localizedDescription))")
                    }
                }
            } else { // one does exist
                scheduleModel.deleteEventFromCalendar(eventIdentifier: shift.calendarEventID ?? "")
                shift.calendarEventID = nil
                scheduleModel.saveShifts(in: viewContext)
            }
            
        } label: {
            Image(systemName: shift.calendarEventID == nil ? "calendar.badge.plus" : "calendar.badge.minus")
        }.tint(Color.pink)
        
    
        
        Button(role: .cancel) {
            
            CustomConfirmationAlert(action: {
                withAnimation {
                    scheduleModel.cancelRepeatingShiftSeries(shift: shift, with: shiftStore, using: viewContext)
                }
            }, title: "End all future repeating shifts for this shift?").showAndStack()
        } label: {
            Image(systemName: "clock.arrow.2.circlepath")
        }.disabled(!shift.isRepeating)
    }
}
