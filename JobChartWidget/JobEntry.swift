//
//  JobEntry.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import Foundation
import WidgetKit

struct JobEntry: TimelineEntry {
    let date: Date
    let job: Job?
    let oldShifts: [OldShift]
}
