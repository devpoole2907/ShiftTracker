//
//  SingleScheduledShift.swift
//  ShiftTracker
//
//  Created by James Poole on 8/07/23.
//

import Foundation

struct SingleScheduledShift: Hashable, Identifiable {
    
    var startDate: Date
    var endDate: Date
    var id: UUID
    var isRepeating: Bool
    var repeatID: UUID?
    var reminderTime: Double
    var notifyMe: Bool
    var job: Job?
    
    
    init(startDate: Date, endDate: Date, id: UUID, job: Job, isRepeating: Bool, repeatID: UUID, reminderTime: Double, notifyMe: Bool) {
        self.startDate = startDate
        self.endDate = endDate
        self.id = id
        self.job = job
        self.isRepeating = isRepeating
        self.repeatID = repeatID
        self.reminderTime = reminderTime
        self.notifyMe = notifyMe
        }
    
    init(shift: ScheduledShift){
        
        self.startDate = shift.startDate!
        self.endDate = shift.endDate!
        self.id = shift.id!
        self.job = shift.job ?? nil
        self.isRepeating = shift.isRepeating
        
        
        self.repeatID = UUID() // why is this fucked shift.newRepeatID ?? nil
        self.reminderTime = shift.reminderTime
        self.notifyMe = shift.notifyMe
        
        
        
        
    }
    
    
    var dateComponents: DateComponents {
            var dateComponents = Calendar.current.dateComponents(
                [.month,
                 .day,
                 .year,
                 .hour,
                 .minute],
                from: startDate)
            dateComponents.timeZone = TimeZone.current
            dateComponents.calendar = Calendar(identifier: .gregorian)
            return dateComponents
        }
    
    
    
    
}
