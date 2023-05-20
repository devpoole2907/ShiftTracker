//
//  TempBreak.swift
//  ShiftTracker
//
//  Created by James Poole on 9/04/23.
//

import Foundation

struct TempBreak: Hashable, Codable, Identifiable {
    var id = UUID()
    var startDate: Date
    var endDate: Date?
    var isUnpaid: Bool
}
