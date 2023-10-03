//
//  AggregatedShift.swift
//  ShiftTracker
//
//  Created by James Poole on 3/10/23.
//

import Foundation

struct AggregatedShift {
   let startDate: Date
   let endDate: Date
   let totalHours: Double
   let totalBreaks: Double
   let totalEarnings: Double
   var originalShifts: [OldShift] // The original shifts for navigation
   let historyRange: HistoryRange
   var dailyOrMonthlyAggregates: [DayOrMonthAggregate]
   
   var title: String {
           switch historyRange {
           case .year:
               return "\(yearFormatter.string(from: startDate))"
           case .month:
               return "\(monthFormatter.string(from: startDate))"
           case .week:
               return "\(weekFormatter.string(from: startDate)) - \(weekFormatter.string(from: endDate))"
           }
       }
    
    init(startDate: Date, endDate: Date, totalHours: Double, totalBreaks: Double, totalEarnings: Double, originalShifts: [OldShift], historyRange: HistoryRange, dailyOrMonthlyAggregates: [DayOrMonthAggregate]) {
        self.startDate = startDate
        self.endDate = endDate
        self.totalHours = totalHours
        self.totalBreaks = totalBreaks
        self.totalEarnings = totalEarnings
        self.originalShifts = originalShifts
        self.historyRange = historyRange
        self.dailyOrMonthlyAggregates = dailyOrMonthlyAggregates
    }
   
   private var yearFormatter: DateFormatter = {
       let formatter = DateFormatter()
       formatter.dateFormat = "yyyy"
       return formatter
   }()
   
   private var monthFormatter: DateFormatter = {
       let formatter = DateFormatter()
       formatter.dateFormat = "MMMM yyyy"
       return formatter
   }()
   
   private var weekFormatter: DateFormatter = {
       let formatter = DateFormatter()
       formatter.dateFormat = "MMM d"
       return formatter
   }()
   
}
