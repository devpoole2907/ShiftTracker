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


extension TimeInterval {
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let hours = (time / 3600)
        let minutes = (time / 60) % 60
        let seconds = time % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
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

func isBeforeEndOfToday(_ date: Date) -> Bool {
    let calendar = Calendar.current
    let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    
    if let date = calendar.date(from: dateComponents), let today = calendar.date(from: todayComponents) {
        return date <= today
    }
        return false
    
}


extension CLPlacemark {
    var formattedAddress: String {
        let components = [subThoroughfare, thoroughfare, locality, administrativeArea, postalCode, country].compactMap { $0 }
        return components.joined(separator: ", ")
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


extension NSNotification.Name {
    static let didEnterRegion = NSNotification.Name("didEnterRegionNotification")
    static let didExitRegion = NSNotification.Name("didExitRegionNotification")
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
    return String(symbol.prefix(1))
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

// for rolling digit timer on TimerView

public func digitsFromTimeString(timeString: String) -> [Int] {
    return timeString.flatMap { char in
        if let digit = Int(String(char)) {
            return [abs(digit)]
        } else {
            return []
        }
    }
}

struct FadeMask: View {
    var body: some View {
        LinearGradient(gradient: Gradient(stops: [
            Gradient.Stop(color: Color.clear, location: 0),
            Gradient.Stop(color: Color.black, location: 0.1), 
            Gradient.Stop(color: Color.black, location: 0.9),
            Gradient.Stop(color: Color.clear, location: 1),
        ]), startPoint: .top, endPoint: .bottom)
    }
}

struct RollingDigit: View {
    let digit: Int
    @State private var shouldAnimate = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach((0...10), id: \.self) { index in
                    Text(index == 10 ? "0" : "\(index)")
                        .font(.system(size: geometry.size.height).monospacedDigit())
                        .bold()
                        .fontDesign(.rounded)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .offset(y: -CGFloat(digit) * geometry.size.height)
            .animation(shouldAnimate ? .easeOut(duration: 0.2) : nil)
            .onAppear {
                shouldAnimate = true
            }
            .onDisappear {
                shouldAnimate = false
            }
        }
    }
}

class NavigationState: ObservableObject {
    static let shared = NavigationState()
    
    @Published var gestureEnabled: Bool = true
    @Published var showMenu: Bool = false
    
    @Published var currentTab: Tab = .home
    
}


// test modifier to capture view height from Matthew's dev blog daringsnowball.net

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        guard let nextValue = nextValue() else { return }
        value = nextValue
    }
}

private struct ReadHeightModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
        }
    }

    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}

extension View {
    func readHeight() -> some View {
        self
            .modifier(ReadHeightModifier())
    }
}

extension UIImage {
    func resized(to newSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            let hScale = newSize.height / size.height
            let vScale = newSize.width / size.width
            let scale = max(hScale, vScale) // scaleToFill
            let resizeSize = CGSize(width: size.width*scale, height: size.height*scale)
            var middle = CGPoint.zero
            if resizeSize.width > newSize.width {
                middle.x -= (resizeSize.width-newSize.width)/2.0
            }
            if resizeSize.height > newSize.height {
                middle.y -= (resizeSize.height-newSize.height)/2.0
            }
            
            draw(in: CGRect(origin: middle, size: resizeSize))
        }
    }
}

// because the focus state just straight up isnt working on JobView, lets use UIKit code - from hackingwithswift

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// used to create 3 default tags when the app launches

func createTags(in viewContext: NSManagedObjectContext) {
        let tagNames = ["Night", "Overtime", "Late"]
        let tagColors = [UIColor(.indigo), UIColor(.orange), UIColor(.pink)]

    for index in tagNames.indices {
        
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", tagNames[index])
        
        do {
            let existingTags = try viewContext.fetch(fetchRequest)
            
            if existingTags.isEmpty {
                let tag = Tag(context: viewContext)
                tag.name = tagNames[index]
                
                let (r, g, b) = tagColors[index].rgbComponents
                tag.colorRed = Double(r)
                tag.colorGreen = Double(g)
                tag.colorBlue = Double(b)
                tag.tagID = UUID()
                tag.editable = false
                
                try viewContext.save()
            }
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    }
class NotificationManager: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus?
    
    init() {
        checkNotificationStatus()
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    
}


extension View {
    @ViewBuilder
    func customSectionSpacing(with spacing: CGFloat) -> some View {
        if #available(iOS 17, *) {
            self
                .modifier(SectionSpacingModifier(spacing: spacing))
        }
        else {
            self
        }
    }
}

@available(iOS 17, *)
struct SectionSpacingModifier: ViewModifier {
    var spacing: CGFloat
    
    func body(content: Content) -> some View {
        content
        .listSectionSpacing(spacing)
    }
    
    
    
}
