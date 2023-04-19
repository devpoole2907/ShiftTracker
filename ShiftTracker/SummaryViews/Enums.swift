//
//  Enums.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//

import Foundation

public enum StatsMode {
    case earnings
    case hours
    case breaks
}

public enum ChartDataType {
    case hoursCount
    case totalPay
    case breakDuration
    
    var yAxisTitle: String {
        switch self {
        case .hoursCount:
            return "Hours Worked"
        case .totalPay:
            return "Total Pay"
        case .breakDuration:
            return "Break Duration"
        }
    }
}

public enum ChartDateType {
    case day
    case date
    
}
