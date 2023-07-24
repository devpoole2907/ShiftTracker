//
//  Date+Extension.swift
//  ShiftTracker
//
//  Created by James Poole on 22/04/23.
//

import Foundation

extension Date {
    func diff(numDays: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: numDays, to: self)!
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
            let startOfNextDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            return startOfNextDay.addingTimeInterval(-1)
        }
    
    var dateComponents: DateComponents {
            let calendar = Calendar.current
            return calendar.dateComponents([.year, .month, .day], from: self)
        }
    
}
