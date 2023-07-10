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
    
    @Published var recentShifts: [singleShift] = []
    @Published var monthlyShifts: [singleShift] = []
    @Published var halfYearlyShifts: [singleShift] = []
    @Published var yearlyShifts: [singleShift] = []
    
    @Published var weeklyTotalPay: Double = 0
    @Published var weeklyTotalHours: Double = 0
    @Published var totalPay: Double = 0
    @Published var totalHours: Double = 0
    @Published var totalShifts: Int = 0
    
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
     func shouldIncludeShift(_ shift: OldShift, jobModel: JobSelectionViewModel) -> Bool {
        if let selectedJobUUID = jobModel.selectedJobUUID {
            return shift.job?.uuid == selectedJobUUID
        }
        return true
    }
    
    // these functions calculate totals for the three key variables in shifts
    
    func addAllTaxedPay(shifts: FetchedResults<OldShift>, jobModel: JobSelectionViewModel) -> Double {
        let total = shifts.filter({ shouldIncludeShift($0, jobModel: jobModel) }).reduce(0) { $0 + $1.taxedPay }
        return Double(round(100*total)/100)
    }

    
     func addAllPay(shifts: FetchedResults<OldShift>, jobModel: JobSelectionViewModel) -> Double {
         let total = shifts.filter({ shouldIncludeShift($0, jobModel: jobModel) }).reduce(0) { $0 + $1.totalPay }
         return Double(round(100*total)/100)
    }
    
    func addAllHours(shifts: FetchedResults<OldShift>, jobModel: JobSelectionViewModel) -> Double {
        let total = shifts.filter({ shouldIncludeShift($0, jobModel: jobModel) }).reduce(0) { $0 + $1.duration }
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
    
    func getAllShifts(from shifts: FetchedResults<OldShift>, jobModel: JobSelectionViewModel) -> [singleShift] {
        
        var allShifts: [singleShift] = []
        
        for shift in shifts {
            if shouldIncludeShift(shift, jobModel: jobModel) {
                allShifts.append(singleShift(shift: shift))
            }
        }
        
        return allShifts.reversed()
        
    }
    
    func getShiftCount(from shifts: FetchedResults<OldShift>, jobModel: JobSelectionViewModel) -> Int {
        
        
        var shiftCount: Int = 0
        
        for shift in shifts {
            if shouldIncludeShift(shift, jobModel: jobModel) {
               shiftCount += 1
            }
        }
        
        return shiftCount
        
    }

    func getLastShifts(from shifts: FetchedResults<OldShift>, jobModel: JobSelectionViewModel, dateRange: DateRange) -> [singleShift] {
        var shiftsByDay: [String: [OldShift]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M/yyyy"

        for shift in shifts {
            if shouldIncludeShift(shift, jobModel: jobModel) {
                let dateKey = formatter.string(from: shift.shiftStartDate!)
                if shiftsByDay[dateKey] != nil {
                    shiftsByDay[dateKey]!.append(shift)
                } else {
                    shiftsByDay[dateKey] = [shift]
                }
            }
        }

        let calendar = Calendar.current
        let today = Date()
        let range = getRange(for: dateRange, using: calendar, and: today)
        var periodShifts: [singleShift] = []
        
        if dateRange == .halfYear {
            
            var shiftsByWeek: [Int: [singleShift]] = [:]
            let weeks = 26
            for i in range {
                let date = calendar.date(byAdding: .day, value: -i, to: today)!
                let dateKey = formatter.string(from: date)
                let shiftsForTheDay = shiftsByDay[dateKey]
                
                if let shifts = shiftsForTheDay {
                    for shift in shifts {
                        let dateComponents = calendar.dateComponents([.weekOfYear], from: shift.shiftStartDate!, to: today)
                        let weekOfYear = dateComponents.weekOfYear!
                        if weekOfYear < weeks {
                            if shiftsByWeek[weekOfYear] != nil {
                                shiftsByWeek[weekOfYear]!.append(singleShift(shift: shift))
                            } else {
                                shiftsByWeek[weekOfYear] = [singleShift(shift: shift)]
                            }
                        }
                    }
                }
            }
            
            for week in 0..<weeks {
                if let shiftsForWeek = shiftsByWeek[week] {
          
                    periodShifts.append(singleShift(shifts: shiftsForWeek))
                }
            }

        } else if dateRange == .year {
            var shiftsByMonth: [Int: [singleShift]] = [:]
                    let months = 12
                    for i in range {
                        let date = calendar.date(byAdding: .day, value: -i, to: today)!
                        let dateKey = formatter.string(from: date)
                        let shiftsForTheDay = shiftsByDay[dateKey]
                        
                        if let shifts = shiftsForTheDay {
                            for shift in shifts {
                                let dateComponents = calendar.dateComponents([.month], from: shift.shiftStartDate!, to: today)
                                let monthOfYear = dateComponents.month!
                                if monthOfYear < months {
                                    if shiftsByMonth[monthOfYear] != nil {
                                        shiftsByMonth[monthOfYear]!.append(singleShift(shift: shift))
                                    } else {
                                        shiftsByMonth[monthOfYear] = [singleShift(shift: shift)]
                                    }
                                }
                            }
                        }
                    }
                    
                    for month in 0..<months {
                        if let shiftsForMonth = shiftsByMonth[month] {
                            periodShifts.append(singleShift(shifts: shiftsForMonth))
                        }
                    }
            
        }
            
            else {
            for i in range {
                let date = calendar.date(byAdding: .day, value: -i, to: today)!
                let dateKey = formatter.string(from: date)
                let shiftsForTheDay = shiftsByDay[dateKey]
                
                if let shifts = shiftsForTheDay {
                    for shift in shifts {
                        periodShifts.append(singleShift(shift: shift))
                    }
                }
            }
        }

        return periodShifts.reversed()
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
    
    
}
