//
//  ShiftDateManager.swift
//  ShiftTracker
//
//  Created by James Poole on 20/05/23.
//

import Foundation
import CoreData
import SwiftUI

class ShiftDateManager {
    
    // This function filters shifts that start after a given date
    func filterShifts(startingAfter date: Date, from shifts: FetchedResults<OldShift>) -> [OldShift] {
        return shifts.filter { $0.shiftStartDate ?? Date() >= date }
    }

    // This function transforms shifts into details
    func mapShiftsToSingleShift(_ shifts: [OldShift]) -> [singleShift] {
        return shifts.map { singleShift(shift: $0) }.reversed()
    }
    
    func getPreviousMonday() -> Date {
        let today = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: today)
        
        // Calculate the number of days to subtract to get to the previous Monday
        let daysToSubtract = currentWeekday == 1 ? 6 : (currentWeekday == 2 ? 0 : currentWeekday - 2)
        
        // Calculate the date for the previous Monday
        // Calculate the date for the previous Monday without time components
        let previousMondayWithTime = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
        let previousMondayComponents = calendar.dateComponents([.year, .month, .day], from: previousMondayWithTime)
        let previousMonday = calendar.date(from: previousMondayComponents)!
        
        return previousMonday
    }

    func subtractDays(from date: Date, days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: date)!
    }

    func removeTime(from date: Date) -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return Calendar.current.date(from: components)!
    }
    
    
}
