//
//  ShiftToChart.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import Foundation

struct ShiftToChart: Identifiable {
    let id = UUID()
    let hoursCount: Double
    let earnings: Double
    let dayOfWeek: Date
    
    init(shift: OldShift) {
        let start = shift.shiftStartDate!
        let end = shift.shiftEndDate!
        self.hoursCount = shift.duration / 3600.0
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // set format to display abbreviated day of the week (e.g. "Mon")
        self.dayOfWeek = start
        
        self.earnings = shift.totalPay
    }
}
