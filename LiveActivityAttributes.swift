//
//  LiveActivityAttributes.swift
//  ShiftTracker
//
//  Created by James Poole on 29/07/23.
//

import SwiftUI
import ActivityKit

struct LiveActivityAttributes: ActivityAttributes {
    public typealias TimerStatus = ContentState
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var startTime: Date
        
        // these variables are not nil when a shift ends, final state for a user dismissable final overview of the finished shift live activity
        
        var totalPay: Double? = nil
        var taxedPay: Double? = nil
        var shiftDuration: Double? = nil
        var breakDuration: Double? = nil
        var endTime: Date? = nil
        
        //
        
        var isOnBreak: Bool
        var unpaidBreak: Bool = false

    }

    // Fixed non-changing properties about your activity go here!
    var jobName: String
    var jobTitle: String
    var jobIcon: String
    var jobColorRed: Double
    var jobColorGreen: Double
    var jobColorBlue: Double
    var hourlyPay: Double
    
    
    
}


