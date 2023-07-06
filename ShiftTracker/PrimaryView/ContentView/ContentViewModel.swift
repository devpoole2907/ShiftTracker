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


class ContentViewModel: ObservableObject {
    
    
    @Published var shiftState: ShiftState = .notStarted
    
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
    @Published  var timeElapsed: TimeInterval = 0
    @Published  var breakTimeElapsed: TimeInterval = 0
    @Published  var overtimeElapsed: TimeInterval = 0
    @Published  var timer: Timer?
    @Published  var breakTimer: Timer?
    @Published  var overtimeTimer: Timer?
    @Published  var isFirstLaunch = false
    @Published  var isPresented = false
    
    @Published  var showEndAlert = false
    @Published  var showStartBreakAlert = false
    @Published  var showEndBreakAlert = false
    @Published  var showStartOvertimeAlert = false
    
    @Published  var timeElapsedBeforeBreak = 0.0
    
    @Published  var isOnBreak = false
    @Published  var isOvertime = false
    @Published var overtimeEnabled = false
    
    @Published  var shiftEnded = false
    
    @Published  var breakStartDate: Date?
    @Published  var breakEndDate: Date?
    @Published  var overtimeStartDate: Date?
    @Published private var overtimeRate = 1.25
    @Published private var overtimeAppliedAfter: TimeInterval = 1.0
    #if os(iOS)
    @Published  var engine: CHHapticEngine?
    #endif
    
    @Published  var automaticBreak = false
    
    // we need this, to pause the timer etc if the user wants to edit
    @Published  var isEditing = false
    
    @Published  var isStartShiftTapped = false
    @Published  var isEndShiftTapped = false
    @Published  var isBreakTapped = false
    
    @Published  var breakTaken = false
    
    @Published  var shouldShowPopup = false
    
    //some context menu stuff:
    @Published  var isAutomaticBreak = false
    
    @Published  var shiftStartDate: Date = Date()// this needs to be the date the shift started, not Date()
    
    //  @State private var activity: Activity<ShiftTrackerWidgetAttributes>? = nil
    #if os(iOS)
    @Published  var isActivityEnabled: Bool = true
    @Published  var currentActivity: Activity<ShiftTrackerWidgetAttributes>?
    #endif
    
    @Published  var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    @Published var selectedJobUUID: UUID?
    
    @Published private var overtimeDuration: TimeInterval = 0
    
    private let shiftKeys = ShiftKeys()
    
    
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
        
        self._overtimeRate = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.overtimeMultiplierKey))
        self._overtimeAppliedAfter = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.overtimeAppliedAfterKey))
        
        
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
 /* // original totalPay and taxedPay excluding overtime
    var totalPay: Double {
        guard let shift = shift else { return 0 }
        let elapsed = Date().timeIntervalSince(shift.startDate) - totalBreakDuration()
        let pay = (elapsed / 3600.0) * Double(shift.hourlyPay)
        return pay
    }
    
    var taxedPay: Double {
        guard let shift = shift else { return 0 }
        let elapsed = Date().timeIntervalSince(shift.startDate) - totalBreakDuration()
        let pay = (elapsed / 3600.0) * Double(shift.hourlyPay)
        let afterTax = pay - (pay * Double(taxPercentage) / 100.0)
        return afterTax
    }
  
  */
    
    // NEW totalPay and taxedPay factoring in overtime
    
    var totalPay: Double {
        guard let shift = shift else { return 0 }
        
        let elapsed = Date().timeIntervalSince(shift.startDate) - totalBreakDuration()
        if elapsed <= overtimeAppliedAfter || !sharedUserDefaults.bool(forKey: shiftKeys.overtimeEnabledKey){
            let pay = (elapsed / 3600.0) * Double(shift.hourlyPay)
            overtimeDuration = 0
            return pay
        }
        else {
            print("OVERTIME!!!!")
            isOvertime = true
            let regularTime = overtimeAppliedAfter //* 3600.0
            let overtime = elapsed - regularTime
            let regularPay = (regularTime / 3600.0) * Double(shift.hourlyPay)
            let overtimePay = (overtime / 3600.0) * Double(shift.hourlyPay) * overtimeRate // Multiply by overtimeRate
            
            overtimeDuration = overtime
            
            
            return regularPay + overtimePay
        }
    }
    
    var taxedPay: Double {
        let pay = totalPay
        let afterTax = pay - (pay * Double(taxPercentage) / 100.0)
        return afterTax
    }
    
    // this func is used for calculating the total pay when the shift is ended, as the user may provide a custom end date
    func computeTotalPay(for endDate: Date) -> Double {
        guard let shift = shift else { return 0 }
        
        let elapsed = endDate.timeIntervalSince(shift.startDate) - totalBreakDuration()
        if elapsed <= overtimeAppliedAfter || !sharedUserDefaults.bool(forKey: shiftKeys.overtimeEnabledKey) {
            let pay = (elapsed / 3600.0) * Double(shift.hourlyPay)
            return pay
        }
        else {
            print("OVERTIME!!!!")
            isOvertime = true
            let regularTime = overtimeAppliedAfter //* 3600.0
            let overtime = elapsed - regularTime
            let regularPay = (regularTime / 3600.0) * Double(shift.hourlyPay)
            let overtimePay = (overtime / 3600.0) * Double(shift.hourlyPay) * overtimeRate // Multiply by overtimeRate

            return regularPay + overtimePay
        }
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
    
     func breakLengthInMinutes(startDate: Date?, endDate: Date?) -> String {
        guard let start = startDate, let end = endDate else { return "N/A" }
        let duration = end.timeIntervalSince(start)
        let minutes = Int(duration) / 60
        return "\(minutes) minutes"
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
    
    func checkOvertime() {
        if timeElapsed > overtimeAppliedAfter  && !isOvertime {
            isOvertime = true
            print("OVERTIME BABYYYY")
        } else if timeElapsed <= overtimeAppliedAfter && isOvertime {
            isOvertime = false
        }
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
        
        func saveTempBreaksToUserDefaults() {
            let tempBreaksDictionaries = tempBreaksToDictionaries(tempBreaks: tempBreaks)
            UserDefaults.standard.set(tempBreaksDictionaries, forKey: "tempBreaks")
        }
        
        func clearTempBreaksFromUserDefaults() {
            UserDefaults.standard.removeObject(forKey: "tempBreaks")
        }
        
        func loadTempBreaksFromUserDefaults() {
            if let tempBreaksDictionaries = UserDefaults.standard.array(forKey: "tempBreaks") as? [[String: Any]] {
                tempBreaks = dictionariesToTempBreaks(dictionaries: tempBreaksDictionaries)
            }
        }
        
        func saveCurrentBreakIndexToUserDefaults() {
            UserDefaults.standard.set(tempBreaks.count - 1, forKey: "currentBreakIndex")
        }
        
        func loadCurrentBreakIndexFromUserDefaults() -> Int? {
            return UserDefaults.standard.object(forKey: "currentBreakIndex") as? Int
        }
        
        func clearCurrentBreakIndexFromUserDefaults() {
            UserDefaults.standard.removeObject(forKey: "currentBreakIndex")
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
            
            sharedUserDefaults.set(timeElapsed, forKey: shiftKeys.timeElapsedBeforeBreakKey)
            
            if sharedUserDefaults.object(forKey: shiftKeys.timeElapsedBeforeBreakKey) == nil {
                sharedUserDefaults.set(timeElapsed, forKey: shiftKeys.timeElapsedBeforeBreakKey)
            }
        if isUnpaid{
            #if os(iOS)
            updateActivity(startDate: currentBreak.startDate)
            #endif
            stopTimer(timer: &timer, timeElapsed: &timeElapsed)
            
            timeElapsed = sharedUserDefaults.object(forKey: shiftKeys.timeElapsedBeforeBreakKey) as! TimeInterval
        }
            startBreakTimer(startDate: currentBreak.startDate)
            
        }
        
        func stopTimer(timer: inout Timer?, timeElapsed: inout TimeInterval) {
            timer?.invalidate()
            timer = nil
            timeElapsed = 0
        }
        
        func startBreakTimer(startDate: Date) {
            
            breakTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.breakTimeElapsed = Date().timeIntervalSince(startDate)
            }
        }
        
    func endShift(using viewContext: NSManagedObjectContext, endDate: Date, job: Job) -> OldShift? {
#if os(iOS)
        stopActivity()
#endif
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
            latestShift!.overtimeDuration = overtimeDuration
            latestShift!.overtimeRate = overtimeRate
            
            latestShift!.job = job
            
            
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
            isPresented = true
            //   breakStartDate = nil
            //  breakEndDate = nil
            
            tempBreaks.removeAll()
            clearTempBreaksFromUserDefaults()
            
        return latestShift
        }
        
        func endBreak(endDate: Date? = nil) {
            
            tempBreaks[tempBreaks.count - 1].endDate = endDate ?? Date()
            
            saveTempBreaksToUserDefaults()
            
            
            print("UPDATING ACTIVITY \(breakTimeElapsed)")
         
            isOnBreak = false
            #if os(iOS)
         updateActivity(startDate: shift?.startDate.addingTimeInterval(totalBreakDuration()) ?? Date())
            #endif
            
            
            stopTimer(timer: &breakTimer, timeElapsed: &breakTimeElapsed)
            
            sharedUserDefaults.set(isOnBreak, forKey: shiftKeys.isOnBreakKey)
            
            
            
              
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
                startTimer(startDate: Date())
            }
        }
        
        func startTimer(startDate: Date) {
            
            if shift != nil{
                let adjustedStartDate = shift!.startDate
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    self.timeElapsed = Date().timeIntervalSince(adjustedStartDate) - self.totalBreakDuration()
                    
                    if self.shiftState == .countdown && self.timeElapsed >= 0 {
                                    self.shiftState = .inProgress
                                }
                    
                    
                    self.checkOvertime()
                }
                #if os(iOS)
                   startActivity(startDate: adjustedStartDate.addingTimeInterval(breakElapsed), hourlyPay: hourlyPay)
                #endif
            }
            else {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    self.timeElapsed = Date().timeIntervalSince(startDate)
                    
                    if self.shiftState == .countdown && self.timeElapsed >= 0 {
                                   self.shiftState = .inProgress
                               }
                    
                    self.checkOvertime()
                }
                #if os(iOS)
                  startActivity(startDate: startDate, hourlyPay: hourlyPay)
                #endif
            }
            
        }
    #if os(iOS)
        func startActivity(startDate: Date, hourlyPay: Double){
            let attributes = ShiftTrackerWidgetAttributes(name: "Shift started", hourlyPay: hourlyPay)
            let state = ShiftTrackerWidgetAttributes.TimerStatus(startTime: startDate, totalPay: totalPay, isOnBreak: false)
            
            if (self.currentActivity == nil){
                self.currentActivity = try? Activity<ShiftTrackerWidgetAttributes>.request(attributes: attributes, contentState: state, pushType: nil)
                print("Created activity")
            }
        }
        
        func stopActivity(){
            Task{
                guard let currentActivity else { return }
                
                let newState = ShiftTrackerWidgetAttributes.TimerStatus(startTime: Date(), totalPay: 0, isOnBreak: false)
                
                await currentActivity.end(using: newState,dismissalPolicy: .immediate)
            }
        }
        
        func updateActivity(startDate: Date){
            Task{
                guard let currentActivity else { return }
                
                let updatedState = ShiftTrackerWidgetAttributes.TimerStatus(startTime: startDate, totalPay: 0, isOnBreak: isOnBreak)
                
                await currentActivity.update(using: updatedState)
            }
        }
    #endif
        
        func startOvertime(startDate: Date) {
            print("Starting overtime")
            overtimeStartDate = startDate
            isOvertime = true
            sharedUserDefaults.set(overtimeStartDate, forKey: shiftKeys.overtimeStartDateKey)
            sharedUserDefaults.set(isOvertime, forKey: shiftKeys.isOvertimeKey)
            var tempTimeElapsed = timeElapsed
            stopTimer(timer: &timer, timeElapsed: &timeElapsed)
            timeElapsed = tempTimeElapsed
            startOvertimeTimer(startDate: overtimeStartDate ?? Date())
        }
        
        func startOvertimeTimer(startDate: Date) {
            
            overtimeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.overtimeElapsed = Date().timeIntervalSince(startDate)
            }
        }
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
                    
                    
                    if let savedTimeElapsed = sharedUserDefaults.object(forKey: shiftKeys.timeElapsedBeforeBreakKey) as? TimeInterval {
                        timeElapsed = savedTimeElapsed
                    }
                    
                    startTimer(startDate: startDate)
                }
                
                loadTempBreaksFromUserDefaults()
                if let currentBreakIndex = loadCurrentBreakIndexFromUserDefaults(),
                   currentBreakIndex < tempBreaks.count,
                   tempBreaks[currentBreakIndex].endDate == nil {
                    let ongoingBreakStartDate = tempBreaks[currentBreakIndex].startDate
                    if tempBreaks[currentBreakIndex].isUnpaid{
                        startBreak(startDate: ongoingBreakStartDate, isUnpaid: true)
                    }
                    else {
                        startBreak(startDate: ongoingBreakStartDate, isUnpaid: false)
                    }
                }
                
                
                
                
                
                /*   else if let breakStartedDate = sharedUserDefaults.object(forKey: shiftKeys.breakStartedDateKey) {
                 shift = Shift(startDate: startDate, hourlyPay: hourlyPay)
                 sharedUserDefaults.set(shift?.startDate, forKey: shiftKeys.shiftStartDateKey)
                 startTimer(startDate: startDate)
                 
                 if isOnBreak{
                 if let tempTimeElapsed = sharedUserDefaults.object(forKey: shiftKeys.timeElapsedBeforeBreakKey) as? Double{
                 startBreak(startDate: breakStartedDate as! Date, timeElapsedBeforeBreak: tempTimeElapsed)
                 }
                 else {
                 startBreak(startDate: breakStartedDate as! Date, timeElapsedBeforeBreak: timeElapsed)
                 }
                 }
                 } */
                
                /*      else {
                 shift = Shift(startDate: startDate, hourlyPay: hourlyPay)
                 sharedUserDefaults.set(shift?.startDate, forKey: shiftKeys.shiftStartDateKey)
                 startTimer(startDate: startDate)
                 /* if activity == nil{
                  print("STARTING ACTIVITY")
                  startActivity(startDate: shift?.startDate ?? Date(), hourlyPay: shift?.hourlyPay ?? 0.0)
                  } */
                 
                 startActivity(startDate: shift?.startDate ?? Date(), hourlyPay: shift?.hourlyPay ?? 0.0)
                 
                 
                 
                 
                 } */
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
            }
        #endif
        }
        
        func startBreakButtonAction() {
            showStartBreakAlert = true
          //  let tempElapsed = timeElapsed
           // stopTimer(timer: &timer, timeElapsed: &timeElapsed)
          //  timeElapsed = tempElapsed
        }
        
        func endBreakButtonAction() {
            showEndBreakAlert = true
      /*      let tempBreakElapsed = breakTimeElapsed
            stopTimer(timer: &breakTimer, timeElapsed: &breakTimeElapsed)
            breakTimeElapsed = tempBreakElapsed */
        }
        
        func endShiftButtonAction(){
            showEndAlert = true

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

