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
    
    func cancelNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Notification with identifier: \(identifier) canceled")
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

        // pay period notifications
        let futurePayPeriods = payPeriods.filter { $0.endDate ?? Date() > Date() }
            .sorted { $0.endDate ?? Date() < $1.endDate ?? Date() }
            .prefix(2) // only take next two future pay periods

        // cancel existing pay periods notifications for all
        for payPeriod in payPeriods {
            if let identifier = payPeriod.notificationIdentifier {
                cancelNotification(withIdentifier: identifier)
            }
        }

        // schedule notifs
        for payPeriod in futurePayPeriods {
            if let endDate = payPeriod.endDate {
                let notificationIdentifier = "payPeriod-\(payPeriod.objectID)"
                payPeriod.notificationIdentifier = notificationIdentifier // store identifier in the pay period

                // scheduled for 6pm on the end date
                let notificationDate = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: endDate) ?? endDate
                
                var notifText = ""
                if let jobName = job.name {
                    
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
            print("Error saving context after updating notifications: \(error)")
        }
    }

}

    
    
    
    
    

