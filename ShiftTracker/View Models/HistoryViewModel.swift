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
    let calendar = Calendar.current
    
    @Published var chartSelection: Date?
    @Published var chartYSelection: Double?
    
    @Published var selection = Set<NSManagedObjectID>()
    
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
    
    func getCurrentDateRangeString(groupedShifts: [(key: Date, value: [OldShift])]) -> String {
        
        let dateFormatter = DateFormatter()
        
        switch historyRange {
        case .week:
            guard groupedShifts.count > 0 else { return "" }
            guard selectedTab < groupedShifts.count else { return "" }
            let startDate = groupedShifts[selectedTab].key
            let endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!
            dateFormatter.dateFormat = "MMM d"
            let startDateString = dateFormatter.string(from: startDate)
            dateFormatter.dateFormat = "d"
            let endDateString = dateFormatter.string(from: endDate)
            return "\(startDateString) - \(endDateString)"
            
        case .month:
            guard selectedTab < groupedShifts.count else { return "" }
            let startDate = groupedShifts[selectedTab].key
            dateFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
            return dateFormatter.string(from: startDate)
            
        case .year:
            guard selectedTab < groupedShifts.count else { return "" }
            let startDate = groupedShifts[selectedTab].key
            dateFormatter.setLocalizedDateFormatFromTemplate("yyyy")
            return dateFormatter.string(from: startDate)
        }
    }
    
    
    func getDateRange(startDate: Date) -> ClosedRange<Date> {
        
        var endDate = Date()
        
        switch historyRange {
            
        case .week:
            endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        case .month:
            endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
        case .year:
            endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
        }
        
        
        
        return startDate...endDate
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
    
    func forwardButtonAction(groupedShifts: [(key: Date, value: [OldShift])]) {
        
        if selectedTab != groupedShifts.count - 1 {
            withAnimation {
                selectedTab = selectedTab + 1
            }
        }
        
    }
    
    
    
}
