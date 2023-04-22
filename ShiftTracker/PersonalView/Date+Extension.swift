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
    
    var dateComponents: DateComponents {
            let calendar = Calendar.current
            return calendar.dateComponents([.year, .month, .day], from: self)
        }
    
}
