//
//  CalendarView.swift
//  ShiftTracker
//
//  Created by James Poole on 18/04/23.
//

import SwiftUI
import CoreData

struct CalendarView: UIViewRepresentable {
    let interval: DateInterval
    @ObservedObject var shiftStore: ScheduledShiftStore
    @Binding var dateSelected: DateComponents?
    @Binding var displayEvents: Bool
    
    
    func makeUIView(context: Context) -> some UICalendarView {
        let view = UICalendarView()
        view.delegate = context.coordinator
        view.calendar = Calendar(identifier: .gregorian)
        view.availableDateRange = interval
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.selectionBehavior = dateSelection
        
        let startDateComponents = view.calendar.dateComponents([.year, .month, .day], from: interval.start)
            dateSelection.setSelected(startDateComponents, animated: true)
        
        context.coordinator.dateSelection = dateSelection
        
       // dateSelection.setSelected(interval.start.dateComponents, animated: true)
        print("date is set to \(startDateComponents)")
        
        //view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return view
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, shiftStore: _shiftStore)
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
        print("I have updated the calendar UI.")
        
        
        
   
            for shift in shiftStore.previousSelectedShifts {
                print("updating decorations for previous selection")
                uiView.reloadDecorations(forDateComponents: [shift.dateComponents], animated: true)
            }
            
            print("shift count is: \(shiftStore.previousSelectedShifts.count)")
            
        
        
        
        for shift in shiftStore.shifts.prefix(60) {
   
                uiView.reloadDecorations(forDateComponents: [shift.dateComponents], animated: true)
            
        }
        
        if let changedEvent = shiftStore.changedShift {
            print("an event was changed.")
   
                uiView.reloadDecorations(forDateComponents: [changedEvent.dateComponents], animated: true)
                shiftStore.changedShift = nil
            
                }
        
        
    }
    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarView
        var dateSelection: UICalendarSelectionSingleDate?
        
        @ObservedObject var shiftStore: ScheduledShiftStore
        
        init(parent: CalendarView, shiftStore: ObservedObject<ScheduledShiftStore>) {
            self.parent = parent
            self._shiftStore = shiftStore
        }
        
        @MainActor
        func calendarView(_ calendarView: UICalendarView,
                          decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            
            
            
            let foundShifts = shiftStore.shifts
                .filter {$0.startDate.startOfDay == dateComponents.date?.startOfDay}
            if foundShifts.isEmpty { return nil }
            
            if foundShifts.count > 1 {
                return .image(UIImage(systemName: "doc.on.doc.fill"),
                              color: calendarView.traitCollection.userInterfaceStyle == .dark ? .white : .black,
                              size: .large)
            }
            let singleShift = foundShifts.first!
        
            
            
            let job = singleShift.job
                            
            let color = UIColor(red: CGFloat(job?.colorRed ?? 0.0 ),
                                green: CGFloat(job?.colorGreen ?? 0.0 ),
                                blue: CGFloat(job?.colorBlue ?? 0.0 ),
                                                alpha: 1)
                            
            return .image(UIImage(systemName: job?.icon ?? "briefcase.circle"),
                                          color: color,
                                          size: .large)
            
            
        }
    
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
              parent.dateSelected = dateComponents
            
            if dateComponents == nil {
                        // User has deselected a date, so reselect the current date
                        let currentDateComponents = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: Date())
                        dateSelection?.setSelected(currentDateComponents, animated: true)
                    }
            
            guard let dateComponents else { return }
            
            
            let foundEvents = shiftStore.shifts
                .filter {$0.startDate.startOfDay == dateComponents.date?.startOfDay}
            if !foundEvents.isEmpty {
                  parent.displayEvents.toggle()
            }
            
            print("the tapped date is : \(dateComponents)")
            
            
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate,
                           canSelectDate dateComponents: DateComponents?) -> Bool {
            return true
        }
        
        
    }
    
}
