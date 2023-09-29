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
    
    var shift: SingleScheduledShift
    
    var body: some View {
        Button(role: .destructive) {
            withAnimation {
                scheduleModel.deleteShift(shift, with: shiftStore, using: viewContext)
            }
        } label: {
            Image(systemName: "trash")
        }
        Button(role: .none){
            scheduleModel.selectedShiftToEdit = scheduleModel.fetchScheduledShift(id: shift.id, in: viewContext)
        } label: {
            Image(systemName: "pencil")
        }
        if let selectedShift = scheduleModel.fetchScheduledShift(id: shift.id, in: viewContext){
        Button(role: .none){
           
            if selectedShift.calendarEventID == nil { // an event doesnt exist in the calendar
                
                scheduleModel.addShiftToCalendar(shift: selectedShift, viewContext: viewContext) { (success, error) in
                    if success {
                        print("Successfully added shift to calendar")
                    } else {
                        print("Failed to add shift to calendar: \(String(describing: error?.localizedDescription))")
                    }
                }
            } else { // one does exist
                scheduleModel.deleteEventFromCalendar(eventIdentifier: selectedShift.calendarEventID ?? "")
            }
            
        } label: {
            Image(systemName: "calendar.badge.plus")
        }.tint(Color.pink)
        
    }
        
        Button(role: .cancel) {
            
            CustomConfirmationAlert(action: {
                withAnimation {
                    scheduleModel.cancelRepeatingShiftSeries(shift: shift, with: shiftStore, using: viewContext)
                }
            }, cancelAction: nil, title: "End all future repeating shifts for this shift?").showAndStack()
        } label: {
            Image(systemName: "clock.arrow.2.circlepath")
        }.disabled(!shift.isRepeating)
    }
}
