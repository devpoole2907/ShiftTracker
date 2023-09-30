//
//  HistoryViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 6/09/23.
//

import Foundation
import CoreData
import SwiftUI

class HistoryViewModel: ObservableObject {
    
    
    @Published var historyRange: HistoryRange = .week
    @Published var selectedTab: Int = 0 // To keep track of the selected tab
    @Published var groupedShifts: [GroupedShifts] = []
    
    
    let calendar = Calendar.current
    
    @Published var chartSelection: Date?
    @Published var selectedDate: Date?
    @Published var aggregateValue: Double = 0.0
    
    
    
    @Published var chartYSelection: Double?
    
    @Published var selection = Set<NSManagedObjectID>()
    
    func formatAggregate(aggregateValue: Double, shiftManager: ShiftDataManager) -> String {
        
        switch shiftManager.statsMode {
        case .earnings:
            return "$\(String(format: "%.2f", aggregateValue))"
        case .hours:
            print("aggregate value when formatting time is: \(aggregateValue)")
            return shiftManager.formatTime(timeInHours: aggregateValue)
        default:
            return shiftManager.formatTime(timeInHours: aggregateValue)
        }
        
        
    }
    
    func computeAggregateValue(for selectedDate: Date, in shifts: [OldShift], statsMode: StatsMode) -> Double {
        var aggregateValue = 0.0

        // Extract the relevant date components of the selected date
        let selectedDateComponents = chartSelectionComponent(date: selectedDate)
        
        // Loop through all shifts to find the ones that match the selected date (or month if the date range is a year)
        for shift in shifts {
            
            // Extract the relevant date components of each shift's start date
            let shiftStartDateComponents = chartSelectionComponent(date: shift.shiftStartDate ?? Date())
            
            // Check if the selected date matches the shift's date
            if selectedDateComponents == shiftStartDateComponents {
                
                // Update the aggregate value based on the current stats mode
                if statsMode == .earnings {
                    aggregateValue += shift.totalPay
                } else if statsMode == .hours {
                    aggregateValue += shift.duration / 3600.0
                } else {
                    aggregateValue += shift.breakDuration / 3600.0
                }
            }
        }
        
        return aggregateValue
    }

    
    
    func generateSampleShifts() -> [OldShift] {
        var shifts: [OldShift] = []
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
        
        for i in 0..<64 {
            let shift = OldShift(context: PersistenceController.preview.container.viewContext) 
            shift.shiftStartDate = Calendar.current.date(byAdding: .day, value: i, to: oneMonthAgo)
            shift.totalPay = Double(100 + (i * 5))
            shifts.append(shift)
        }
        return shifts
    }
    
    func convertToGroupedShifts(from dictionary: [(key: Date, value: [OldShift])]) -> [GroupedShifts] {

        var newGroupedShifts: [GroupedShifts] = []
        
        // Convert to use the GroupedShifts struct.
        for (key, shifts) in dictionary {
            var title: String
            let dateFormatter = DateFormatter()
            var startDate: Date = Date()
            
            switch historyRange {
            case .week:
                 startDate = key
                let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate)!
                dateFormatter.dateFormat = "MMM d"
                let startDateString = dateFormatter.string(from: startDate)
                dateFormatter.dateFormat = "d"
                let endDateString = dateFormatter.string(from: endDate)
                title = "\(startDateString) - \(endDateString)"
                
            case .month:
                 startDate = key
                dateFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
                title = dateFormatter.string(from: startDate)
                
            case .year:
                 startDate = key
                dateFormatter.setLocalizedDateFormatFromTemplate("yyyy")
                title = dateFormatter.string(from: startDate)
            }
            
            let newGroup = GroupedShifts(title: title, shifts: shifts, startDate: startDate)
            newGroupedShifts.append(newGroup)
        }
        
        return newGroupedShifts
    }

    
    func getCurrentDateRangeString() -> String {
        guard groupedShifts.count > 0 else { return "" }
        guard selectedTab < groupedShifts.count else { return "" }
        
        return groupedShifts[selectedTab].title
    }
    
    
    func getDateRange(startDate: Date) -> ClosedRange<Date> {
        
        var endDate = Date()
        
        switch historyRange {
            
        case .week:
            endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        case .month:
            endDate = Calendar.current.date(byAdding: .day, value: 29, to: startDate)!
        case .year:
            endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
        }
        
        
        
        return startDate.addingTimeInterval(-10000)...endDate
    }
    
    func chartSelectionComponent(date: Date?) -> DateComponents {
        
        switch historyRange {
        case .week:
            return calendar.dateComponents([.year, .month, .day], from: date ?? .distantPast)
        case .month:
            return calendar.dateComponents([.year, .month, .day], from: date ?? .distantPast)
        case .year:
            return calendar.dateComponents([.year, .month], from: date ?? .distantPast)
        }
        
    }
    
    func getGroupingKey(for shift: OldShift) -> Date {
        let components: Set<Calendar.Component>
        switch historyRange {
        case .week:
            components = [.yearForWeekOfYear, .weekOfYear]
        case .month:
            components = [.year, .month]
        case .year:
            components = [.year]
        }
        return calendar.startOfDay(for: calendar.date(from: calendar.dateComponents(components, from: shift.shiftStartDate!))!)
    }
    
    func backButtonAction() {
        
        if selectedTab != 0 {
        withAnimation{
            selectedTab = selectedTab - 1
        }
    }
        
    }
    
    func forwardButtonAction() {
        
        if selectedTab != groupedShifts.count - 1 {
            withAnimation {
                selectedTab = selectedTab + 1
            }
        }
        
    }
    
    
    
    
    
}

struct GroupedShifts {
    var title: String
    var shifts: [OldShift]
    var startDate: Date
}
