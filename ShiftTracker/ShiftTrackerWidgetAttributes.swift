//
//  ShiftTrackerWidgetAttributes.swift
//  ShiftTracker
//
//  Created by James Poole on 25/03/23.
//

import Foundation
import ActivityKit
import SwiftUI

struct ShiftTrackerWidgetAttributes: ActivityAttributes {
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
