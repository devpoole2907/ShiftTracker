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
    var isComplete: Bool // used to determine whether the scheduled shift is in fact an OldShift
    
    
    init(startDate: Date, endDate: Date, id: UUID, job: Job, isRepeating: Bool, repeatID: String, reminderTime: Double, notifyMe: Bool, tags: Set<Tag>, isComplete: Bool) {
        self.startDate = startDate
        self.endDate = endDate
        self.id = id
        self.job = job
        self.isRepeating = isRepeating
        self.repeatID = repeatID
        self.reminderTime = reminderTime
        self.notifyMe = notifyMe
        self.tags = tags
        self.isComplete = isComplete
        }
    
    init(shift: ScheduledShift){
        
        self.startDate = shift.startDate!
        self.endDate = shift.endDate!
        self.id = shift.id!
        self.job = shift.job ?? nil
        self.isRepeating = shift.isRepeating
        self.isComplete = false
        

        
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
        self.endDate = oldShift.shiftEndDate ?? Date() // TODO: COME BACK! DONT FORCE!
        
        self.id = oldShift.shiftID ?? UUID()
        
        self.job = oldShift.job ?? nil
        self.isRepeating = false
        self.repeatID = UUID().uuidString
        self.reminderTime = 0
        self.notifyMe = false
        
        self.isComplete = true
        
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
