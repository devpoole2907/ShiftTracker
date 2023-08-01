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
    let shiftStartDate: Date
    var animate: Bool = false
    
    init(shift: OldShift) {
        let start = shift.shiftStartDate!
        let end = shift.shiftEndDate!
        self.hoursCount = end.timeIntervalSince(start) / 3600.0
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // set format to display abbreviated day of the week (e.g. "Mon")
        self.dayOfWeek = formatter.string(from: start)
        self.totalPay = shift.totalPay
        
        formatter.dateFormat = "dd/MM/YYYY"
                self.date = formatter.string(from: start)
        
       /* var totalShiftBreakDuration = 0.0
                if let breaks = shift.breaks as? Set<Break> {
                    breaks.forEach { breakInstance in
                        if let breakStartDate = breakInstance.startDate,
                           let breakEndDate = breakInstance.endDate {
                            let breakDuration = breakEndDate.timeIntervalSince(breakStartDate)
                            totalShiftBreakDuration += breakDuration
                        }
                    }
                } */
        self.breakDuration = shift.breakDuration / 3600.0
        
        self.shiftStartDate = shift.shiftStartDate!
        
    }
    
    init(date: Date) {
            self.hoursCount = 0
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE" // set format to display abbreviated day of the week (e.g. "Mon")
            self.dayOfWeek = formatter.string(from: date)
            self.totalPay = 0
            formatter.dateFormat = "dd/MM/YYYY"
            self.date = formatter.string(from: date)
            self.breakDuration = 0
        self.shiftStartDate = date
        }
    
    init(shifts: [singleShift]) {
            self.hoursCount = shifts.reduce(0, { $0 + $1.hoursCount })
            self.totalPay = shifts.reduce(0, { $0 + $1.totalPay })
            self.breakDuration = shifts.reduce(0, { $0 + $1.breakDuration })
            self.dayOfWeek = shifts[0].dayOfWeek
            self.date = shifts[0].date
            self.shiftStartDate = shifts[0].shiftStartDate
        }
    
    init(aggregateShifts: [OldShift], startDate: Date) {
        // Sum of all properties
        self.hoursCount = aggregateShifts.reduce(0, { $0 + $1.shiftEndDate!.timeIntervalSince($1.shiftStartDate!) / 3600.0 })
        self.totalPay = aggregateShifts.reduce(0, { $0 + $1.totalPay })
        self.breakDuration = aggregateShifts.reduce(0, { $0 + $1.breakDuration / 3600.0 })

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        self.dayOfWeek = formatter.string(from: startDate)

        formatter.dateFormat = "dd/MM/YYYY"
        self.date = formatter.string(from: startDate)

        self.shiftStartDate = startDate
    }

    
}

public struct ShiftWeek: Identifiable {
    public let id = UUID()
    let hoursCount: Double
    let totalPay: Double
    let breakDuration: Double
    let date: String
    let weekStartDate: Date
    var animate: Bool = false
    
    init(shifts: [singleShift]) {
        self.hoursCount = shifts.reduce(0, { $0 + $1.hoursCount })
        self.totalPay = shifts.reduce(0, { $0 + $1.totalPay })
        self.breakDuration = shifts.reduce(0, { $0 + $1.breakDuration })
        
        let firstShiftDate = shifts.first?.date
        self.date = firstShiftDate ?? ""
        self.weekStartDate = shifts.first!.shiftStartDate
    }
    
    init(date: Date){
        self.hoursCount = 0
        self.totalPay = 0
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"
        self.date = formatter.string(from: date)
        self.breakDuration = 0
        self.weekStartDate = date
    }
}

public struct ShiftMonth: Identifiable {
    public let id = UUID()
    let hoursCount: Double
    let totalPay: Double
    let breakDuration: Double
    let monthOfYear: String
    let date: Date
    var animate: Bool = false
    
    init(shifts: [singleShift]) {
        self.hoursCount = shifts.reduce(0, { $0 + $1.hoursCount })
        self.totalPay = shifts.reduce(0, { $0 + $1.totalPay })
        self.breakDuration = shifts.reduce(0, { $0 + $1.breakDuration })
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy" // set format to display abbreviated month and year (e.g. "Jan 2023")
        self.monthOfYear = formatter.string(from: shifts.first?.shiftStartDate ?? Date())
        self.date = shifts.first!.shiftStartDate
    }
    
    init(date: Date) {
        self.hoursCount = 0
        self.totalPay = 0
        self.breakDuration = 0
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy" // set format to display abbreviated month and year (e.g. "Jan 2023")
        self.monthOfYear = formatter.string(from: date)
        self.date = date
    }
}

protocol Payable {
    var totalPay: Double { get }
    var hoursCount: Double { get }
    var breakDuration: Double { get }
}

extension singleShift: Payable {}
extension ShiftWeek: Payable {}
extension ShiftMonth: Payable {}


public struct fullWeekShifts: Identifiable {
    public let id = UUID()
    let hoursCount: Double
    let totalPay: Double
    let breakDuration: Double
    let startDate: String
    let endDate: String
}
