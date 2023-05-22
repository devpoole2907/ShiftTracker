//
//  GlobalFunctions.swift
//  ShiftTracker
//
//  Created by James Poole on 30/04/23.
//

import Foundation
import UIKit
import CoreLocation
import SwiftUI
import PopupView
import MapKit
import CoreData
import Haptics
import UserNotifications

func isSubscriptionActive() -> Bool {
    
    let subscriptionStatus = UserDefaults.standard.bool(forKey: "subscriptionStatus")
    return subscriptionStatus
}

func setUserSubscribed(_ subscribed: Bool) {
    let userDefaults = UserDefaults.standard
    userDefaults.set(subscribed, forKey: "subscriptionStatus")
    if subscribed{
        print("set subscription to true ")
    }
    else {
        print("subscription is false")
    }
}

extension UIColor {
    var rgbComponents: (Float, Float, Float) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: nil)
        return (Float(r), Float(g), Float(b))
    }
}

extension CLPlacemark {
    var formattedAddress: String {
        let components = [subThoroughfare, thoroughfare, locality, administrativeArea, postalCode, country].compactMap { $0 }
        return components.joined(separator: ", ")
    }
}

struct OkButtonPopup: CentrePopup {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        VStack(spacing: 5) {
            
            createTitle()
                .padding(.vertical)
            //Spacer(minLength: 32)
            //  Spacer.height(32)
            createButtons()
            // .padding()
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background(colorScheme == .dark ? Color(.systemGray6) : .primary.opacity(0.04))
        .triggersHapticFeedbackWhenAppear()
    }
}

extension OkButtonPopup {
    
    func createTitle() -> some View {
        Text(title)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    func createButtons() -> some View {
        HStack(spacing: 4) {
            createConfirmButton()
        }
    }
}

extension OkButtonPopup {
    func createConfirmButton() -> some View {
        Button(action: dismiss) {
            Text("OK")
                .bold()
                .foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
    }
}

struct OkButtonPopupWithAction: CentrePopup {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let action: () -> Void
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        VStack(spacing: 5) {
            
            createTitle()
                .padding(.vertical)
            //Spacer(minLength: 32)
            //  Spacer.height(32)
            createButtons()
            // .padding()
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background(colorScheme == .dark ? Color(.systemGray6) : .primary.opacity(0.04))
        .triggersHapticFeedbackWhenAppear()
    }
}

extension OkButtonPopupWithAction {
    
    func createTitle() -> some View {
        Text(title)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    func createButtons() -> some View {
        HStack(spacing: 4) {
            createConfirmButton()
        }
    }
}

extension OkButtonPopupWithAction {
    func createConfirmButton() -> some View {
        Button(action: { dismiss()
            action()
        }) {
            Text("OK")
                .bold()
                .foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
    }
}

class AddressManager: ObservableObject {
    private let geocoder = CLGeocoder()
    private let defaults = UserDefaults.standard

    func loadSavedAddress(selectedAddressString: String?, completion: @escaping (MKCoordinateRegion?, IdentifiablePointAnnotation?) -> Void) {
        if let savedAddress = selectedAddressString {
            geocoder.geocodeAddressString(savedAddress) { placemarks, error in
                if let error = error {
                    print("Error geocoding address: \(error.localizedDescription)")
                } else if let placemarks = placemarks, let firstPlacemark = placemarks.first {
                    let annotation = IdentifiablePointAnnotation()
                    annotation.coordinate = firstPlacemark.location!.coordinate
                    annotation.title = firstPlacemark.formattedAddress
                    
                    if let coordinate = firstPlacemark.location?.coordinate {
                        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                        completion(region, annotation)
                    }
                }
            }
        }
    }
}

struct CustomConfirmationAlert: CentrePopup {
    
    @Environment(\.colorScheme) var colorScheme
    
    let action: () -> Void
    let title: String
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        

        
        VStack(spacing: 5) {
            
            createTitle()
                .padding(.vertical)
            createButtons()
        }

        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background(colorScheme == .dark ? Color(.systemGray6) : .primary.opacity(0.04))
        .triggersHapticFeedbackWhenAppear()
    }
}

private extension CustomConfirmationAlert {
    
    func createTitle() -> some View {
        Text(title)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    func createButtons() -> some View {
        HStack(spacing: 4) {
            createCancelButton()
            createUnlockButton()
        }
    }
}

private extension CustomConfirmationAlert {
    func createCancelButton() -> some View {
        Button(action: dismiss) {
            Text("Cancel")
            
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.primary.opacity(0.1))
                .cornerRadius(8)
        }
    }
    func createUnlockButton() -> some View {
        Button(action: {
            action()
            dismiss()
        }) {
            Text("Confirm")
                .bold()
                .foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
    }
}

struct CustomConfirmAlertWithCancelAction: CentrePopup {
    
    @Environment(\.colorScheme) var colorScheme
    
    let action: () -> Void
    let cancelAction: () -> Void
    let title: String
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        

        
        VStack(spacing: 5) {
            
            createTitle()
                .padding(.vertical)
            createButtons()
        }

        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background(colorScheme == .dark ? Color(.systemGray6) : .primary.opacity(0.04))
        .triggersHapticFeedbackWhenAppear()
    }
}

private extension CustomConfirmAlertWithCancelAction {
    
    func createTitle() -> some View {
        Text(title)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    func createButtons() -> some View {
        HStack(spacing: 4) {
            createCancelButton()
            createUnlockButton()
        }
    }
}

private extension CustomConfirmAlertWithCancelAction {
    func createCancelButton() -> some View {
        Button(action: {
            cancelAction()
            dismiss()
        }) {
            Text("Cancel")
            
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.primary.opacity(0.1))
                .cornerRadius(8)
        }
    }
    func createUnlockButton() -> some View {
        Button(action: {
            action()
            dismiss()
        }) {
            Text("Confirm")
                .bold()
                .foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
    }
}

class JobSelectionViewModel: ObservableObject {
    @Published var selectedJobUUID: UUID?
    @Published var selectedJobOffset: CGFloat = 0.0
    @AppStorage("selectedJobUUID") private var storedSelectedJobUUID: String = ""
    
    
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

    
    func selectJob(_ job: Job, with jobs: FetchedResults<Job>, shiftViewModel: ContentViewModel) {
        if shiftViewModel.shift == nil {
            if let jobUUID = job.uuid {
                let currentIndex = jobs.firstIndex(where: { $0.uuid == jobUUID }) ?? 0
                let selectedIndex = jobs.firstIndex(where: { $0.uuid == selectedJobUUID }) ?? 0
                withAnimation(.spring()) {
                    selectedJobOffset = CGFloat(selectedIndex - currentIndex) * 60
                }
                selectedJobUUID = jobUUID
                shiftViewModel.selectedJobUUID = jobUUID
                shiftViewModel.hourlyPay = job.hourlyPay
                shiftViewModel.saveHourlyPay()
                shiftViewModel.taxPercentage = job.tax
                shiftViewModel.saveTaxPercentage()
                storedSelectedJobUUID = jobUUID.uuidString
            }
        } else {
            OkButtonPopup(title: "End your current shift to select another job.").present()
        }
    }
    
    
    
    
}


enum ActionType {
    case startBreak, endShift, endBreak, startShift
}

// this is stupid and needs to be removed but itll do for now
// gets the equivalent primary color opacity without the opacity

func opaqueVersion(of color: Color, withOpacity opacity: Double, in colorScheme: ColorScheme) -> Color {
    // Convert the SwiftUI color to a UIKit color
    let uiColor = UIColor(color)

    // Get the RGBA components of the color
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    // Calculate the equivalent opaque color based on the color scheme
    let background: CGFloat = colorScheme == .dark ? 0 : 1
    let newRed = red * CGFloat(opacity) + (1 - CGFloat(opacity)) * background
    let newGreen = green * CGFloat(opacity) + (1 - CGFloat(opacity)) * background
    let newBlue = blue * CGFloat(opacity) + (1 - CGFloat(opacity)) * background

    // Convert the new color back to a SwiftUI color
    return Color(UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1))
}

// scheduled shifts notification manager

class ShiftNotificationManager {
    static let shared = ShiftNotificationManager()
    
    private var shiftNotificationIdentifiers: [String] = []
    
    func fetchUpcomingShifts() -> [ScheduledShift] {
        let fetchRequest: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "notifyMe == true")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledShift.reminderTime, ascending: true)]
        fetchRequest.fetchLimit = 20
        
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
               let startDate = shift.startDate, let jobName = shift.job?.name {
                content.title = "\(jobName) Shift Reminder"
                content.body = "Your scheduled shift starts at \(startDate)"
                
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
    
}

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
    
}

extension NSNotification.Name {
    static let didEnterRegion = NSNotification.Name("didEnterRegionNotification")
    static let didExitRegion = NSNotification.Name("didExitRegionNotification")
}

struct AnimatedButton: View {
    @Binding var isTapped: Bool
    @Binding var activeSheet: ActiveSheet?
    
    @Environment(\.colorScheme) var colorScheme
    
    var activeSheetCase: ActiveSheet
    var title: String
    var backgroundColor: Color
    var isDisabled: Bool

    var body: some View {
        
        let foregroundColor: Color = colorScheme == .dark ? .black : .white
        
        Button(action: {
            self.activeSheet = activeSheetCase
            withAnimation {
                self.isTapped = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isTapped = false
                }
            }
        }) {
            Text(title)
                .frame(minWidth: UIScreen.main.bounds.width / 3)
                .bold()
                .padding()
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(18)
        }
        .buttonStyle(.borderless)
        .disabled(isDisabled)
        .frame(maxWidth: .infinity)
        .scaleEffect(isTapped ? 1.1 : 1)
        .animation(.easeInOut(duration: 0.3))
    }
}

struct Shake: AnimatableModifier {
    var times: CGFloat = 0
    var amplitude: CGFloat = 5
    
    var animatableData: CGFloat {
        get { times }
        set { times = newValue }
    }
    
    func body(content: Content) -> some View {
        content.offset(x: sin(times * .pi * 2) * amplitude)
    }
}

extension View {
    func shake(times: CGFloat) -> some View {
        self.modifier(Shake(times: times))
    }
}

func getDayOfWeek(date: Date) -> Int {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.weekday], from: date)
    return components.weekday ?? 0
}

func getDayShortName(day: Int) -> String {
    let formatter = DateFormatter()
    let symbols = formatter.shortWeekdaySymbols
    let symbol = symbols?[day % 7] ?? ""
    return String(symbol.prefix(2))
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

// for calculating a week ahead

func nextDate(dayOfWeek: Int, time: Date) -> Date? {
    let calendar = Calendar.current
    let now = Date()

    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
    var dateComponents = DateComponents()
    dateComponents.weekday = dayOfWeek
    dateComponents.hour = timeComponents.hour
    dateComponents.minute = timeComponents.minute

    let nextDate = calendar.nextDate(after: now, matching: dateComponents, matchingPolicy: .nextTime)

    return nextDate
}

func updateRosterNotifications(viewContext: NSManagedObjectContext) {
    let center = UNUserNotificationCenter.current()

    // Cancel all existing notifications
    center.removePendingNotificationRequests(withIdentifiers: ["roster"])

    let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "rosterReminder == true")

    do {
        let jobs = try viewContext.fetch(fetchRequest)

        // Loop through the jobs and reschedule
        for job in jobs {
            if let time = job.rosterTime,
               let nextDate = nextDate(dayOfWeek: Int(job.rosterDayOfWeek), time: time) {
                
                // Schedule the notification
                
                let content = UNMutableNotificationContent()
                content.title = "Time to check your roster"
                content.body = "Open the app to schedule your shifts for \(job.name ?? "")"

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

public func wipeCoreData(in viewContext: NSManagedObjectContext) {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntityName")
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    
    let entityNames = ["Job", "OldShift", "Break", "JobLocation", "ScheduledShift", "Tip"]

    for entityName in entityNames {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try viewContext.execute(deleteRequest)
        } catch let error as NSError {
            // Handle the error
            print("Could not delete \(entityName). \(error), \(error.userInfo)")
        }
    }
}


