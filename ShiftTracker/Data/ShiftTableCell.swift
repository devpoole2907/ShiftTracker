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
    var duration: TimeInterval
    var rate: Double
    var pay: Double
    
    
}
