//
//  PayPeriodManager.swift
//  ShiftTracker
//
//  Created by James Poole on 10/03/24.
//

import Foundation
import CoreData
import SwiftUI
import UserNotifications


class PayPeriodManager: ObservableObject {
    
    @Published var newPeriodStartDate = Date()
    @Published var newPeriodEndDate = Date()
    @Published var remindMeAtEnd = false
    
    func scheduleNotification(for date: Date, title: String, text: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = text
        content.sound = UNNotificationSound.default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled with identifier: \(identifier)")
            }
        }
    }
    
    func cancelNotifications(for payPeriods: [PayPeriod]) {
        let identifiers = payPeriods.compactMap { $0.notificationIdentifier }.filter { !$0.isEmpty }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    
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
        
        try? context.save()
        // Associate shifts with the new pay period
        updatePayPeriods(using: context, for: job)
        
    }
    
    
    func updatePayPeriods(using context: NSManagedObjectContext, for job: Job? = nil) {
        let jobsToUpdate: [Job]
        
        if let specificJob = job {
            jobsToUpdate = [specificJob]
        } else {
            let jobFetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
            do {
                jobsToUpdate = try context.fetch(jobFetchRequest)
            } catch {
                print("Error fetching jobs: \(error)")
                return
            }
        }
        
        for job in jobsToUpdate {
            let shiftsFetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
            let jobPredicate = NSPredicate(format: "job == %@", job)
            let activeShiftPredicate = NSPredicate(format: "isActive == NO")
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [jobPredicate, activeShiftPredicate])

            shiftsFetchRequest.predicate = compoundPredicate

            
            let allShifts: [OldShift]
            do {
                allShifts = try context.fetch(shiftsFetchRequest)
            } catch {
                print("Error fetching shifts for job \(job.name ?? ""): \(error)")
                continue
            }
            // Update pay periods for the current job based on its shifts
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
        }

        let payPeriods = fetchAllPayPeriods(using: context)
        
        // pay period notifications
        let futurePayPeriods = payPeriods.filter { $0.endDate ?? Date() > Date() }
            .sorted { $0.endDate ?? Date() < $1.endDate ?? Date() }
            .prefix(2) // only take next two future pay periods
        
        // cancel existing pay periods notifications for all
            cancelNotifications(for: payPeriods)
        
        // schedule notifs
        for payPeriod in futurePayPeriods {
            if let endDate = payPeriod.endDate {
                let notificationIdentifier = "payPeriod-\(payPeriod.objectID)"
                payPeriod.notificationIdentifier = notificationIdentifier // store identifier in the pay period
                
                // scheduled for 6pm on the end date
                let notificationDate = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: endDate) ?? endDate
                
                var notifText = ""
                if let job = payPeriod.job, let jobName = job.name {
                        
                        notifText = "Your \(jobName) pay period is ending today. Don't forget to check your shifts!"
                    
                } else {
                    notifText = "Your pay period is ending today. Don't forget to check your shifts!"
                }
                
                scheduleNotification(for: notificationDate, title: "Pay Period Ending", text: notifText, identifier: notificationIdentifier)
            }
        }
        
        
        do {
            try context.save()
        } catch {
            print("Error saving updated shifts for all jobs: \(error)")
        }
    }
    
    func fetchAllPayPeriods(using context: NSManagedObjectContext) -> [PayPeriod] {
        let fetchRequest: NSFetchRequest<PayPeriod> = PayPeriod.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        
        do {
            let payPeriods = try context.fetch(fetchRequest)
            return payPeriods
        } catch {
            print("Failed to fetch pay periods: \(error)")
            return []
        }
    }

    
}






