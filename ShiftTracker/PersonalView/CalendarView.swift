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
    @Binding var dateSelected: DateComponents?
    @Binding var displayEvents: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(entity: ScheduledShift.entity(),
                      sortDescriptors: [],
                      animation: .default)
        private var scheduledShifts: FetchedResults<ScheduledShift>
    
    func makeUIView(context: Context) -> some UICalendarView {
        let view = UICalendarView()
        view.delegate = context.coordinator
        view.calendar = Calendar(identifier: .gregorian)
        view.availableDateRange = interval
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.selectionBehavior = dateSelection
        return view
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, viewContext: viewContext)
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        var dateComponentsSet = Set<DateComponents>()

            for scheduledShift in scheduledShifts {
                guard let dateComponents = scheduledShift.startDate?.dateComponents else { continue }
                dateComponentsSet.insert(dateComponents)
            }

            // Convert the Set back to an array
            let dateComponents = Array(dateComponentsSet)

            uiView.reloadDecorations(forDateComponents: dateComponents, animated: true)
    }
    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarView
        
        let viewContext: NSManagedObjectContext
        
        init(parent: CalendarView, viewContext: NSManagedObjectContext) {
            self.parent = parent
            self.viewContext = viewContext
        }
        
        @MainActor
        func calendarView(_ calendarView: UICalendarView,
                          decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        
            let fetchRequest: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
                
                // Filter by start date
                if let date = dateComponents.date?.startOfDay {
                    fetchRequest.predicate = NSPredicate(format: "startDate >= %@ AND startDate < %@",
                                                         argumentArray: [date, date.addingTimeInterval(24 * 60 * 60)])
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true),
                                                    NSSortDescriptor(key: "objectID", ascending: true)]

                }
            
            do {
                    // Execute the fetch request
                    let scheduledShifts = try viewContext.fetch(fetchRequest)
                    
                    if scheduledShifts.isEmpty { return nil }
                
                if scheduledShifts.count > 1 {
                                return .image(UIImage(systemName: "doc.on.doc.fill"),
                                              color: .orange,
                                              size: .medium)
                            }
                
                    
                let job = scheduledShifts.first!.job
                
                let color = UIColor(red: CGFloat(job?.colorRed ?? 0),
                                            green: CGFloat(job?.colorGreen ?? 0),
                                            blue: CGFloat(job?.colorBlue ?? 0),
                                            alpha: 1)
                        
                        return .image(UIImage(systemName: "briefcase.fill"),
                                      color: color,
                                      size: .large)
                } catch {
                    print("Failed to fetch ScheduledShifts: \(error)")
                    return nil
                }
                     
            
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate,
                           didSelectDate dateComponents: DateComponents?) {
            parent.dateSelected = dateComponents
            guard let dateComponents else { return }
                parent.displayEvents.toggle()
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate,
                           canSelectDate dateComponents: DateComponents?) -> Bool {
            return true
        }
        
    }
    
    
}
