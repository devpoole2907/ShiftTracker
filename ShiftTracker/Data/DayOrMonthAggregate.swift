//
//  DayOrMonthAggregate.swift
//  ShiftTracker
//
//  Created by James Poole on 3/10/23.
//

import Foundation

struct DayOrMonthAggregate: Hashable, Identifiable {
    
    public var id: Int {
        hashValue
    }
    
    var date: Date
   
       var totalEarnings: Double
  
       var totalHours: Double
       var totalBreaks: Double
    
    let historyRange: HistoryRange
        
    let calendar: Calendar
    
    var formattedDate: String {
        
        let dateFormatter = DateFormatter()
           
        switch historyRange {
        case .week:
            dateFormatter.dateFormat = "EEEE"
        case .month:
            dateFormatter.dateFormat = "dd MMM YYYY"
        case .year:
            dateFormatter.dateFormat = "MMMM"
        }
        
        return dateFormatter.string(from: date)
        }
    
    var formattedHours: String {
        let hours = Int(totalHours)
        let minutes = Int((totalHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }
    
    var formattedBreaks: String {
        let hours = Int(totalBreaks)
        let minutes = Int((totalBreaks - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }
    
    
    var formattedEarnings: String {
            return "$\(String(format: "%.2f", totalEarnings))"
        }
    
    
    init(date: Date, totalEarnings: Double, totalHours: Double, totalBreaks: Double, historyRange: HistoryRange, calendar: Calendar) {
        self.date = date
        self.totalEarnings = totalEarnings
        self.calendar = calendar
        self.historyRange = historyRange
        self.totalHours = totalHours
        self.totalBreaks = totalBreaks
    }

    
}
