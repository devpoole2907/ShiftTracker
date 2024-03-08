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
    
    @Published var aggregatedShifts: [AggregatedShift] = []
    var lastKnownShiftCount: Int = 0
    
    
    let calendar = Calendar.current
    
    @Published var chartSelection: Date? = nil
    @Published var visibleShifts: [OldShift]? = nil
    
    @Published var isAnimating = false
    
    @Published var selectedDate: Date? = nil
    @Published var aggregateValue: Double = 0.0
    
    @Published var appeared: Bool = false
    
    @Published var showLargeIcon: Bool = true
    
    @Published var chartYSelection: Double? = nil
    
    @Published var selection = Set<NSManagedObjectID>()
    
    @Published var showExportView = false
    @Published var showingProView = false
    @Published var showInvoiceView = false
    
   lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        switch historyRange {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "dd/M"
        case .year:
            formatter.dateFormat = "MMMM"
        }

        return formatter
    }()
    
    func checkTitlePosition(geometry: GeometryProxy) {
        let minY = geometry.frame(in: .global).minY
        showLargeIcon = minY > 100  // adjust this threshold as needed
    }

    
    func getCurrentDateRangeString() -> String {
        guard aggregatedShifts.count > 0 else { return "" }
        guard selectedTab < aggregatedShifts.count else { return "" }
        
        return aggregatedShifts[selectedTab].title
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
        
        if selectedTab != aggregatedShifts.count - 1 {
            withAnimation {
                selectedTab = selectedTab + 1
            }
        }
        
    }
    
    func generateAggregatedShifts(from shifts: FetchedResults<OldShift>, using selectedJobManager: JobSelectionManager) -> [AggregatedShift] {
        
        let shiftManager = ShiftDataManager.shared
        
        var aggregatedShifts: [AggregatedShift] = []

     
            let filteredShifts = shifts.filter { shiftManager.shouldIncludeShift($0, jobModel: selectedJobManager) }

        let groupedShifts = Dictionary(grouping: filteredShifts) { (shift) -> Date in
            return getGroupingKey(for: shift)
        }
        
        


        for (groupKey, groupShifts) in groupedShifts {

            
            let dailyOrMonthlyAggregates = calculateDayOrMonthAggregates(from: groupShifts)
            
            let totalHours = groupShifts.reduce(0) { $0 + ($1.duration / 3600.0) }
            let totalBreaks = groupShifts.reduce(0) { $0 + ($1.breakDuration / 3600.0) }
            let totalEarnings = groupShifts.reduce(0) { $0 + $1.totalPay }

          
            let endDate = getEndDate(from: groupKey)
            let aggregatedShift = AggregatedShift(startDate: groupKey, endDate: endDate, totalHours: totalHours, totalBreaks: totalBreaks, totalEarnings: totalEarnings, originalShifts: groupShifts, historyRange: historyRange, dailyOrMonthlyAggregates: dailyOrMonthlyAggregates)
            
            aggregatedShifts.append(aggregatedShift)
        }

        return aggregatedShifts.sorted(by: { $0.startDate < $1.startDate })
    }
    
    func updateAggregatedShift(afterDeleting shift: OldShift, at index: Int) {
        let oldAggregatedShift = aggregatedShifts[index]
        let newAggregatedShift = recalculateAggregatedShift(afterDeleting: shift, from: oldAggregatedShift)
        aggregatedShifts[index] = newAggregatedShift
    }

    func recalculateAggregatedShift(afterDeleting shift: OldShift, from aggregatedShift: AggregatedShift) -> AggregatedShift {
        
        let remainingShifts = aggregatedShift.originalShifts.filter { $0 != shift }

        
        let totalHours = remainingShifts.reduce(0) { $0 + ($1.duration / 3600.0) }
        let totalBreaks = remainingShifts.reduce(0) { $0 + ($1.breakDuration / 3600.0) }
        let totalEarnings = remainingShifts.reduce(0) { $0 + $1.totalPay }


        let dayOrMonthAggregates = calculateDayOrMonthAggregates(from: remainingShifts)


        let updatedAggregatedShift = AggregatedShift(startDate: aggregatedShift.startDate,
                                                     endDate: aggregatedShift.endDate,
                                                     totalHours: totalHours,
                                                     totalBreaks: totalBreaks,
                                                     totalEarnings: totalEarnings,
                                                     originalShifts: remainingShifts,
                                                     historyRange: aggregatedShift.historyRange,
                                                     dailyOrMonthlyAggregates: dayOrMonthAggregates)
        
        return updatedAggregatedShift
    }
    
    func calculateDayOrMonthAggregates(from shifts: [OldShift]) -> [DayOrMonthAggregate] {
        var dayOrMonthAggregates: [DayOrMonthAggregate] = []

        
        switch historyRange {
        case .week, .month:
            let dayGroupedShifts = Dictionary(grouping: shifts, by: { calendar.startOfDay(for: $0.shiftStartDate!) })
            
            for (day, dayShifts) in dayGroupedShifts {
                let totalHours = dayShifts.reduce(0, { $0 + ($1.duration / 3600.0) })
                let totalBreaks = dayShifts.reduce(0, { $0 + ($1.breakDuration / 3600.0) })
                let totalEarnings = dayShifts.reduce(0, { $0 + $1.totalPay })
                dayOrMonthAggregates.append(DayOrMonthAggregate(date: day, totalEarnings: totalEarnings, totalHours: totalHours, totalBreaks: totalBreaks, historyRange: historyRange, calendar: calendar))
            }
            
        case .year:
            let monthGroupedShifts = Dictionary(grouping: shifts, by: { (shift) -> Date in
                let components = calendar.dateComponents([.year, .month], from: shift.shiftStartDate!)
                return calendar.date(from: components)!
            })
            
            for (month, monthShifts) in monthGroupedShifts {
                let totalHours = monthShifts.reduce(0, { $0 + ($1.duration / 3600.0) })
                let totalBreaks = monthShifts.reduce(0, { $0 + ($1.breakDuration / 3600.0) })
                let totalEarnings = monthShifts.reduce(0, { $0 + $1.totalPay })
                dayOrMonthAggregates.append(DayOrMonthAggregate(date: month, totalEarnings: totalEarnings, totalHours: totalHours, totalBreaks: totalBreaks, historyRange: historyRange, calendar: calendar))
            }
        }
        
        return dayOrMonthAggregates
    }


    
    func getEndDate(from startDate: Date) -> Date {
        let calendar = Calendar.current
        switch historyRange {
        case .week:
            return calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        case .month:
            return calendar.date(byAdding: .month, value: 1, to: startDate)?.addingTimeInterval(-1) ?? startDate
        case .year:
            return calendar.date(byAdding: .year, value: 1, to: startDate)?.addingTimeInterval(-1) ?? startDate
        }
    }

    
    
}



