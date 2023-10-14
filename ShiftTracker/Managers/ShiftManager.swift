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

    @Published var showModePicker = true
    
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
         
         if hours == 0 {
             return "\(minutes)m"
         }
         
        return "\(hours)h \(minutes)m"
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
                formatter.dateFormat = "EEE"
        return formatter
    }
    
    func isWithinLastWeek(date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        return date >= oneWeekAgo
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



    func subtractDays(from date: Date, days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: date)!
    }

    func removeTime(from date: Date) -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return Calendar.current.date(from: components)!
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
        case .year:
            return 0..<52
        }
    }


   
    
    
    
    
}
