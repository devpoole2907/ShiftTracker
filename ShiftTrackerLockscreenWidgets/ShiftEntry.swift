//
//  ShiftEntry.swift
//  ShiftTrackerLockscreenWidgetsExtension
//
//  Created by James Poole on 30/07/23.
//

import Foundation
import WidgetKit

struct ShiftEntry: TimelineEntry {
    let date: Date
    let shiftStartDate: Date?
    let totalPay: Double
    let taxedPay: Double
    let isOnBreak: Bool // we need this to hide the pay when on break, easier to just do this rather than figure out calculations
    
    
}
