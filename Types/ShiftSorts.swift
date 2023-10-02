//
//  ShiftSorts.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import Foundation
import CoreData

struct ShiftNSSort: Hashable, Identifiable {
    let id: Int
    let name: String
    let descriptors: [NSSortDescriptor]

    static let sorts: [ShiftNSSort] = [
        ShiftNSSort(
            id: 0,
            name: "Latest",
            descriptors: [
                NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)
            ]),
        ShiftNSSort(
            id: 1,
            name: "Oldest",
            descriptors: [
                NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: true)
            ]),
        ShiftNSSort(
            id: 2,
            name: "Pay | Ascending",
            descriptors: [
                NSSortDescriptor(keyPath: \OldShift.taxedPay, ascending: false)
            ]),
        ShiftNSSort(
            id: 3,
            name: "Pay | Descending",
            descriptors: [
                NSSortDescriptor(keyPath: \OldShift.taxedPay, ascending: true)
            ]),
        ShiftNSSort(
            id: 4,
            name: "Longest",
            descriptors: [
                NSSortDescriptor(keyPath: \OldShift.duration, ascending: false)
            ]),
        ShiftNSSort(
            id: 5,
            name: "Shortest",
            descriptors: [
                NSSortDescriptor(keyPath: \OldShift.duration, ascending: true)
            ])
    ]

    static var `default`: ShiftNSSort { sorts[0] }
}






struct ShiftSort: Hashable, Identifiable {
    let id: Int
    let name: String
    let descriptors: [SortDescriptor<OldShift>]
    
    
    static let sorts: [ShiftSort] = [
        ShiftSort(
            id: 0,
            name: "Latest",
            descriptors: [
                SortDescriptor(\OldShift.shiftStartDate, order: .reverse)
            ]),
        ShiftSort(
            id: 1,
            name: "Oldest",
            descriptors: [
                SortDescriptor(\OldShift.shiftStartDate, order: .forward)
            ]),
        ShiftSort(
            id: 2,
            name: "Pay | Ascending",
            descriptors: [
                SortDescriptor(\OldShift.taxedPay, order: .reverse)
            ]),
        ShiftSort(
            id: 3,
            name: "Pay | Descending",
            descriptors: [
                SortDescriptor(\OldShift.taxedPay, order: .forward)
            ]),
        ShiftSort(
            id: 4,
            name: "Longest",
            descriptors: [
                SortDescriptor(\OldShift.duration, order: .reverse)
            ]),
        ShiftSort(
            id: 5,
            name: "Shortest",
            descriptors: [
                SortDescriptor(\OldShift.duration, order: .forward)
            ])
    ]
    
    // 4
    static var `default`: ShiftSort { sorts[0] }
    
    
}
