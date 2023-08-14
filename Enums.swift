//
//  Enums.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//

import Foundation

public enum Field: Hashable {
    case field1, field2, field3
}

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
            return "6M"
        case .year:
            return "Yearly"
        }
    }

    var dateComponent: Calendar.Component {
        switch self {
        case .week:
            return .day
        case .month:
            return .month
        case .halfYear:
            return .weekOfYear
        case .year:
            return .month
        }
    }

    var length: Int {
        switch self {
        case .week:
            return 7
        case .month:
            return 1
        case .halfYear:
            return 26
        case .year:
            return 13
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

public enum CustomColor {
    
    case customUIColorPicker
    
    case customTextColorPicker
    
    case earningsColorPicker
    
    case taxColorPicker
    
    case timerColorPicker
    
    case breaksColorPicker
    
    case tipsColorPicker
}

public enum ActiveSheet: Identifiable {
    case detailSheet, startBreakSheet, endShiftSheet, endBreakSheet, startShiftSheet
    
    public var id: Int {
        hashValue
    }
}
