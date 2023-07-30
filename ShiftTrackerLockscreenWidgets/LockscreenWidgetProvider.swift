//
//  LockscreenWidgetProvider.swift
//  ShiftTrackerLockscreenWidgetsExtension
//
//  Created by James Poole on 30/07/23.
//

import Foundation
import WidgetKit

struct LockscreenWidgetProvider: TimelineProvider {
    
    private let shiftKeys = ShiftKeys()
    
    func placeholder(in context: Context) -> ShiftEntry {
        ShiftEntry(date: Date(), shiftStartDate: nil, totalPay: 0, taxedPay: 0, isOnBreak: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftEntry) -> ()) {
        let entry = ShiftEntry(date: Date(), shiftStartDate: nil, totalPay: 0, taxedPay: 0, isOnBreak: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftEntry>) -> ()) {
        var entries: [ShiftEntry] = []
        let currentDate = Date()
        
        for offset in 0..<4 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: 15*offset, to: currentDate)!
            let sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
            let shiftStartDate = sharedUserDefaults.object(forKey: shiftKeys.shiftStartDateKey) as? Date
            let hourlyPay = sharedUserDefaults.double(forKey: shiftKeys.hourlyPayKey)
            
            let tempBreaks = loadTempBreaksFromUserDefaults()
            let totalPay = calculateTotalPay(sharedUserDefaults: sharedUserDefaults, hourlyPay: hourlyPay, tempBreaks: tempBreaks)
            let taxedPay = calculateTaxedPay(sharedUserDefaults: sharedUserDefaults, totalPay: totalPay)
            
            
            let entry = ShiftEntry(date: entryDate, shiftStartDate: shiftStartDate, totalPay: totalPay, taxedPay: taxedPay, isOnBreak: false)
            entries.append(entry)
            
        }

        let timeline = Timeline(entries: entries, policy: .after(entries.last!.date))
        completion(timeline)
    }
    
    // these need to factor in breaks
    
    func calculateTotalPay(sharedUserDefaults: UserDefaults, hourlyPay: Double, tempBreaks: [TempBreak]) -> Double {
        guard let shiftStartDate = sharedUserDefaults.object(forKey: shiftKeys.shiftStartDateKey) as? Date else { return 0 }
        
        let totalTimeWorked = Date().timeIntervalSince(shiftStartDate) - totalBreakDuration(tempBreaks: tempBreaks)
        let pay = (totalTimeWorked / 3600.0) * hourlyPay
        return pay
    }
    
    func calculateTaxedPay(sharedUserDefaults: UserDefaults, totalPay: Double) -> Double {
        guard let taxPercentage = sharedUserDefaults.object(forKey: shiftKeys.taxPercentageKey) as? Double else { return 0 }
        let afterTax = totalPay - (totalPay * Double(taxPercentage) / 100.0)
        return afterTax
    }
    
    func totalBreakDuration(tempBreaks: [TempBreak]) -> TimeInterval {
        let totalDuration = tempBreaks.reduce(0) { (result, tempBreak) -> TimeInterval in
            if tempBreak.isUnpaid {
                let duration = tempBreak.endDate?.timeIntervalSince(tempBreak.startDate) ?? 0
                return result + duration
            } else {
                return result
            }
        }
            return totalDuration
        }
    
    func loadTempBreaksFromUserDefaults() -> [TempBreak] {
        let sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
        
        var temporaryBreaks: [TempBreak] = []
        
        if let tempBreaksDictionaries = sharedUserDefaults.array(forKey: shiftKeys.tempBreaksKey) as? [[String: Any]] {
            let loadedBreaks = dictionariesToTempBreaks(dictionaries: tempBreaksDictionaries)
            
            for tempBreak in loadedBreaks {
                       
                            temporaryBreaks.append(tempBreak)
                        
                    }
            
        }
        
        return temporaryBreaks

    }
    
    func dictionariesToTempBreaks(dictionaries: [[String: Any]]) -> [TempBreak] {
        let decoder = JSONDecoder()
        let jsonData = try? JSONSerialization.data(withJSONObject: dictionaries, options: [])
        let tempBreaks = try? decoder.decode([TempBreak].self, from: jsonData!)
        return tempBreaks ?? []
    }
    
    
}
