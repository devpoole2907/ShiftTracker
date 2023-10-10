//
//  DetailViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 12/08/23.
//

import Foundation
import SwiftUI
import CoreData

class DetailViewModel: ObservableObject {
   
    @Published var selectedStartDate: Date
    @Published var selectedEndDate: Date
    @Published var selectedBreakStartDate: Date
    @Published var selectedBreakEndDate: Date
    @Published var selectedTaxPercentage: Double
    @Published var selectedHourlyPay: String = ""
    @Published var shiftDuration: TimeInterval
    @Published var selectedTotalTips: String = ""
    @Published var addTipsToTotal: Bool = false
    @Published var payMultiplier = 1.0
    @Published var multiplierEnabled = false
    @Published var notes = ""
    @Published var selectedTags: Set<Tag> = []
    @Published var shiftID: UUID
    
    @Published var overtimeEnabled: Bool = false
    @Published var overtimeRate: Double = 1.00
    @Published var overtimeAppliedAfter: Double = 0
    
    @Published var shift: OldShift?
    @Published var job: Job?
    
    @Published var isEditJobPresented: Bool = false
    
    @AppStorage("displayedCount") var displayedCount: Int = 0
    @AppStorage("TipsEnabled") var tipsEnabled: Bool = true
    @AppStorage("TaxEnabled") var taxEnabled: Bool = true
    
    @Published var isAddingBreak: Bool = false
    @Published var isUnpaid: Bool = false
    
    @Published var showingDeleteAlert = false
    
    var originalJob: Job? = nil // used to determine if the job associated with the shift is changed/different from initialisation
    
    // used to toggle view refresh when editing a break
    @Published var breakEdited = false
    
    // for adding shift:
    
    @Published var tempBreaks: [TempBreak] = []
    
    @Published var isEditing: Bool = false
    
    init(selectedStartDate: Date = Date(), selectedEndDate: Date = Date().addingTimeInterval(60 * 60), selectedBreakStartDate: Date = Date(), selectedBreakEndDate: Date = Date().addingTimeInterval(10 * 60), selectedTaxPercentage: Double = 0.0, selectedHourlyPay: String = "0.00", shiftDuration: TimeInterval = 0.0, selectedTotalTips: String = "0.00", addTipsToTotal: Bool = false, payMultiplier: Double = 1.0, multiplierEnabled: Bool = false, notes: String = "", selectedTags: Set<Tag> = [], shiftID: UUID = UUID(), isEditing: Bool = false, job: Job? = nil) {
        self.selectedStartDate = selectedStartDate
        self.selectedEndDate = selectedEndDate
        self.selectedBreakStartDate = selectedBreakStartDate
        self.selectedBreakEndDate = selectedBreakEndDate
        self.selectedTaxPercentage = selectedTaxPercentage
        self.selectedHourlyPay = selectedHourlyPay
        self.shiftDuration = shiftDuration
        self.selectedTotalTips = selectedTotalTips
        self.addTipsToTotal = addTipsToTotal
        self.payMultiplier = payMultiplier
        self.multiplierEnabled = multiplierEnabled
        self.selectedTags = selectedTags
        self.shiftID = shiftID
        self.isEditing = isEditing
        self.job = job
        self.originalJob = job
        self.overtimeAppliedAfter = job?.overtimeAppliedAfter ?? 0
    }
    
    init(shift: OldShift){
        
        self.selectedStartDate = shift.shiftStartDate ?? Date()
        self.selectedEndDate = shift.shiftEndDate ?? Date()
        self.selectedBreakStartDate = Date()
        self.selectedBreakEndDate = Date().addingTimeInterval(60 * 60)
        self.selectedTaxPercentage = shift.tax
        self.selectedHourlyPay = "\(shift.hourlyPay)"
        self.shiftDuration = shift.duration
        self.selectedTotalTips = "\(shift.totalTips)"
        self.addTipsToTotal = shift.addTipsToTotal
        self.payMultiplier = shift.payMultiplier
        self.multiplierEnabled = shift.multiplierEnabled
        self.selectedTags = shift.tags as! Set<Tag>
        self.shiftID = shift.shiftID ?? UUID()
        self.isEditing = false
        self.shift = shift
        self.overtimeEnabled = shift.overtimeEnabled
        self.overtimeRate = shift.overtimeRate
        self.overtimeAppliedAfter = shift.timeBeforeOvertime
        self.job = shift.job
        self.originalJob = shift.job
        
    }
    
    func totalBreakDuration(for breaks: Set<Break>) -> TimeInterval {
        let paidBreaks = breaks.filter { $0.isUnpaid == true }
        let totalDuration = paidBreaks.reduce(0) { (sum, breakItem) -> TimeInterval in
            let breakDuration = breakItem.endDate?.timeIntervalSince(breakItem.startDate ?? Date())
            return sum + (breakDuration ?? 0.0)
        }
        return totalDuration
    }
    
    func totalTempBreakDuration(for tempBreaks: [TempBreak]) -> TimeInterval {
        let unpaidBreaks = tempBreaks.filter { $0.isUnpaid == true }
        let totalDuration = unpaidBreaks.reduce(0) { (sum, breakItem) -> TimeInterval in
            let breakDuration = breakItem.endDate?.timeIntervalSince(breakItem.startDate)
            return sum + (breakDuration ?? 0)
        }
        return totalDuration
    }
    
    var adaptiveShiftDuration: TimeInterval {
        selectedEndDate.timeIntervalSince(selectedStartDate)
    }
    
    // pay before overtime pay added
    
    var originalPay: Double {
        
        let totalDuration = selectedEndDate.timeIntervalSince(selectedStartDate)
        let totalBreakDuration = totalTempBreakDuration(for: tempBreaks)
        
        let originalPay = (totalDuration - totalBreakDuration) / 3600.0 * (Double(selectedHourlyPay) ?? 0.0)
        
        return originalPay

    }
    // the earnings made purely from overtime
    var overtimeEarnings: Double {
        return totalPay - originalPay
    }
    
    var totalPay: Double {
        
        var totalBreakDuration: TimeInterval = 0.0
        
        if let shift = shift {
            let allBreaks = shift.breaks as! Set<Break>
            
            totalBreakDuration = self.totalBreakDuration(for: allBreaks)
   
        } else {
            totalBreakDuration = totalTempBreakDuration(for: tempBreaks)
        }
        
        

        let totalDuration = selectedEndDate.timeIntervalSince(selectedStartDate)
        var overtimeDuration = 0.0
        var baseDuration = totalDuration

        // base and overtime duration
        if overtimeAppliedAfter > 0 && overtimeRate > 1.0 && totalDuration > overtimeAppliedAfter {
            overtimeDuration = totalDuration - overtimeAppliedAfter
            baseDuration = totalDuration - overtimeDuration
        }

        // base pay and overtime pay
        let basePay = (baseDuration - totalBreakDuration) / 3600.0 * (Double(selectedHourlyPay) ?? 0.0)
        let overtimePay = (overtimeDuration / 3600.0) * (Double(selectedHourlyPay) ?? 0.0) * overtimeRate

        
        var total = multiplierEnabled ? (basePay + overtimePay) * payMultiplier : basePay + overtimePay

        if addTipsToTotal {
            total += Double(selectedTotalTips) ?? 0.0
        }
        
        return total
    }


    
    var taxedPay: Double {
        return totalPay - (totalPay * selectedTaxPercentage / 100.0)
    }
    
    
    // this var means the check below for temp breaks is ... pointless & repetitive. still matters for Breaks though
    
    var areAllTempBreaksWithin: Bool {
            return tempBreaks.allSatisfy {
                $0.startDate >= selectedStartDate && $0.endDate! <= selectedEndDate
            }
        }
    
    
    func setupShift(_ shift: OldShift, breaks: [AnyObject]) -> Bool {
        
        let allBreaksAreWithin = breaks.allSatisfy { breakObj in
            
            if let breakItem = breakObj as? Break {
                return breakItem.startDate! >= selectedStartDate && breakItem.endDate! <= selectedEndDate
            } else if let tempBreak = breakObj as? TempBreak {
                return tempBreak.startDate >= selectedStartDate && tempBreak.endDate! <= selectedEndDate
            }
            
            return false
            
            
            
        }
        
        guard allBreaksAreWithin else { return false }
        
        shift.shiftStartDate = selectedStartDate
        shift.shiftEndDate = selectedEndDate
        shift.tax = selectedTaxPercentage
        shift.hourlyPay = Double(selectedHourlyPay) ?? 0.0
        shift.totalTips = Double(selectedTotalTips) ?? 0.0
        shift.addTipsToTotal = addTipsToTotal
        shift.duration = selectedEndDate.timeIntervalSince(selectedStartDate)
        shift.payMultiplier = payMultiplier
        shift.multiplierEnabled = multiplierEnabled
        shift.shiftNote = notes
        shift.shiftID = shift.shiftID ?? UUID()
        shift.tags = NSSet(array: Array(selectedTags))
        
        shift.overtimeEnabled = overtimeEnabled
        shift.overtimeRate = overtimeRate
        shift.timeBeforeOvertime = overtimeAppliedAfter
        
        let unpaidBreaks = (shift.breaks?.allObjects as? [Break])?.filter { $0.isUnpaid == true } ?? []
            let totalBreakDuration = unpaidBreaks.reduce(0) { $0 + $1.endDate!.timeIntervalSince($1.startDate!) }
            shift.breakDuration = totalBreakDuration
            let shiftDuration = selectedEndDate.timeIntervalSince(selectedStartDate)
            shift.duration = shiftDuration
            
            var overtimeDuration = 0.0
            var baseDuration = shiftDuration
        if overtimeEnabled {
            if overtimeAppliedAfter > 0 && overtimeRate > 1.0 && shiftDuration > overtimeAppliedAfter {
                overtimeDuration = shiftDuration - overtimeAppliedAfter
                baseDuration = shiftDuration - overtimeDuration
            }
        }

        let basePay = (baseDuration - totalBreakDuration) / 3600.0 * Double(selectedHourlyPay)!
        let overtimePay = (overtimeDuration / 3600.0) * Double(selectedHourlyPay)! * overtimeRate

            shift.totalPay = (shift.multiplierEnabled ? (basePay + overtimePay) * payMultiplier : basePay + overtimePay)
        
        if shift.addTipsToTotal {
            shift.totalPay = shift.totalPay + shift.totalTips
        }
        
            shift.taxedPay = shift.totalPay - (shift.totalPay * shift.tax / 100.0)
        
        shift.job = job
            
            return true
        
        
        
    }
    
    
    
    func saveShift(_ shift: OldShift, in viewContext: NSManagedObjectContext){
        
        let allBreaks = (shift.breaks?.allObjects as? [Break]) ?? []
        
        if !setupShift(shift, breaks: allBreaks) {
            
            OkButtonPopup(title: "Saved breaks are not within the shift start and end dates.").showAndStack()
            
            return
            
        }
        
        withAnimation {
            isEditing = false
        }
            

        
        do {
            
            try viewContext.save()
            
            
            
        } catch {
            print("Error saving shift: \(error)")
        }
        
        
    }
    
    
    
    @MainActor func addShift(in viewContext: NSManagedObjectContext, with shiftStore: ShiftStore, job: Job) {
        
        let newShift = OldShift(context: viewContext)
        let tempBreaks = self.tempBreaks as [AnyObject]
        
        if !setupShift(newShift, breaks: tempBreaks) {
            
            OkButtonPopup(title: "Saved breaks are not within the shift start and end dates.").showAndStack()
            
            
            
            return
        }
        
        
       
        
        newShift.job = job
        
        newShift.shiftID = UUID()
        
        for tempBreak in self.tempBreaks {
            if let breakEndDate = tempBreak.endDate {
                BreaksManager().createBreak(oldShift: newShift, startDate: tempBreak.startDate, endDate: breakEndDate, isUnpaid: tempBreak.isUnpaid, in: viewContext)
            }
        }
        
        shiftStore.add(SingleScheduledShift(oldShift: newShift))
        
        
        
        do {
            try viewContext.save()
           
        } catch {
            print("Error saving new shift: \(error)")
        }
        
        
        
    }
    
    
}

