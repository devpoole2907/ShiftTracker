//
//  ShiftTableCell.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import Foundation

struct ShiftTableCell: Identifiable {
    
    var id = UUID()
    // this needs to reduce any break duration
    var date: Date
    var duration: TimeInterval = 0.0
    var rate: Double = 0.0
    var pay: Double = 0.0
    
    var startTime: Date {
        return date
    }
    var endtime: Date = Date()
    var breakDuration: TimeInterval = 0.0
    var overtimeDuration: TimeInterval = 0.0
    
    var notes: String = "" // description from the shift
    
    var isEmpty: Bool = false // used to create blank cells so the pdf renders correctly due to weird behaviour with ImageRenderer aligning toward the bottom
    
    
    
}
