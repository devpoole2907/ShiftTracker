//
//  Enums.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//

import Foundation
import SwiftUI

public enum Field: Hashable {
    case field1, field2, field3
}

public enum SegmentedContentType {
    case image(String)
    case text(String)
}

protocol SegmentedItem: Hashable {
    var contentType: SegmentedContentType { get }
}

enum ActiveCover: Identifiable {
    public var id: Int {
        hashValue
    }
    
    case lockedView, jobView
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
    
    var image: String {
        switch self {
        case .earnings:
            return "dollarsign.circle.fill"
        case .hours:
            return "clock.fill"
        case .breaks:
            return "bed.double.fill"
            
        }
        
        
    }
    
    var color: Color {
        
        switch self {
        case .earnings:
            return Color.green
        case .hours:
            return Color.orange
        case .breaks:
            return Color.indigo
        }
        
    }
    
    var gradient: LinearGradient {
            switch self {
            case .earnings:
                return LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 198 / 255, green: 253 / 255, blue: 80 / 255),
                        Color(red: 112 / 255, green: 218 / 255, blue: 65 / 255)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom)
            case .hours:
                return LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom)
            case .breaks:
                return LinearGradient(
                    gradient: Gradient(colors: [Color.indigo, Color.purple]),
                    startPoint: .top,
                    endPoint: .bottom)
            }
        
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .earnings:
            return 10
        case .breaks:
            return 5
        case .hours:
            return 5
        }
    }
    
    
}


public enum HistoryRange: Int, CaseIterable {
    
    case week
    case month
    case year
    
    var shortDescription: String {
        switch self {
        case .week:
            return "Week"
        case .month:
            return "Month"
        case .year:
            return "Year"
        }
    }
    
    var initial: String {
        switch self {
        case .week:
            return "W"
        case .month:
            return "M"
        case .year:
            return "Y"
        }
    }
    
    
}

extension StatsMode: SegmentedItem {
    var contentType: SegmentedContentType {
        .image(image) 
    }
}

extension HistoryRange: SegmentedItem {
    var contentType: SegmentedContentType {
        .text(initial)
    }
}




public enum DateRange: Int, CaseIterable {
    case week
    case month
    case year

    var shortDescription: String {
        switch self {
        case .week:
            return "W"
        case .month:
            return "M"
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

enum JobViewActiveSheet: Identifiable {
    case overtimeSheet, symbolSheet, breakRemindSheet
    
    var id: Int {
        hashValue
    }
}

enum ActiveOverviewSheet: Identifiable {
    case addShiftSheet, configureExportSheet, symbolSheet
    
    var id: Int {
        hashValue
    }
}

enum ActiveScheduleSheet: Identifiable {
    case pastShiftSheet, scheduleSheet, configureExportSheet
    
    var id: Int {
        hashValue
    }
}

enum ReminderTime: String, CaseIterable, Identifiable {
    case oneMinute = "1m before"
    case fifteenMinutes = "15m before"
    case thirtyMinutes = "30m before"
    case oneHour = "1hr before"
    
    var id: String { self.rawValue }
    var timeInterval: TimeInterval {
        switch self {
        case .oneMinute:
            return 60
        case .fifteenMinutes:
            return 15 * 60
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        }
    }
}

enum Tab: String, CaseIterable {
    case home = "Home"
    case timesheets = "Timesheets"
    case schedule = "Schedule"
    case settings = "Settings"
    
    var image: String? {
        switch self {
        case .home:
            return "Home"
        case .timesheets:
            return "Timesheets"
        case .schedule:
            return "Schedule"
        case .settings:
            return "Settings"
        
        }
    }
    
    var systemImage: String? {
        switch self {
        case .home:
            return "house.fill"
        case .timesheets:
            return "clock.fill"
        case .schedule:
            return "calendar"
        case .settings:
            return "gear"
        }
    }
}
