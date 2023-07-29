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
    var repeatID: String
    var reminderTime: Double
    var notifyMe: Bool
    var job: Job?
    var tags: Set<Tag> = []
    
    
    init(startDate: Date, endDate: Date, id: UUID, job: Job, isRepeating: Bool, repeatID: String, reminderTime: Double, notifyMe: Bool, tags: Set<Tag>) {
        self.startDate = startDate
        self.endDate = endDate
        self.id = id
        self.job = job
        self.isRepeating = isRepeating
        self.repeatID = repeatID
        self.reminderTime = reminderTime
        self.notifyMe = notifyMe
        self.tags = tags
        }
    
    init(shift: ScheduledShift){
        
        self.startDate = shift.startDate!
        self.endDate = shift.endDate!
        self.id = shift.id!
        self.job = shift.job ?? nil
        self.isRepeating = shift.isRepeating
        
        

        
        self.repeatID = shift.repeatIdString ?? UUID().uuidString // why is this fucked shift.newRepeatID ?? nil
        self.reminderTime = shift.reminderTime
        self.notifyMe = shift.notifyMe
        
        if let tagsSet = shift.tags as? Set<Tag> {
            self.tags = tagsSet
        } else {
            self.tags = Set<Tag>()
        }
        
        
    }
    
    init(oldShift: OldShift){
        
        self.startDate = oldShift.shiftStartDate!
        self.endDate = oldShift.shiftEndDate!
        
        self.id = oldShift.shiftID ?? UUID()
        
        self.job = oldShift.job ?? nil
        self.isRepeating = false
        self.repeatID = UUID().uuidString
        self.reminderTime = 0
        self.notifyMe = false
        if let tagsSet = oldShift.tags as? Set<Tag> {
            self.tags = tagsSet
        } else {
            self.tags = Set<Tag>()
        }

        
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
