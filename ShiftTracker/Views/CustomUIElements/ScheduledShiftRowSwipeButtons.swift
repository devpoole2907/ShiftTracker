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
    
    var showText: Bool = false
    
    var body: some View {
        
        Button(action: {
            withAnimation {
                scheduleModel.deleteShift(shift, with: shiftStore, using: viewContext)
                
            }
            
            Task {
                await scheduleModel.loadGroupedShifts(shiftStore: shiftStore, scheduleModel: scheduleModel)
            }
        }){
            HStack {
                if showText {
                    Text("Delete")
                }
                Image(systemName: "trash")
            }
        }.tint(Color.clear)
        
        Button(action: {
            scheduleModel.selectedShiftToEdit = shift
        }){
            HStack{
                if showText {
                    Text("Edit")
                }
                Image(systemName: "pencil")
            }
        }.tint(Color.clear)

        Button(action: {
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
        }){
            HStack {
                if showText {
                    Text(shift.calendarEventID == nil ? "Add to Calendar" : "Remove from Calendar")
                }
                Image(systemName: shift.calendarEventID == nil ? "calendar.badge.plus" : "calendar.badge.minus")
            }
        }.tint(Color.clear)
 
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
        }.disabled(!shift.isRepeating)
            .tint(Color.clear)

    }
}
