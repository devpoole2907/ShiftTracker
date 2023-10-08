//
//  ContentViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 8/04/23.
//

import Foundation
#if os(iOS)
import ActivityKit

import CoreHaptics
import UserNotifications
#endif
import CoreData
import SwiftUI


class ContentViewModel: ObservableObject {
    
    static let shared = ContentViewModel()
    
    @Published var payMultiplier: Double = 1.0 {
        didSet {
            savePayMultiplier()
        }
    }
    
    @Published var isMultiplierEnabled: Bool = false {
        didSet {
            saveIsMultiplierEnabled()
        }
    }
    
    
    @Published var shiftState: ShiftState = .notStarted
    
    // for new tag system
    @Published var selectedTags = Set<UUID>() {
        
        didSet {
            
            saveSelectedTags()
            
        }
        
    }
    
    let breaksManager = BreaksManager()
    
    @Published var lastEndedShift: OldShift? = nil // store the latest shift to return when popping the detail view
    @Published  var hourlyPay: Double = 0.0
    @Published  var lastPay: Double = 0.0
    @Published  var breakTime: Double = 30
    @Published  var lastTaxedPay: Double = 0.0
    @Published  var lastBreakElapsed: TimeInterval = 0
    @Published  var taxPercentage: Double = 0
    @Published  var overtimeMultiplier: Double = 1.25
    @Published  var shift: Shift?
    @Published  var timeElapsed: TimeInterval = 0 {
        didSet {
            print("weird i got set?")
        }
    }
    
    
    @AppStorage("totalPayAtBreakStart") var totalPayAtBreakStart: Double = 0.0
    @Published  var breakTimeElapsed: TimeInterval = 0
    @Published  var overtimeElapsed: TimeInterval = 0
    @Published  var timer: Timer?
    @Published  var breakTimer: Timer?
    @Published  var overtimeTimer: Timer?
    @Published  var isFirstLaunch = false
    @Published  var isPresented = false
    @Published var activityEnabled = false
    
    @Published  var showEndAlert = false
    @Published  var showStartBreakAlert = false
    @Published  var showEndBreakAlert = false
    @Published  var showStartOvertimeAlert = false
    
    @Published var breakReminder = false
    
    @Published  var timeElapsedBeforeBreak = 0.0
    
    @Published  var isOnBreak = false
    @Published  var isOvertime = false
    @Published var overtimeEnabled = false
    
    // used to determine whether to even activate overtime calcs
    @Published var enableOvertime = false
    
    @Published  var shiftEnded = false
    
    @Published var upcomingShiftShakeTimes: CGFloat = 0
    
    @Published  var breakStartDate: Date?
    @Published  var breakEndDate: Date?
    @Published  var overtimeStartDate: Date?
#if os(iOS)
    @Published  var engine: CHHapticEngine?
#endif
    
    @AppStorage("shiftsTracked") var shiftsTracked = 0
    
    @Published  var automaticBreak = false
    
    // we need this, to pause the timer etc if the user wants to edit
    @Published  var isEditing = false
    
    @Published  var isStartShiftTapped = false
    @Published  var isEndShiftTapped = false
    @Published  var isBreakTapped = false
    
    @Published  var breakTaken = false
    
    @Published  var shouldShowPopup = false
    
    @AppStorage("timeElapsedUntilOvertime") var timeElapsedUntilOvertime: TimeInterval = 0
    @AppStorage("overtimeRate") var overtimeRate: Double = 1.25
    @AppStorage("applyOvertimeAfter") var applyOvertimeAfter: TimeInterval = 60
    
    //some context menu stuff:
    @Published  var isAutomaticBreak = false
    
    @Published  var shiftStartDate: Date = Date()// this needs to be the date the shift started, not Date()
    
    //  @State private var activity: Activity<ShiftTrackerWidgetAttributes>? = nil
#if os(iOS)
    @Published  var isActivityEnabled: Bool = true
 //  @Published var currentActivity: Activity<LiveActivityAttributes>?
    
    private var activityStore: [String: Any] = [:]
    
    var currentActivity: Any? {
            get {
                if #available(iOS 16.2, *) {
                    return activityStore["currentActivity"]
                }
                return nil
            }
            set {
                if #available(iOS 16.2, *) {
                    activityStore["currentActivity"] = newValue
                }
            }
        }

#endif
    
    @Published  var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    @Published var selectedJobUUID: UUID?
    
    @Published private var overtimeDuration: TimeInterval = 0
    
    private let shiftKeys = ShiftKeys()
    
    
    // seperated from job manager due to live activity & widgets
    
    func fetchJob(with uuid: UUID? = nil, in context: NSManagedObjectContext) -> Job? {
        let id = uuid ?? selectedJobUUID
        guard let uuidToFetch = id else { return nil }
        let request: NSFetchRequest<Job> = Job.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", uuidToFetch as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching job: \(error)")
            return nil
        }
    }
    
    
    // breaks stuff:
    
    var tempBreaks: [TempBreak] = []
    
    func updateBreak(id: UUID, startDate: Date?, endDate: Date?) {
        if let index = tempBreaks.firstIndex(where: { $0.id == id }) {
            if let startDate = startDate {
                tempBreaks[index].startDate = startDate
            }
            if let endDate = endDate {
                tempBreaks[index].endDate = endDate
            }
        }
    }
    
    func minimumStartDate(for breakItem: TempBreak) -> Date {
        if let previousBreak = tempBreaks
            .prefix(while: { $0.id != breakItem.id })
            .last(where: { $0.endDate != nil }),
           let previousEndDate = previousBreak.endDate {
            return previousEndDate
        } else {
            return shift?.startDate ?? Date() // Return a default minimum date if no suitable break is found
        }
    }
    
    public let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    init() {
        // Read the value of hourlyPay from UserDefaults, or use a default value if none is found
        self._hourlyPay = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.hourlyPayKey))
        self._lastPay = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.lastPayKey))
        self._taxPercentage = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.taxPercentageKey))
        self._lastTaxedPay = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.lastTaxedPayKey))
        self._lastBreakElapsed = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.lastBreakElapsedKey))
        self._breakTaken = .init(initialValue: sharedUserDefaults.bool(forKey: shiftKeys.breakTakenKey))
        self._isOnBreak = .init(initialValue: sharedUserDefaults.bool(forKey: shiftKeys.isOnBreakKey))
        self._breakTime = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.breakTimeKey))
        self._timeElapsedBeforeBreak = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.timeElapsedBeforeBreakKey))
        
        
        // overtime stuff
        
        // multiplier stuff
        
        self._payMultiplier = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.payMultiplierKey))
        self._isMultiplierEnabled = .init(initialValue: sharedUserDefaults.bool(forKey: shiftKeys.multiplierEnabledKey))
        
        
        // i dont know if ill use this, its old:
        self._overtimeMultiplier = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.overtimeMultiplierKey))
        
        self._isOvertime = .init(initialValue: sharedUserDefaults.bool(forKey: shiftKeys.isOvertimeKey))
        
        self._overtimeEnabled = .init(initialValue: sharedUserDefaults.bool(forKey: shiftKeys.overtimeEnabledKey))
        
        if let uuidString = sharedUserDefaults.string(forKey: "SelectedJobUUID"), let uuid = UUID(uuidString: uuidString) {
            self._selectedJobUUID = .init(initialValue: uuid)
        } else {
            self._selectedJobUUID = .init(initialValue: nil)
        }
        
        
    }
    
    var breakElapsed: TimeInterval {
        guard let breakStartDate = breakStartDate, let breakEndDate = breakEndDate else { return 0 }
        return breakEndDate.timeIntervalSince(breakStartDate)
    }
    
    // NEW totalPay and taxedPay factoring in overtime
    
  var totalPay: Double {
        guard let shift = shift else { return 0 }
        
        let elapsed = Date().timeIntervalSince(shift.startDate) - totalBreakDuration()
        
        if elapsed >= applyOvertimeAfter && timeElapsedUntilOvertime == 0 && overtimeRate > 1.0 {
            timeElapsedUntilOvertime = elapsed
            overtimeEnabled = true
            print("overtime was set to true")
 
        } else {
            print("not overtime yet")
        }
        
        let basePay = (timeElapsedUntilOvertime > 0 ? timeElapsedUntilOvertime : elapsed) / 3600.0 * Double(shift.hourlyPay)
        let overtimePay = overtimeEnabled ? (elapsed - timeElapsedUntilOvertime) / 3600.0 * Double(shift.hourlyPay) * overtimeRate : 0
        
        let pay = basePay + overtimePay
        
        return isMultiplierEnabled ? pay * payMultiplier : pay
    }
    
    
    var taxedPay: Double {
        let pay = totalPay
        let afterTax = pay - (pay * Double(taxPercentage) / 100.0)
        return afterTax
    }
    
    // this func is used for calculating the total pay when the shift is ended, as the user may provide a custom end date
    func computeTotalPay(for endDate: Date) -> Double {
        guard let shift = shift else {
            
            print("im returning 0")
            
            return 0 }
        
        let elapsed = endDate.timeIntervalSince(shift.startDate) - totalBreakDuration()
        
        var computeOvertimeEnabled = false
        
        var elapsedTimeUntilOvertime = timeElapsedUntilOvertime
        
        if applyOvertimeAfter > 0 && enableOvertime {
            if elapsed >= applyOvertimeAfter && timeElapsedUntilOvertime == 0 {
                
                // this was modifying the global variable. this may have been fine for when calling this when ending a shift, but now that we call it upon starting a break
                // we will make a local copy instead and use that
                
                
                  elapsedTimeUntilOvertime = elapsed
                computeOvertimeEnabled = true
            }
        }
        
        let basePay = (elapsedTimeUntilOvertime > 0 ? elapsedTimeUntilOvertime : elapsed) / 3600.0 * Double(shift.hourlyPay)
        let overtimePay = computeOvertimeEnabled ? (elapsed - elapsedTimeUntilOvertime) / 3600.0 * Double(shift.hourlyPay) * overtimeRate : 0
        
        var pay = basePay
        if enableOvertime {
            pay += overtimePay
        }
        
        return isMultiplierEnabled ? pay * payMultiplier : pay
    }
    
    
    
    
    func totalBreakDuration() -> TimeInterval {
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
    
    func breakLength(startDate: Date?, endDate: Date?) -> Int {
        guard let start = startDate, let end = endDate else { return 0 }
        let duration = end.timeIntervalSince(start)
        let minutes = Int(duration) / 60
        return minutes
    }
    
    func breakLengthInMinutes(startDate: Date?, endDate: Date?) -> String {
        let minutes = breakLength(startDate: startDate, endDate: endDate)
        if minutes == 0 {
            
            return "N/A"
            
        }
        if minutes == 1 {
            return "\(minutes) minute"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    
    func deleteBreaks(at offsets: IndexSet) {
        tempBreaks.remove(atOffsets: offsets)
    }
    
    func deleteSpecificBreak(breakItem: TempBreak) {
        if let index = tempBreaks.firstIndex(where: { $0 == breakItem }) {
            tempBreaks.remove(at: index)
        }
    }
    
    func previousBreakEndDate(for breakItem: TempBreak) -> Date? {
        let sortedBreaks = tempBreaks.sorted { $0.startDate < $1.startDate }
        if let index = sortedBreaks.firstIndex(of: breakItem), index > 0 {
            return sortedBreaks[index - 1].endDate
        }
        return nil
    }
    
    func saveHourlyPay() {
        sharedUserDefaults.set(hourlyPay, forKey: shiftKeys.hourlyPayKey)
    }
    func saveLastPay() {
        sharedUserDefaults.set(lastPay, forKey: shiftKeys.lastPayKey)
        //saved last pay to userdefaults
    }
    func saveLastTaxedPay() {
        sharedUserDefaults.set(lastTaxedPay, forKey: shiftKeys.lastTaxedPayKey)
        //saved last taxed pay to userdefaults
    }
    
    func saveTaxPercentage() {
        sharedUserDefaults.set(taxPercentage, forKey: shiftKeys.taxPercentageKey)
        //saved tax percentage to userdefaults
    }
    
    public func saveLastBreak() {
        sharedUserDefaults.set(lastBreakElapsed, forKey: shiftKeys.lastBreakElapsedKey)
        //saved last break to userdefaults
    }
    
    func saveOvertimeMultiplier() {
        sharedUserDefaults.set(overtimeMultiplier, forKey: shiftKeys.overtimeMultiplierKey)
        //saved tax percentage to userdefaults
    }
    
    func savePayMultiplier() {
        sharedUserDefaults.set(payMultiplier, forKey: shiftKeys.payMultiplierKey)
    }
    
    func saveIsMultiplierEnabled() {
        sharedUserDefaults.set(isMultiplierEnabled, forKey: shiftKeys.multiplierEnabledKey)
    }
    
    
    func saveSelectedTags() {
        let tagsData = try? JSONEncoder().encode(selectedTags)
        sharedUserDefaults.set(tagsData, forKey: shiftKeys.selectedTags)
    }
    
    func loadSelectedTags() {
        guard let tagsData = sharedUserDefaults.data(forKey: shiftKeys.selectedTags) else { return }
        selectedTags = (try? JSONDecoder().decode(Set<UUID>.self, from: tagsData)) ?? []
    }
    
    func removeSelectedTags() {
        sharedUserDefaults.removeObject(forKey: shiftKeys.selectedTags)
    }
    
    
    
    func saveTempBreaksToUserDefaults() {
        let tempBreaksDictionaries = tempBreaksToDictionaries(tempBreaks: tempBreaks)
        sharedUserDefaults.set(tempBreaksDictionaries, forKey: shiftKeys.tempBreaksKey)
        
        print("after saving breaks the count is: \(tempBreaksDictionaries.count)")
        
    }
    
    func clearTempBreaksFromUserDefaults() {
        sharedUserDefaults.removeObject(forKey: shiftKeys.tempBreaksKey)
    }
    
    func loadTempBreaksFromUserDefaults() {
        if let tempBreaksDictionaries = sharedUserDefaults.array(forKey: shiftKeys.tempBreaksKey) as? [[String: Any]] {
            let loadedBreaks = dictionariesToTempBreaks(dictionaries: tempBreaksDictionaries)
            
            for tempBreak in loadedBreaks {
                if tempBreak.endDate == nil {
                    startBreak(startDate: tempBreak.startDate, isUnpaid: tempBreak.isUnpaid)
                } else {
                    tempBreaks.append(tempBreak)
                }
            }
            
        }
        
        print("after loading breaks the count is: \(tempBreaks.count)")
    }
    
    func saveCurrentBreakIndexToUserDefaults() {
        sharedUserDefaults.set(tempBreaks.count - 1, forKey: "currentBreakIndex")
    }
    
    func loadCurrentBreakIndexFromUserDefaults() -> Int? {
        return sharedUserDefaults.object(forKey: "currentBreakIndex") as? Int
    }
    
    func clearCurrentBreakIndexFromUserDefaults() {
        sharedUserDefaults.removeObject(forKey: "currentBreakIndex")
    }
    
    func indexOfTempBreak(withId id: UUID) -> Int? {
        return tempBreaks.firstIndex(where: { $0.id == id })
    }
    
    func updateBreak(oldBreak: TempBreak, newBreak: TempBreak) {
        if let index = tempBreaks.firstIndex(of: oldBreak) {
            tempBreaks[index] = newBreak
        }
    }
    
    
    func startBreak(startDate: Date? = nil, isUnpaid: Bool) {
        print("Starting break")
        
        
        
        //   breakStartDate = startDate
        
        // add the break to tempBreaks
        
        let breakStartDate = startDate ?? Date()
        let currentBreak = TempBreak(startDate: breakStartDate, endDate: nil, isUnpaid: isUnpaid)
        tempBreaks.append(currentBreak)
        
        saveTempBreaksToUserDefaults()
        saveCurrentBreakIndexToUserDefaults()
        isOnBreak = true
        sharedUserDefaults.set(isOnBreak, forKey: shiftKeys.isOnBreakKey)
        
        //   sharedUserDefaults.set(timeElapsed, forKey: shiftKeys.timeElapsedBeforeBreakKey)
        
        /*   if sharedUserDefaults.object(forKey: shiftKeys.timeElapsedBeforeBreakKey) == nil {
         sharedUserDefaults.set(timeElapsed, forKey: shiftKeys.timeElapsedBeforeBreakKey)
         } */
        
#if os(iOS)
        updateActivity(startDate: currentBreak.startDate, isUnpaid: isUnpaid)
#endif
        // stopTimer(timer: &timer, timeElapsed: &timeElapsed)
        
        if isUnpaid {
            
          /*  if let startDate = startDate, startDate < Date() {
                let computedPay = computeTotalPay(for: startDate)
                totalPayAtBreakStart = computedPay
                } else {
            
            totalPayAtBreakStart = totalPay
            
           }*/
            
            totalPayAtBreakStart = computeTotalPay(for: currentBreak.startDate)
            
            // timeElapsed = sharedUserDefaults.object(forKey: shiftKeys.timeElapsedBeforeBreakKey) as! TimeInterval
        }
        startBreakTimer(startDate: currentBreak.startDate)
        
    }
    
    func cancelBreak() {
        print("Cancelling break")
        
        // Remove the last added break from tempBreaks if one exists
        
        withAnimation(.spring(duration: 1.0)) {
            
            if !tempBreaks.isEmpty {
                
                    tempBreaks.removeLast()
                
                saveTempBreaksToUserDefaults()
            }
            
            // Reset the totalPayAtBreakStart to revert the pay calculation
            totalPayAtBreakStart = 0.0
            
            // Reset isOnBreak
    
            isOnBreak = false
            
            sharedUserDefaults.set(isOnBreak, forKey: shiftKeys.isOnBreakKey)
            
            stopTimer(timer: &breakTimer, timeElapsed: &breakTimeElapsed)
            
        }
        
#if os(iOS)
        updateActivity(startDate: shift?.startDate ?? Date())
#endif
        
        
        
    }
    
    
    
    
    func stopTimer(timer: inout Timer?, timeElapsed: inout TimeInterval) {
        timer?.invalidate()
        timer = nil
        timeElapsed = 0
    }
    
    func startBreakTimer(startDate: Date) {
        
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            withAnimation{
                self.breakTimeElapsed = Date().timeIntervalSince(startDate)
            }
        }
    }
    
    func endShift(using viewContext: NSManagedObjectContext, endDate: Date, job: Job) -> OldShift? {
#if os(iOS)
        stopActivity()
#endif
        
        
        print("time elapsed until overtime was: \(timeElapsedUntilOvertime)")
        print("ending shift, overtime time elapsed is: \(timeElapsed - timeElapsedUntilOvertime)")
        
        // cancel any potential upcoming break reminders that may not have been triggered yet
        cancelBreakReminder()
        
        
        let overtimeElapsed = timeElapsed - timeElapsedUntilOvertime
        
        stopTimer(timer: &timer, timeElapsed: &timeElapsed)
        breakTaken = false
        isOvertime = false
        
        
        
        shiftEnded = true
        sharedUserDefaults.removeObject(forKey: shiftKeys.shiftStartDateKey)
        sharedUserDefaults.removeObject(forKey: shiftKeys.breakStartedDateKey)
        sharedUserDefaults.removeObject(forKey: shiftKeys.breakEndedDateKey)
        sharedUserDefaults.removeObject(forKey: shiftKeys.timeElapsedBeforeBreakKey) // destroys the time elapsed before break
        sharedUserDefaults.set(breakTaken, forKey: shiftKeys.breakTakenKey)
        sharedUserDefaults.set(true, forKey: shiftKeys.shiftEndedKey)
        sharedUserDefaults.set(false, forKey: shiftKeys.overtimeEnabledKey)
        
        
        var latestShift: OldShift? = nil
        if shiftState != .countdown {
            
            if let shift = shift {
                self.lastPay = totalPay
                self.lastTaxedPay = taxedPay
                saveLastPay() // Save the value of lastPay to UserDefaults
                saveLastTaxedPay()
                self.lastBreakElapsed = breakElapsed
                saveLastBreak()
                
                let newTotalPay = computeTotalPay(for: endDate)
                let newTaxedPay = newTotalPay - (newTotalPay * Double(taxPercentage) / 100.0)
                
                latestShift = OldShift(context: viewContext)
                latestShift!.hourlyPay = shift.hourlyPay
                latestShift!.shiftStartDate = shift.startDate
                latestShift!.shiftEndDate = endDate
                latestShift!.totalPay = newTotalPay
                latestShift!.taxedPay = newTaxedPay
                latestShift!.tax = Double(taxPercentage)
                latestShift!.breakElapsed = breakElapsed
                latestShift!.duration = endDate.timeIntervalSince(shift.startDate)
                latestShift!.overtimeDuration = overtimeElapsed
                latestShift!.timeBeforeOvertime = timeElapsedUntilOvertime
                latestShift!.overtimeEnabled = enableOvertime
                latestShift!.overtimeRate = overtimeRate
                latestShift!.multiplierEnabled = isMultiplierEnabled
                latestShift!.payMultiplier = payMultiplier
                
                latestShift!.breakDuration = totalBreakDuration()
                
                latestShift!.shiftID = UUID()
                
                latestShift!.job = job
                
                let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "tagID IN %@", selectedTags)
                let selectedTagEntities = try? viewContext.fetch(fetchRequest)
                
                latestShift!.tags = NSSet(array: selectedTagEntities ?? [])
                
                // empty the selected tags
                selectedTags = Set<UUID>()
                removeSelectedTags()
                
                
                for tempBreak in tempBreaks {
                    if let breakEndDate = tempBreak.endDate {
                        breaksManager.createBreak(oldShift: latestShift!, startDate: tempBreak.startDate, endDate: breakEndDate, isUnpaid: tempBreak.isUnpaid, in: viewContext)
                    }
                }
                
                //PersistenceController.shared.save()
                if latestShift!.duration > 0 {
                    do {
                        try viewContext.save()
                        
                    } catch {
                        print("Error saving new shift: \(error)")
                    }
                }
                
                
            }
        }
        
        shiftState = .notStarted
        
        sharedUserDefaults.removeObject(forKey: shiftKeys.lastBreakElapsedKey)
        shift = nil
        shiftEnded = true
        overtimeDuration = 0
        
        timeElapsedUntilOvertime = 0 // reset time elapsed until overtime if it exists
        
        isPresented = true
        //   breakStartDate = nil
        //  breakEndDate = nil
        
        tempBreaks.removeAll()
        clearTempBreaksFromUserDefaults()
        isMultiplierEnabled = false
        payMultiplier = 1.0
        overtimeEnabled = false
        
        return latestShift
    }
    
    func endBreak(endDate: Date? = nil, viewContext: NSManagedObjectContext) {
        
        print("At endBreak start: totalPay=\(totalPay), totalPayAtBreakStart=\(totalPayAtBreakStart), isOnBreak=\(isOnBreak)")

        
        tempBreaks[tempBreaks.count - 1].endDate = endDate ?? Date()
        
        saveTempBreaksToUserDefaults()
        
        
        print("UPDATING ACTIVITY \(breakTimeElapsed)")
        
        isOnBreak = false
#if os(iOS)
        updateActivity(startDate: shift?.startDate ?? Date())
#endif
        
        
        stopTimer(timer: &breakTimer, timeElapsed: &breakTimeElapsed)
        
        sharedUserDefaults.set(isOnBreak, forKey: shiftKeys.isOnBreakKey)
        
        totalPayAtBreakStart = 0.0
        
        print("total pay at break end is: \(totalPay)")
        
        // TEMP DISABLED UNTIL MULTIPLE BREAKS WORKING
        
        
        //    guard let breakStartDate = breakStartDate else { return } // Check if break has started
        print("ending break")
        // breakEndDate = Date()
        // sharedUserDefaults.set(breakEndDate, forKey: shiftKeys.breakEndedDateKey)
        
        
        
        
        // lastBreakElapsed = breakTimeElapsed
        
        
        // stopTimer(timer: &breakTimer, timeElapsed: &breakTimeElapsed)
        
        sharedUserDefaults.removeObject(forKey: shiftKeys.timeElapsedBeforeBreakKey)
        
        
        isOnBreak = false
        sharedUserDefaults.set(isOnBreak, forKey: shiftKeys.isOnBreakKey)
        // saveLastBreak()
        // print(lastBreakElapsed)
        
        if tempBreaks[tempBreaks.count - 1].isUnpaid{
            // startTimer(startDate: Date(), viewContext: viewContext)
        }
        
        print("At endBreak end: totalPay=\(totalPay), totalPayAtBreakStart=\(totalPayAtBreakStart), isOnBreak=\(isOnBreak)")

     
        
    }
    
    func startTimer(startDate: Date, viewContext: NSManagedObjectContext) {
        
        if shift != nil{
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.timeElapsed = Date().timeIntervalSince(startDate)// - self.totalBreakDuration()
                
                if self.shiftState == .countdown && self.timeElapsed >= 0 {
                    self.shiftState = .inProgress
                }
                
                
                
            }
#if os(iOS)
            startActivity(startDate: startDate, hourlyPay: hourlyPay, viewContext: viewContext)
#endif
        }
        else {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.timeElapsed = Date().timeIntervalSince(startDate)
                
                if self.shiftState == .countdown && self.timeElapsed >= 0 {
                    self.shiftState = .inProgress
                }
                
                
            }
#if os(iOS)
            startActivity(startDate: startDate, hourlyPay: hourlyPay, viewContext: viewContext)
#endif
        }
        
    }
#if os(iOS)
    func startActivity(startDate: Date, hourlyPay: Double, viewContext: NSManagedObjectContext){
        if #available(iOS 16.2, *) {
            guard let job = fetchJob(with: self.selectedJobUUID, in: viewContext) else { return }
            
            
            
            let attributes = LiveActivityAttributes(jobName: job.name ?? "Unnamed", jobTitle: job.title ?? "No Title", jobIcon: job.icon ?? "briefcase.circle", jobColorRed: Double(job.colorRed), jobColorGreen: Double(job.colorGreen), jobColorBlue: Double(job.colorBlue), hourlyPay: hourlyPay)
            let state = LiveActivityAttributes.TimerStatus(startTime: startDate, totalPay: totalPay, isOnBreak: false)
            
            let activityContent = ActivityContent(state: state, staleDate: nil)
            
            if (self.currentActivity == nil && self.activityEnabled){
                
                
                self.currentActivity = try? Activity.request(attributes: attributes, content: activityContent, pushType: nil)
                
                print("Created activity")
            }
            
            
        }
        
        
    }
    
    func stopActivity(){
        if #available(iOS 16.2, *) {
        let newState = LiveActivityAttributes.TimerStatus(startTime: Date(), totalPay: 0, isOnBreak: false)
        
            let finalContent = ActivityContent(state: newState, staleDate: nil)
            
            
            Task{
                
                for activity in Activity<LiveActivityAttributes>.activities {
                    
                    await activity.end(finalContent, dismissalPolicy: .immediate)
                    
                }
            }
            
            self.currentActivity = nil
            
        }
        
    }
    
    func updateActivity(startDate: Date, isUnpaid: Bool = false){
        if #available(iOS 16.2, *) {
            Task{
                
                let updatedState = LiveActivityAttributes.TimerStatus(startTime: startDate, totalPay: 0, isOnBreak: isOnBreak, unpaidBreak: isUnpaid)
                
                let updatedContent = ActivityContent(state: updatedState, staleDate: nil)
                
                if let activity = currentActivity as? Activity<LiveActivityAttributes> {
                                await activity.update(updatedContent, alertConfiguration: nil)
                            }
            }
        }
    }
#endif
    
    
    func startShift(using viewContext: NSManagedObjectContext, startDate: Date, job: Job) {
        if shift == nil{ // PERHAPS YOU DONT NEED THIS?
            if(hourlyPay == 0){
                return
            }
            else {
                
                if startDate > Date() {
                    shiftState = .countdown
                    // Setup countdown
                } else {
                    shiftState = .inProgress
                    // Setup timer
                }
                
                
                // lol this isnt actually using the hourly pay here...
                shift = Shift(startDate: startDate, hourlyPay: job.hourlyPay)
                sharedUserDefaults.set(shift?.startDate, forKey: shiftKeys.shiftStartDateKey)
                
                print("starting shift, time elapsed until overtime started was: \(timeElapsedUntilOvertime)")
                
                if job.overtimeEnabled {
                    print("overtime is enabled when the shift started")
                    self.applyOvertimeAfter = job.overtimeAppliedAfter
                    print("Overtime will be applied after: \(applyOvertimeAfter)")
                    self.overtimeRate = job.overtimeRate
                    
                    self.enableOvertime = job.overtimeEnabled
                    
                } else {
                    self.applyOvertimeAfter = 0
                    self.overtimeRate = 1.0
                }
                
                
                if let savedTimeElapsed = sharedUserDefaults.object(forKey: shiftKeys.timeElapsedBeforeBreakKey) as? TimeInterval {
                    // timeElapsed = savedTimeElapsed
                }
                
                startTimer(startDate: startDate, viewContext: viewContext)
                
                shiftsTracked += 1
            }
            
            if isMultiplierEnabled {
                print("multiplier is enabled")
                
                print("multiplier rate is: \(payMultiplier)")
                
                
            }
            
            loadTempBreaksFromUserDefaults()
            
            
            print("temp break count after starting break is now: \(tempBreaks.count)")
            
            shiftEnded = false
            sharedUserDefaults.set(false, forKey: shiftKeys.shiftEndedKey)
            shiftStartDate = startDate // sets the picker value to startDate of the shift every time
        }
    }
    
    private var shiftStartDateString: String? {
        guard let shiftStartDate = sharedUserDefaults.object(forKey: shiftKeys.shiftStartDateKey) as? Date else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: shiftStartDate)
    }
#if os(iOS)
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }
#endif
    
    func startShiftButtonAction(using viewContext: NSManagedObjectContext, startDate: Date, job: Job) {
        startShift(using: viewContext, startDate: startDate, job: job)
        shiftStartDate = startDate
        // Add notification logic
        
#if os(iOS)
        if hourlyPay != 0 {
            let content = UNMutableNotificationContent()
            content.title = "ShiftTracker"
            content.subtitle = "Let the money roll in! Enjoy your shift."
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 8, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
            
            if job.breakReminder && breakReminder {
                
                scheduleBreakReminder(after: job.breakReminderTime, startDate: startDate)
            }
            
        }
        
        
#endif
    }
    
    func scheduleBreakReminder(after timeInterval: TimeInterval, startDate: Date) {
        
        let breakDate = startDate.addingTimeInterval(timeInterval)
            let currentDateTime = Date()
        
        if breakDate < currentDateTime {
                print("break reminder time already passed")
                return
            }
        
        let content = UNMutableNotificationContent()
        content.title = "Break Time!"
        content.body = "It's time for your break."

        let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: breakDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(identifier: "BreakReminder", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    
    func cancelBreakReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["BreakReminder"])
    }
    
    // multiple breaks stuff:
    
    func tempBreaksToDictionaries(tempBreaks: [TempBreak]) -> [[String: Any]] {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(tempBreaks)
        let jsonArray = (try? JSONSerialization.jsonObject(with: data!, options: [])) as? [[String: Any]]
        return jsonArray ?? []
    }
    
    func dictionariesToTempBreaks(dictionaries: [[String: Any]]) -> [TempBreak] {
        let decoder = JSONDecoder()
        let jsonData = try? JSONSerialization.data(withJSONObject: dictionaries, options: [])
        let tempBreaks = try? decoder.decode([TempBreak].self, from: jsonData!)
        return tempBreaks ?? []
    }
    
    
    // used for auto rounding a job start date:
    
    func roundDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        
        // Get components for year, month, day, hour, and minute.
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        guard let hour = components.hour, let minute = components.minute else {
            fatalError("Invalid date components")
        }
        
        var roundedHour = hour
        var roundedMinute: Int
        
        switch minute {
        case 0...7:
            roundedMinute = 0
        case 8...22:
            roundedMinute = 15
        case 23...37:
            roundedMinute = 30
        case 38...52:
            roundedMinute = 45
        case 53...59:
            roundedMinute = 0
            roundedHour += 1
        default:
            fatalError("Invalid minute component")
        }
        
        var newComponents = DateComponents()
        newComponents.year = components.year
        newComponents.month = components.month
        newComponents.day = components.day
        newComponents.hour = roundedHour
        newComponents.minute = roundedMinute
        return calendar.date(from: newComponents) ?? date
    }
    
    
}

