//
//  InvoiceViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 8/03/24.
//

import Foundation
import CoreData
import SwiftUI

class InvoiceViewModel: ObservableObject {
    
    @Published var tableCells: [ShiftTableCell] = []
    @Published var totalPay: Double = 0.0
    
    var selectedShifts: Set<NSManagedObjectID>? = nil
    var shifts: FetchedResults<OldShift>? = nil
    var arrayShifts: [OldShift]? = nil
    var job: Job?
    var singleExportShift: OldShift? = nil
    var viewContext: NSManagedObjectContext
    
    
    init(shifts: FetchedResults<OldShift>? = nil, selectedShifts: Set<NSManagedObjectID>? = nil, job: Job? = nil, viewContext: NSManagedObjectContext, arrayShifts: [OldShift]? = nil, singleExportShift: OldShift? = nil){
        self.selectedShifts = selectedShifts
        self.shifts = shifts
        self.job = job
        self.viewContext = viewContext
        self.arrayShifts = arrayShifts
        self.singleExportShift = singleExportShift
        
        setupData()
        
    }
    // this func is in two places, also in exportviewmodel. could consolidate it somewhere in future.
    private func shouldInclude(shift: OldShift) -> Bool {
        if let selectedShifts = selectedShifts {
            return selectedShifts.contains(shift.objectID)
        } /*else {
            return isShiftWithinDateRange(shift: shift)
        }*/
        
        return false
        
    }
    
    func setupData() {
        
        var filteredShifts: [OldShift] = []
        
        if let theShifts = shifts {
            filteredShifts = theShifts.filter { shouldInclude(shift: $0) }
        } else if let arrayShifts = arrayShifts {
            filteredShifts = arrayShifts.filter { shouldInclude(shift: $0) }
        }
        
        tableCells = filteredShifts.map { shift in
                    let duration = shift.duration // Assuming you have a duration property in OldShift
                    let rate = shift.hourlyPay // Assuming you have a rate property in OldShift
                    let pay = shift.totalPay
                    return ShiftTableCell(date: shift.shiftStartDate ?? Date(), duration: duration, rate: rate, pay: pay)
               }
        
        totalPay = tableCells.reduce(0) { $0 + $1.pay }
        
    }
    
    
    
}
