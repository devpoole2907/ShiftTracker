//
//  PayPeriodManager.swift
//  ShiftTracker
//
//  Created by James Poole on 10/03/24.
//

import Foundation
import CoreData
import SwiftUI

class PayPeriodManager: ObservableObject {
    
    @Published var newPeriodStartDate = Date()
    @Published var newPeriodEndDate = Date()
    
    func deletePayPeriod(_ period: PayPeriod, in context: NSManagedObjectContext) {
        context.delete(period)
        do {
            try context.save()
        } catch {
            print("Error deleting shift: \(error)")
        }
    }
    
    func createNewPayPeriod(using context: NSManagedObjectContext, payPeriods: FetchedResults<PayPeriod>, job: Job) {
            let newPayPeriod = PayPeriod(context: context)
        newPayPeriod.startDate = newPeriodStartDate.startOfDay
        newPayPeriod.endDate = newPeriodEndDate.endOfDay
            newPayPeriod.job = job
            
        
            // Associate shifts with the new pay period
        updatePayPeriods(using: context, payPeriods: payPeriods, job: job)
            try? context.save()
        }
        
    func updatePayPeriods(using context: NSManagedObjectContext, payPeriods: FetchedResults<PayPeriod>, job: Job) {
        
        let shiftsFetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        shiftsFetchRequest.predicate = NSPredicate(format: "job == %@", job)
        let allShifts: [OldShift]
        do {
            allShifts = try context.fetch(shiftsFetchRequest)
        } catch {
            print("Error fetching shifts: \(error)")
            return
        }
        
        for shift in allShifts {
                if let shiftStartDate = shift.shiftStartDate {
                    let matchingPayPeriod = (job.payPeriods as? Set<PayPeriod>)?.first { payPeriod in
                        if let payPeriodStartDate = payPeriod.startDate, let payPeriodEndDate = payPeriod.endDate {
                            return shiftStartDate >= payPeriodStartDate && shiftStartDate <= payPeriodEndDate
                        }
                        return false
                    }
                    shift.payPeriod = matchingPayPeriod
                    if let payPeriod = matchingPayPeriod {
                                    payPeriod.shiftCount += 1
                                    payPeriod.totalPay += shift.totalPay
                                    payPeriod.totalSeconds += shift.duration
                                }
                }
            }
        
        do {
            try context.save()
        } catch {
            print("Error saving updated shifts: \(error)")
        }
    }
    
    
    
    
    
}
