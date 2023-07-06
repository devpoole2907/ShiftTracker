//
//  Enums.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//

import Foundation

public enum StatsMode: Int, CaseIterable {
    case earnings
    case hours
    case breaks

    var description: String {
        switch self {
        case .earnings:
            return "Earnings"
        case .hours:
            return "Hours"
        case .breaks:
            return "Breaks"
        }
    }
}

public enum DateRange: Int, CaseIterable {
    case week
    case month
    case halfYear
    case year

    var shortDescription: String {
        switch self {
        case .week:
            return "W"
        case .month:
            return "M"
        case .halfYear:
            return "6M"
        case .year:
            return "Y"
        }
        
    }
    
    var description: String {
        switch self {
        case .week:
            return "Weekly"
        case .month:
            return "Monthly"
        case .halfYear:
            return "6 Month"
        case .year:
            return "Yearly"
        }
    }
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

public enum ActionType {
    case startBreak, endShift, endBreak, startShift
}

public enum ShiftState {
    case notStarted
    case countdown
    case inProgress
    //case onBreak
}
