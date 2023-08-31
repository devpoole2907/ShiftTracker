//
//  ShiftNotificationManager.swift
//  ShiftTracker
//
//  Created by James Poole on 31/08/23.
//

import Foundation
import CoreData
import UserNotifications

// scheduled shifts notification manager

class ShiftNotificationManager {
    static let shared = ShiftNotificationManager()
    
    private var shiftNotificationIdentifiers: [String] = []
    
    func fetchUpcomingShifts() -> [ScheduledShift] {
        let fetchRequest: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "notifyMe == true")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledShift.reminderTime, ascending: true)]
        fetchRequest.fetchLimit = 10
        
        do {
            let shifts = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            return shifts
        } catch {
            print("Failed to fetch shifts: \(error.localizedDescription)")
            return []
        }
    }
    
    func scheduleNotifications() {
        let shifts = fetchUpcomingShifts()
        let center = UNUserNotificationCenter.current()
        
        center.removePendingNotificationRequests(withIdentifiers: shiftNotificationIdentifiers)
        shiftNotificationIdentifiers.removeAll()
        
        for shift in shifts {
            let content = UNMutableNotificationContent()
            
            
            if let reminderDate = shift.startDate?.addingTimeInterval(-shift.reminderTime),
               let _ = shift.startDate, let jobName = shift.job?.name {
                
                let minutesToStart = Int(shift.reminderTime / 60)
                
                content.title = "\(jobName) Shift Reminder"
                
                content.body = "Shift starting in \(minutesToStart) \(minutesToStart == 1 ? "minute." : "minutes.")"
                
                content.interruptionLevel = .timeSensitive
                let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                
                let identifier = "Shift-\(shift.id?.uuidString ?? UUID().uuidString)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                center.add(request)
                
                shiftNotificationIdentifiers.append(identifier)
            }
        }
    }
    
    // used for location based clock in and out/auto clock in and out
    
    func sendLocationNotification(with title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        print("Sending notification") // debugging
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // used for roster reminding notifications
    
    func updateRosterNotifications(viewContext: NSManagedObjectContext) {
        let center = UNUserNotificationCenter.current()
        
        // Cancel all existing notifications
        center.removePendingNotificationRequests(withIdentifiers: ["roster"])
        
        let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "rosterReminder == true")
        
        do {
            let jobs = try viewContext.fetch(fetchRequest)
            
            
            for job in jobs {
                if let time = job.rosterTime,
                   let nextDate = nextDate(dayOfWeek: Int(job.rosterDayOfWeek), time: time) {
                    
                    
                    
                    let content = UNMutableNotificationContent()
                    content.title = "Check your roster"
                    content.body = "Open the app to schedule your shifts for \(job.name ?? "")."
                    
                    content.userInfo = ["url": "shifttrackerapp://schedule"]
                    content.categoryIdentifier = "rosterCategory"
                    
                    
                    let triggerDate = Calendar.current.dateComponents([.weekday, .hour, .minute], from: nextDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
                    
                    let request = UNNotificationRequest(identifier: "roster", content: content, trigger: trigger)
                    center.add(request, withCompletionHandler: { (error) in
                        if let error = error {
                            // handle the error
                            print("Notification error: ", error)
                        }
                    })
                }
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
}
