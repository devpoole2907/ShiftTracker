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
        var totalPay: Double
        var isOnBreak: Bool
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
    var hourlyPay: Double
}


