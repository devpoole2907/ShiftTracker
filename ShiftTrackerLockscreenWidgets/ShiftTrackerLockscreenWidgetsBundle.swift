//
//  ShiftTrackerLockscreenWidgetsBundle.swift
//  ShiftTrackerLockscreenWidgets
//
//  Created by James Poole on 30/07/23.
//

import WidgetKit
import SwiftUI

@main
struct ShiftTrackerLockscreenWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ShiftTrackerLockscreenDurationWidgets()
        ShiftTrackerLockscreenPayWidgets()
        
    }
}
