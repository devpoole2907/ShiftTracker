//
//  ShiftGroups.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//

import Foundation

public struct singleShift: Identifiable {
    public let id = UUID()
    let hoursCount: Double
    let dayOfWeek: String
    let totalPay: Double
    let breakDuration: Double
    let date: String
    
    init(shift: OldShift) {
        let start = shift.shiftStartDate!
        let end = shift.shiftEndDate!
        self.hoursCount = end.timeIntervalSince(start) / 3600.0
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // set format to display abbreviated day of the week (e.g. "Mon")
        self.dayOfWeek = formatter.string(from: start)
        self.totalPay = shift.totalPay
        
        formatter.dateFormat = "d/M"
                self.date = formatter.string(from: start)
        
        var totalShiftBreakDuration = 0.0
                if let breaks = shift.breaks as? Set<Break> {
                    breaks.forEach { breakInstance in
                        if let breakStartDate = breakInstance.startDate,
                           let breakEndDate = breakInstance.endDate {
                            let breakDuration = breakEndDate.timeIntervalSince(breakStartDate)
                            totalShiftBreakDuration += breakDuration
                        }
                    }
                }
                self.breakDuration = totalShiftBreakDuration / 3600.0
    }
}

public struct fullWeekShifts: Identifiable {
    public let id = UUID()
    let hoursCount: Double
    let totalPay: Double
    let breakDuration: Double
    let startDate: String
    let endDate: String
}
