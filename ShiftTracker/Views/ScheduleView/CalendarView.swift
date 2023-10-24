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
    @ObservedObject var shiftStore: ShiftStore
    
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    
    
    func makeUIView(context: Context) -> some UICalendarView {
        let view = UICalendarView()
        view.delegate = context.coordinator
        view.calendar = Calendar(identifier: .gregorian)
        view.availableDateRange = interval
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.selectionBehavior = dateSelection
        
        let visibleDate = view.visibleDateComponents
        
        print("visible date is \(visibleDate.date)")
        
        let startDateComponents = view.calendar.dateComponents([.year, .month, .day], from: interval.start)
            dateSelection.setSelected(startDateComponents, animated: true)
        
        context.coordinator.dateSelection = dateSelection
        
       
        
        dateSelection.setSelected(Date().dateComponents, animated: true)
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

        let calendar = Calendar.current
        let visibleDate = uiView.visibleDateComponents.date!
        let futureDate = calendar.date(byAdding: .day, value: 31, to: visibleDate)!

        let relevantShifts = shiftStore.shifts.filter { shift in
            let shiftDate = shift.dateComponents.date!
            return shiftDate >= visibleDate && shiftDate <= futureDate
        }

        for shift in relevantShifts {
            uiView.reloadDecorations(forDateComponents: [shift.dateComponents], animated: true)
        }

        if let changedEvent = shiftStore.changedShift {
            let changedEventDate = changedEvent.dateComponents.date!

            if changedEventDate >= visibleDate && changedEventDate <= futureDate {
                print("an event was changed.")
                uiView.reloadDecorations(forDateComponents: [changedEvent.dateComponents], animated: true)
                shiftStore.changedShift = nil
            }
        }

        if let changedEvents = shiftStore.batchDeletedShifts {
            for changedEvent in changedEvents {
                let changedEventDate = changedEvent.dateComponents.date!

                if changedEventDate >= visibleDate && changedEventDate <= futureDate {
                    uiView.reloadDecorations(forDateComponents: [changedEvent.dateComponents], animated: true)
                    shiftStore.batchDeletedShifts = nil
                }
            }
        }
        
        for changedEvent in shiftStore.previousSelectedShifts {
            let changedEventDate = changedEvent.dateComponents.date!
            if changedEventDate >= visibleDate && changedEventDate <= futureDate {
                uiView.reloadDecorations(forDateComponents: [changedEvent.dateComponents], animated: true)
                shiftStore.previousSelectedShifts = []
            }
            
        }
        
    
        
        
        if let selectedDate = scheduleModel.dateSelected?.date {
                if selectedDate >= visibleDate && selectedDate <= futureDate {
                    uiView.reloadDecorations(forDateComponents: [scheduleModel.dateSelected!], animated: true)
                }
            }
        
        
    }


    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarView
        var dateSelection: UICalendarSelectionSingleDate?
        
        @ObservedObject var shiftStore: ShiftStore
        
        init(parent: CalendarView, shiftStore: ObservedObject<ShiftStore>) {
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
            
            
            let currentDate = Date()
let isBeforeNow = singleShift.endDate > currentDate

let color = UIColor(red: CGFloat(job?.colorRed ?? 0.0 ),
                    green: CGFloat(job?.colorGreen ?? 0.0 ),
                    blue: CGFloat(job?.colorBlue ?? 0.0 ),
                    alpha: isBeforeNow ? 1 : 0.5)

return .image(UIImage(systemName: job?.icon ?? "briefcase.fill"),
              color: color,
              size: .large)
            
            
        }
    
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            withAnimation{
                parent.scheduleModel.dateSelected = dateComponents
            }
            
         //   print("setting date selected to \(dateComponents?.date)")
            
           if dateComponents == nil {
                        // User has deselected a date, so reselect the current date
                        let currentDateComponents = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: Date())
                        dateSelection?.setSelected(currentDateComponents, animated: true)
               parent.scheduleModel.dateSelected = Date().dateComponents
                    }
            
            guard let dateComponents else { return }
            
            
            let foundEvents = shiftStore.shifts
                .filter {$0.startDate.startOfDay == dateComponents.date?.startOfDay}
            if !foundEvents.isEmpty {
     
                parent.scheduleModel.displayEvents.toggle()
                
            }
            
          //  print("the tapped date is : \(dateComponents.date)")
            
            
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate,
                           canSelectDate dateComponents: DateComponents?) -> Bool {
            return true
        }
        
        
    }
    
}
