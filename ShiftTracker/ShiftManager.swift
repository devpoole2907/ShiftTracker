//
//  ShiftDateManager.swift
//  ShiftTracker
//
//  Created by James Poole on 20/05/23.
//

import Foundation
import CoreData
import SwiftUI
import Combine

class ShiftDataManager: ObservableObject {
    
    static let shared = ShiftDataManager()
    
    @Published var recentShifts: [singleShift] = []
    @Published var monthlyShifts: [singleShift] = []
    @Published var halfYearlyShifts: [singleShift] = []
    @Published var yearlyShifts: [singleShift] = []
    
    @Published var weeklyTotalPay: Double = 0
    @Published var weeklyTotalHours: Double = 0
    @Published var weeklyTotalBreaksHours: Double = 0
    @Published var totalPay: Double = 0
    @Published var totalHours: Double = 0
    @Published var totalShifts: Int = 0
    @Published var totalBreaksHours: Double = 0
    
    let shiftDataLoaded = PassthroughSubject<Void, Never>()
    
    @Published var statsMode: StatsMode = .earnings
    let statsModes = ["Earnings", "Hours", "Breaks"]
    
    @Published var dateRange: DateRange = .week
    
    @Published var shiftAdded: Bool = false
    
     var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
     func formatTime(timeInHours: Double) -> String {
        let hours = Int(timeInHours)
        let minutes = Int((timeInHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
                formatter.dateFormat = "EEE"
        return formatter
    }
    
    
    
    func deleteShift(_ shift: OldShift, in viewContext: NSManagedObjectContext) {
        viewContext.delete(shift)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting shift: \(error)")
        }
    }
    
    
    // this function determines whether a shift should be included in the current selection of job
     func shouldIncludeShift(_ shift: OldShift, jobModel: JobSelectionManager) -> Bool {
        if let selectedJobUUID = jobModel.selectedJobUUID {
            return shift.job?.uuid == selectedJobUUID
        }
        return true
    }
    
    // these functions calculate totals for the three key variables in shifts
    
    func addAllTaxedPay(shifts: FetchedResults<OldShift>, jobModel: JobSelectionManager) -> Double {
        let total = shifts.filter({ shouldIncludeShift($0, jobModel: jobModel) }).reduce(0) { $0 + $1.taxedPay }
        return Double(round(100*total)/100)
    }

    
     func addAllPay(shifts: FetchedResults<OldShift>, jobModel: JobSelectionManager) -> Double {
         let total = shifts.filter({ shouldIncludeShift($0, jobModel: jobModel) }).reduce(0) { $0 + $1.totalPay }
         return Double(round(100*total)/100)
    }
    
    func addAllHours(shifts: FetchedResults<OldShift>, jobModel: JobSelectionManager) -> Double {
        let total = shifts.filter({ shouldIncludeShift($0, jobModel: jobModel) }).reduce(0) { $0 + $1.duration }
        return total / 3600
    }
    
    func addAllBreaksHours(shifts: FetchedResults<OldShift>, jobModel: JobSelectionManager) -> Double {
        let total = shifts.filter({ shouldIncludeShift($0, jobModel: jobModel) }).reduce(0) { $0 + $1.breakDuration }
        return total / 3600
    }
    
    
    // This function filters shifts that start after a given date
    func filterShifts(startingAfter date: Date, from shifts: FetchedResults<OldShift>) -> [OldShift] {
        return shifts.filter { $0.shiftStartDate ?? Date() >= date }
    }

    // This function transforms shifts into details
    func mapShiftsToSingleShift(_ shifts: [OldShift]) -> [singleShift] {
        return shifts.map { singleShift(shift: $0) }.reversed()
    }


    func subtractDays(from date: Date, days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: date)!
    }

    func removeTime(from date: Date) -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return Calendar.current.date(from: components)!
    }
    
    func getAllShifts(from shifts: FetchedResults<OldShift>, jobModel: JobSelectionManager) -> [singleShift] {
        
        var allShifts: [singleShift] = []
        
        for shift in shifts {
            if shouldIncludeShift(shift, jobModel: jobModel) {
                allShifts.append(singleShift(shift: shift))
            }
        }
        
        return allShifts.reversed()
        
    }
    
    func getShiftCount(from shifts: FetchedResults<OldShift>, jobModel: JobSelectionManager) -> Int {
        
        
        var shiftCount: Int = 0
        
        for shift in shifts {
            if shouldIncludeShift(shift, jobModel: jobModel) {
               shiftCount += 1
            }
        }
        
        return shiftCount
        
    }

    func getLastShifts(from shifts: FetchedResults<OldShift>, jobModel: JobSelectionManager, dateRange: DateRange) -> [singleShift] {
        // Group shifts by day for all cases
        
       // let currentJobShifts = shifts.filter { shouldIncludeShift($0, jobModel: jobModel) }
        
        let shiftsGroupedByDate: [Date: [OldShift]] = Dictionary(grouping: shifts) { shift in
            return Calendar.current.startOfDay(for: shift.shiftStartDate!)
        }

        // Filter only the shifts in the desired range
        let today = Date()
        let startDate = Calendar.current.date(byAdding: dateRange.dateComponent, value: -dateRange.length, to: today)!
        let filteredShifts = shiftsGroupedByDate.filter { $0.key >= startDate && $0.key <= today }
        
        let calendar = Calendar.current
        var periodShifts: [singleShift] = []
        
        switch dateRange {
        case .week, .month:
            // Convert to singleShift
            periodShifts = filteredShifts.flatMap { date, shifts in
                shifts.map { singleShift(shift: $0) }
            }
        case .halfYear:
            // Group shifts by week
            let shiftsGroupedByWeek: [Date: [OldShift]] = Dictionary(grouping: filteredShifts.flatMap { $0.value }) { shift in
                return calendar.startOfDay(for: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shift.shiftStartDate!))!)
            }
            // Convert to singleShift
            periodShifts = shiftsGroupedByWeek.map { date, shifts in
                singleShift(aggregateShifts: shifts, startDate: date)
            }
        case .year:
            // Group shifts by month
            let shiftsGroupedByMonth: [Date: [OldShift]] = Dictionary(grouping: filteredShifts.flatMap { $0.value }) { shift in
                return calendar.date(from: calendar.dateComponents([.year, .month], from: shift.shiftStartDate!))!
            }
            // Convert to singleShift
            periodShifts = shiftsGroupedByMonth.map { date, shifts in
                singleShift(aggregateShifts: shifts, startDate: date)
            }
        }

        return periodShifts.sorted(by: { $0.shiftStartDate < $1.shiftStartDate })
    }






    func getDateRange() -> ClosedRange<Date> {
        var now = Date()
        var components = DateComponents()
        var extraComponent = DateComponents()

        switch dateRange {
        case .week:
            components.day = -7
        case .month:
            components.month = -1
        case .halfYear:
           // extraComponent.month = 1
          //  now = Calendar.current.date(byAdding: extraComponent, to: now) ?? Date()
            components.weekOfYear = -26
        case .year:
            extraComponent.month = 1
            now = Calendar.current.date(byAdding: extraComponent, to: now) ?? Date()
            components.month = -13
        }

        let startDate = Calendar.current.date(byAdding: components, to: now)!
        return startDate...now
    }



    

    func getRange(for dateRange: DateRange, using calendar: Calendar, and date: Date) -> Range<Int> {
        switch dateRange {
        case .week:
            return 0..<7
        case .month:
            let range = calendar.range(of: .day, in: .month, for: date)!
            return 0..<range.count
        case .halfYear:
            return 0..<(30 * 6 * 4)
        case .year:
            return 0..<52
        }
    }


    func getTotalPay<T: Payable>(from shifts: [T]) -> Double {
        return shifts.reduce(0, { $0 + $1.totalPay })
    }
    
    func getTotalHours<T: Payable>(from shifts: [T]) -> Double {
        return shifts.reduce(0, { $0 + $1.hoursCount })
    }
    
    func getTotalBreaksHours<T: Payable>(from shifts: [T]) -> Double {
        return shifts.reduce(0, { $0 + $1.breakDuration })
    }
    
    
   
    
    
    
    
}
