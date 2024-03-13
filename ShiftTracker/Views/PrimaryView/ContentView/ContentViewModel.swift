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
    
    @Published var payMultiplier: Double = 1.0
    
    @Published var isMultiplierEnabled: Bool = false
    
    
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
   // old @Published  var shift: Shift?
    
    @Published var currentShift: OldShift?
    
    @Published  var timeElapsed: TimeInterval = 0 {
        didSet {
            print("weird i got set?")
        }
    }
    
    @Published var scheduledShift: ScheduledShift? = nil
    
    
    @AppStorage("totalPayAtBreakStart") var totalPayAtBreakStart: Double = 0.0
    @Published  var breakTimeElapsed: TimeInterval = 0
    @Published  var overtimeElapsed: TimeInterval = 0
    @Published  var timer: Timer?
    @Published  var breakTimer: Timer?
    @Published  var overtimeTimer: Timer?
    @Published  var isFirstLaunch = false
    @Published  var isPresented = false
    @Published var activityEnabled = false
    
    @AppStorage("showTabButtonBadge") var showBadge = false
    
    @Published  var showEndAlert = false
    @Published  var showStartBreakAlert = false
    @Published  var showEndBreakAlert = false
    @Published  var showStartOvertimeAlert = false
    
    @Published var breakReminder = false
    @Published var breakReminderTime = 0.0
    
    @Published var clockOutReminder = false ////time based not location
    @Published var clockOutReminderTime: TimeInterval = 0.0
    @Published var autoClockOut = false
    @Published var autoClockOutTime: TimeInterval = 0.0
    
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
            return currentShift?.shiftStartDate ?? Date() // Return a default minimum date if no suitable break is found
        }
    }
    
    public let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var breakElapsed: TimeInterval {
        guard let breakStartDate = breakStartDate, let breakEndDate = breakEndDate else { return 0 }
        return breakEndDate.timeIntervalSince(breakStartDate)
    }
    
    // NEW totalPay and taxedPay factoring in overtime
    
  var totalPay: Double {
      guard let shift = currentShift, let shiftStartDate = shift.shiftStartDate else { return 0 }
        
        let elapsed = Date().timeIntervalSince(shiftStartDate) - totalBreakDuration()
        
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
        guard let shift = currentShift, let shiftStartDate = shift.shiftStartDate else {
            
            print("im returning 0")
            
            return 0 }
        
        let elapsed = endDate.timeIntervalSince(shiftStartDate) - totalBreakDuration()
        
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
        saveTempBreaksToUserDefaults()
    }
    
    func previousBreakEndDate(for breakItem: TempBreak) -> Date? {
        let sortedBreaks = tempBreaks.sorted { $0.startDate < $1.startDate }
        if let index = sortedBreaks.firstIndex(of: breakItem), index > 0 {
            return sortedBreaks[index - 1].endDate
        }
        return nil
    }
    
    func saveAutoClockOut() {
        sharedUserDefaults.set(autoClockOut, forKey: shiftKeys.autoClockOutKey)
        sharedUserDefaults.set(autoClockOutTime, forKey: shiftKeys.autoClockOutTimeKey)
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
        updateActivity(startDate: currentShift?.shiftStartDate ?? Date())
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

    
    func endBreak(endDate: Date? = nil, viewContext: NSManagedObjectContext) {
        
        print("At endBreak start: totalPay=\(totalPay), totalPayAtBreakStart=\(totalPayAtBreakStart), isOnBreak=\(isOnBreak)")

        
        tempBreaks[tempBreaks.count - 1].endDate = endDate ?? Date()
        
        saveTempBreaksToUserDefaults()
        
        
        print("UPDATING ACTIVITY \(breakTimeElapsed)")
        
        isOnBreak = false
#if os(iOS)
        updateActivity(startDate: currentShift?.shiftStartDate ?? Date())
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
    
    func newStartTimer(viewContext: NSManagedObjectContext){
        
        if let currentShift = self.currentShift, let startDate = currentShift.shiftStartDate {
            
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.timeElapsed = Date().timeIntervalSince(startDate)
                
                if self.shiftState == .countdown && self.timeElapsed >= 0 {
                    self.shiftState = .inProgress
                }
                
                
            }
#if os(iOS)
            startActivity(startDate: startDate, hourlyPay: hourlyPay, viewContext: viewContext)
#endif
            
        } else {
            return
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
    
    func stopActivity(startDate: Date, totalPay: Double? = nil, taxedPay: Double? = nil, shiftDuration: Double? = nil, breakDuration: Double? = nil, endDate: Date? = nil){
        if #available(iOS 16.2, *) {
            
            // update me to have an overview state containing total shift duration, total earnings and break duration
            
            let newState = LiveActivityAttributes.TimerStatus(startTime: startDate, totalPay: totalPay, taxedPay: taxedPay, shiftDuration: shiftDuration, breakDuration: breakDuration, endTime: endDate, isOnBreak: false)
        
            let finalContent = ActivityContent(state: newState, staleDate: nil)
            
           
            
            
            Task{
                
                // update the live activity with the final overview content
                if let activity = currentActivity as? Activity<LiveActivityAttributes> {
                                await activity.update(finalContent, alertConfiguration: nil)
                            }
                
                for activity in Activity<LiveActivityAttributes>.activities {
                        // dismiss live activity automatically after 1 hour
                    
                    if let _ = totalPay, let _ = taxedPay {
                        
                        // a shift ended since these variables exist, otherwise it would be a cancelled shift - we need to show the activity for an hour letting the user dismiss it
                        // it will display an overview state
                        
                        await activity.end(finalContent, dismissalPolicy: .after(.now.addingTimeInterval(3600)))
                        
                        // dismiss immediately no overview state
                    } else {
                        await activity.end(finalContent, dismissalPolicy: .immediate)
                    }
                    
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
    
    func checkForActiveShiftAndManageTimer(using viewContext: NSManagedObjectContext, completion: @escaping (Bool, Error?) -> Void) {
            let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isActive == YES")
            do {
                let activeShifts = try viewContext.fetch(fetchRequest)
                if activeShifts.isEmpty {
                    stopTimer(timer: &timer, timeElapsed: &timeElapsed)
                    completion(false, nil)
                    print("No active shift found. Timer stopped.")
                } else {
                    print("found active shift")
                }
                
                completion(true, nil)
                
            } catch {
                print("Failed to fetch active shifts: \(error.localizedDescription)")
                
            }
        }
    
    func newStartShift(using viewContext: NSManagedObjectContext, startDate: Date? = nil, job: Job? = nil) {
        
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        do {
            let activeShifts = try viewContext.fetch(fetchRequest)
            if let activeShift = activeShifts.first {
                print("Resuming active shift with start date: \(String(describing: activeShift.shiftStartDate))")
                updateViewModelForActiveShift(activeShift)
                newStartTimer(viewContext: viewContext)
                loadSelectedTags()
                loadTempBreaksFromUserDefaults()
                return
            }
        } catch {
            print("Failed to check for active shifts: \(error.localizedDescription)")
        }

        guard let startDate = startDate, let job = job else {
            print("Missing startDate or job for new shift. Cannot proceed.")
            return
        }

        let newShift = OldShift(context: viewContext)
        newShift.shiftStartDate = startDate
        newShift.hourlyPay = job.hourlyPay
        newShift.isActive = true
        newShift.job = job
        newShift.payMultiplier = payMultiplier
        newShift.multiplierEnabled = isMultiplierEnabled
        setupNewShiftDetails(newShift, with: job)
        updateViewModelForActiveShift(newShift)

        loadTempBreaksFromUserDefaults()
        loadSelectedTags()

        do {
            try viewContext.save()
            
            print("New shift started successfully.")
        } catch {
            print("Failed to start new shift: \(error.localizedDescription)")
        }
        
        newStartTimer(viewContext: viewContext)
     
        
    }

    private func setupNewShiftDetails(_ shift: OldShift, with job: Job) {
   
        // this actuallyt shouldnt be toggled yet, unless the shift literally hits overtime so later. leaving here so you rememeber 
       // shift.overtimeEnabled = job.overtimeEnabled
        if job.overtimeEnabled {
            shift.overtimeRate = job.overtimeRate
        }

        // Updating ViewModel's overtime settings for UI consistency
        self.applyOvertimeAfter = job.overtimeAppliedAfter
        self.overtimeRate = job.overtimeRate
        self.enableOvertime = job.overtimeEnabled
        
        self.currentShift = shift
        
    }

    private func updateViewModelForActiveShift(_ shift: OldShift) {
        
        if shift.shiftStartDate ?? Date() > Date() {
            shiftState = .countdown
            // Setup countdown
        } else {
            shiftState = .inProgress
            // Setup timer
        }
        
        print("shift state is in progress")
        self.hourlyPay = shift.hourlyPay
        self.applyOvertimeAfter = shift.job?.overtimeAppliedAfter ?? 0 // Assuming these properties exist
        self.overtimeRate = shift.overtimeRate
        self.enableOvertime = shift.overtimeEnabled
        self.currentShift = shift
        self.taxPercentage = shift.job?.tax ?? 0.0
        self.payMultiplier = shift.payMultiplier
        self.isMultiplierEnabled = shift.multiplierEnabled

    }
    
    func newEndShift(using viewContext: NSManagedObjectContext, endDate: Date, completion: @escaping (Result<OldShift, Error>) -> Void) {
        guard self.shiftState == .inProgress else {
            // Assuming cancelShift() is updated to handle new architecture and uses a completion handler if needed.
            cancelShift(using: viewContext) { result in
                            switch result {
                            case .success():
                                print("Successfully canceled and deleted all active shifts.")
                          
                            case .failure(let error):
                                print("Failed to cancel shifts: \(error.localizedDescription)")
                            
                            }
                        }
            print("we're cancelling!")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Shift is not in progress"])))
            return
        }

        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        do {
            let activeShifts = try viewContext.fetch(fetchRequest)
            guard let activeShift = activeShifts.first else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active shift to end."])))
                return
            }
            
         
            updateShiftDetails(activeShift, endDate: endDate, viewContext: viewContext) { result in
                switch result {
                case .success(let updatedShift):
                    self.clearShiftState()
                    completion(.success(updatedShift))
                case .failure(let error):
                    completion(.failure(error))
                    self.clearShiftState()
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    private func clearShiftState() {
        DispatchQueue.main.async {
      
            self.shiftState = .notStarted
            self.currentShift = nil
            self.shiftEnded = true
            self.breakTaken = false
            self.isOvertime = false
            self.overtimeDuration = 0
            self.timeElapsedUntilOvertime = 0
            self.isMultiplierEnabled = false
            self.payMultiplier = 1.0
            self.overtimeEnabled = false
            self.tempBreaks.removeAll()
         
            self.clearTempBreaksFromUserDefaults()
      
            self.showBadge = true
       
            self.isPresented = true
            self.cancelReminderNotification()
            
            self.stopTimer(timer: &self.timer, timeElapsed: &self.timeElapsed)

        }
    }
    
    private func updateShiftDetails(_ latestShift: OldShift, endDate: Date, viewContext: NSManagedObjectContext, completion: @escaping (Result<OldShift, Error>) -> Void) {
        
        let newTotalPay = computeTotalPay(for: endDate)
        let newTaxedPay = newTotalPay - (newTotalPay * Double(taxPercentage) / 100.0)
        
#if os(iOS)
        stopActivity(startDate: currentShift?.shiftStartDate ?? Date(), totalPay: newTotalPay, taxedPay: newTaxedPay, shiftDuration: endDate.timeIntervalSince(currentShift?.shiftStartDate ?? Date()), breakDuration: totalBreakDuration(), endDate: endDate)
#endif
        
        
        print("time elapsed until overtime was: \(timeElapsedUntilOvertime)")
        print("ending shift, overtime time elapsed is: \(timeElapsed - timeElapsedUntilOvertime)")
        
        
        let overtimeElapsed = timeElapsed - timeElapsedUntilOvertime
    
        
            self.lastPay = totalPay
            self.lastTaxedPay = taxedPay
            self.lastBreakElapsed = breakElapsed
            

            latestShift.hourlyPay = currentShift?.hourlyPay ?? 0.0
            latestShift.shiftStartDate = currentShift?.shiftStartDate
            latestShift.shiftEndDate = endDate
            latestShift.totalPay = newTotalPay
            latestShift.taxedPay = newTaxedPay
            latestShift.tax = Double(taxPercentage)
            latestShift.breakElapsed = breakElapsed
            latestShift.duration = endDate.timeIntervalSince(currentShift?.shiftStartDate ?? Date())
            latestShift.overtimeDuration = overtimeElapsed
            latestShift.timeBeforeOvertime = timeElapsedUntilOvertime
            latestShift.overtimeEnabled = enableOvertime
            latestShift.overtimeRate = overtimeRate
            latestShift.multiplierEnabled = isMultiplierEnabled
            latestShift.payMultiplier = payMultiplier
        // set shift to inactive
        latestShift.isActive = false
            
            latestShift.breakDuration = totalBreakDuration()
            
            latestShift.shiftID = UUID()
            
        // job is already set no need
          //  latestShift.job = job
            
            let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "tagID IN %@", selectedTags)
            let selectedTagEntities = try? viewContext.fetch(fetchRequest)
            
            latestShift.tags = NSSet(array: selectedTagEntities ?? [])
            
            // empty the selected tags
            selectedTags = Set<UUID>()
            removeSelectedTags()
            
            
            for tempBreak in tempBreaks {
                if let breakEndDate = tempBreak.endDate {
                    breaksManager.createBreak(oldShift: latestShift, startDate: tempBreak.startDate, endDate: breakEndDate, isUnpaid: tempBreak.isUnpaid, in: viewContext)
                }
            }
            
            //PersistenceController.shared.save()
            if latestShift.duration > 0 {
                do {
                        try viewContext.save()
                        completion(.success(latestShift))
                    } catch {
                        completion(.failure(error))
                    }
            }
            
            

        completion(.failure(NSError(domain: "", code: 2001, userInfo: [NSLocalizedDescriptionKey: "Error updating shift details"])))
        
    }
    
    func cancelShift(using viewContext: NSManagedObjectContext, completion: @escaping (Result<Void, Error>) -> Void) {
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        do {
            let activeShifts = try viewContext.fetch(fetchRequest)
            for activeShift in activeShifts {
                // delete any shifts marked active
                viewContext.delete(activeShift)
            }

            try viewContext.save()
            clearShiftState()

            completion(.success(()))
            print("All active shifts canceled successfully.")
        } catch {
            completion(.failure(error))
            print("Failed to cancel active shifts: \(error.localizedDescription)")
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
        
        newStartShift(using: viewContext, startDate: startDate, job: job)
        
        
       // startShift(using: viewContext, startDate: startDate, job: job)
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
            
            if breakReminder {
                
                scheduleReminderNotification(after: breakReminderTime, startDate: startDate, title: "Break Time!", body: "It's time for your break.")
            }
            
            if clockOutReminder {
                
                scheduleReminderNotification(after: clockOutReminderTime, startDate: startDate, title: "Time to clock out!", body: "Take a look at how much you earned today.")
            }
            
            
            
        }
        
        
#endif
    }
    
    func scheduleReminderNotification(after timeInterval: TimeInterval, startDate: Date, title: String, body: String) {
        
        
        let reminderDate = startDate.addingTimeInterval(timeInterval)
        let currentDateTime = Date()
        
        if reminderDate < currentDateTime {
            print("reminder time already passed")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(identifier: "ReminderNotification", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        
        
    }
    
    
    func cancelReminderNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["ReminderNotification"])
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
    
    func deleteCompletedScheduledShifts(viewContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isComplete == true")

        do {
            let completedShifts = try viewContext.fetch(fetchRequest)
            for shift in completedShifts {
                viewContext.delete(shift)
            }
            try viewContext.save()
        } catch {
  
            print("Error deleting completed scheduled shifts: \(error)")
        }
    }
    
    func uncompleteCancelledScheduledShift(viewContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isComplete == true")

        do {
            let completedShifts = try viewContext.fetch(fetchRequest)
            for shift in completedShifts {
                shift.isComplete = false
            }
            try viewContext.save()
        } catch {
           
            print("Error deleting completed scheduled shifts: \(error)")
        }
    }
    
}
