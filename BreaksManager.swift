//
//  BreaksManager.swift
//  ShiftTracker
//
//  Created by James Poole on 28/05/23.
//

import Foundation
import CoreData


class BreaksManager {
    static let shared = BreaksManager()
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
     func formattedDate(_ date: Date) -> String {
            dateFormatter.string(from: date)
        }
    
    func deleteBreak(context: NSManagedObjectContext, breakToDelete: Break) {
        // Remove the relationship between the break and its shift
        if let oldShift = breakToDelete.oldShift {
            oldShift.removeFromBreaks(breakToDelete)
        }

        // Delete the break from the context
        context.delete(breakToDelete)

        // Save the changes
        do {
            try context.save()
        } catch {
            print("Error deleting break: \(error)")
        }
    }
    
    func addBreak(oldShift: OldShift, startDate: Date, endDate: Date, isUnpaid: Bool, context: NSManagedObjectContext) {
        let newBreak = Break(context: context)
        newBreak.startDate = startDate
        newBreak.endDate = endDate
        newBreak.isUnpaid = isUnpaid
        oldShift.addToBreaks(newBreak)

        do {
            try context.save()
        } catch {
            print("Error adding break: \(error)")
        }
    }
    
     func saveChanges(in context: NSManagedObjectContext) {
            do {
                try context.save()
            } catch {
                print("Error saving changes: \(error)")
            }
        }
    
    
    
    func breakLengthInMinutes(startDate: Date?, endDate: Date?) -> String {
        guard let start = startDate, let end = endDate else { return "N/A" }
        let duration = end.timeIntervalSince(start)
        let minutes = Int(duration) / 60
        return "\(minutes) minutes"
    }
    
    func previousBreakEndDate(for breakItem: Break, breaks: [Break]) -> Date? {
        let sortedBreaks = breaks.sorted { $0.startDate! < $1.startDate! }
        if let index = sortedBreaks.firstIndex(of: breakItem), index > 0 {
            return sortedBreaks[index - 1].endDate
        }
        return nil
    }
    // used for converting TempBreak to Break
    func createBreak(oldShift: OldShift, startDate: Date, endDate: Date, isUnpaid: Bool, in context: NSManagedObjectContext) {
            let newBreak = Break(context: context)
            newBreak.startDate = startDate
            newBreak.endDate = endDate
        newBreak.isUnpaid = isUnpaid
            newBreak.oldShift = oldShift
            
            oldShift.addToBreaks(newBreak)
            
            do {
                try PersistenceController.shared.container.viewContext.save()
            } catch {
                print("Error saving break: \(error)")
            }
        }
    
}
