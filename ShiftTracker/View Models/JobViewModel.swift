//
//  JobViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 7/10/23.
//

import Foundation
import SwiftUI
import CoreData

class JobViewModel: ObservableObject {
    
    let jobIcons = [
        "briefcase.fill", "display", "tshirt.fill", "takeoutbag.and.cup.and.straw.fill", "trash.fill",
        "wineglass.fill", "cup.and.saucer.fill", "film.fill", "building.columns.fill", "camera.fill", "camera.macro", "bus.fill", "box.truck.fill", "fuelpump.fill", "popcorn.fill", "cross.case.fill", "frying.pan.fill", "cart.fill", "paintbrush.fill", "wrench.adjustable.fill",
                "car.fill", "ferry.fill", "bolt.fill", "books.vertical.fill",
                    "newspaper.fill", "theatermasks.fill", "lightbulb.led.fill", "spigot.fill"]

    let jobColors = [
        Color.pink, Color.green, Color.blue, Color.purple, Color.orange, Color.cyan]
    
    let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var job: Job?
    
    @Published var miniMapAnnotation: IdentifiablePointAnnotation?
    @Published var name = ""
    @Published var title = ""
    @Published var hourlyPay: String = ""
    @Published var taxPercentage: Double = 0
    @Published var selectedColor = Color.pink
    @Published var clockInReminder = false
    @Published var autoClockIn = false
    @Published var clockOutReminder = false
    @Published var autoClockOut = false
    
    @Published var payShakeTimes: CGFloat = 0
    @Published var nameShakeTimes: CGFloat = 0
    @Published var titleShakeTimes: CGFloat = 0
    @Published var overtimeShakeTimes: CGFloat = 0
    
    @Published var showOvertimeTimeView = false
    @Published var overtimeRate = 1.25
    @Published var overtimeAppliedAfter: TimeInterval = 8.0
    @Published var overtimeEnabled = false
    
    @Published var selectedIcon: String
    
    @Published var rosterReminder: Bool
    @Published var selectedDay: Int = 1
    @Published var selectedTime: Date
    
    @Published var breakReminder: Bool = false
    @Published var breakRemindAfter: TimeInterval
    
    @Published var selectedRadius: Double = 75
    
    @Published var activeSheet: JobViewActiveSheet?
    
    @Published var editToggle: Bool = false
    
    @Published var showProSheet = false
    
    @Published var hasAppeared = false // used to animate the background fading out when appearing as a fullscreencover due to a system glitch with black/white backgrounds no transparency
    
    @Published var selectedAddress: String?
    
    @Published var buttonBounce: Bool = false
    
    init(job: Job? = nil) {
        
        self.job = job
        
        self.name = job?.name ?? ""
        self.title = job?.title ?? ""
        self.hourlyPay = "\(job?.hourlyPay ?? 0)"
        self.taxPercentage = job?.tax ?? 0
        self.selectedIcon = job?.icon ?? "briefcase.fill"
        
        if let jobColorRed = job?.colorRed, let jobColorBlue = job?.colorBlue, let jobColorGreen = job?.colorGreen {
            self.selectedColor = Color(red: Double(jobColorRed), green: Double(jobColorGreen), blue: Double(jobColorBlue))
        }
        
        // gets the first saved address, with the new address data model system for future multiple location implementation
        
        if let locationSet = job?.locations, let location = locationSet.allObjects.first as? JobLocation {
            self.selectedAddress = location.address
            self.selectedRadius = location.radius
            print("job has an address: \(location.address)")
        } else {
            print("job has no address")
            
        }
        
        self.breakReminder = job?.breakReminder ?? false
        self.breakRemindAfter = job?.breakReminderTime ?? 0
        self.clockInReminder = job?.clockInReminder ?? false
        self.clockOutReminder = job?.clockOutReminder ?? false
        self.autoClockIn = job?.autoClockIn ?? false
        self.autoClockOut = job?.autoClockOut ?? false
        self.overtimeEnabled = job?.overtimeEnabled ?? false
        self.overtimeRate = job?.overtimeRate ?? 1.25
        self.overtimeAppliedAfter = job?.overtimeAppliedAfter ?? 8.0
        
        self.rosterReminder = job?.rosterReminder ?? false
        self.selectedDay = Int(job?.rosterDayOfWeek ?? 1)
        self.selectedTime = job?.rosterTime ?? Date()
        
        
        
    }
    
    func saveJob(in viewContext: NSManagedObjectContext, locationManager: LocationDataManager, selectedJobManager: JobSelectionManager, jobViewModel: JobViewModel, contentViewModel: ContentViewModel) {
        
        
        let notificationManager = ShiftNotificationManager.shared
        
        var newJob: Job

        if let job = job {
            print("yeah job exists")
            newJob = job
            
        } else {
            newJob = Job(context: viewContext)
            newJob.uuid = UUID()
        }

        
        newJob.name = name
        newJob.title = title
        newJob.hourlyPay = Double(hourlyPay) ?? 0.0
        newJob.clockInReminder = clockInReminder
        newJob.clockOutReminder = clockOutReminder
        newJob.tax = taxPercentage
        newJob.autoClockIn = autoClockIn
        newJob.autoClockOut = autoClockOut
        newJob.overtimeEnabled = overtimeEnabled
        newJob.overtimeAppliedAfter = overtimeAppliedAfter
        newJob.overtimeRate = overtimeRate
        newJob.icon = selectedIcon
        newJob.rosterReminder = rosterReminder
        newJob.rosterTime = selectedTime
        newJob.rosterDayOfWeek = Int16(selectedDay)
        newJob.breakReminder = breakReminder
        newJob.breakReminderTime = breakRemindAfter
        
        // replace this code with adding locations later when multiple address system update releases
        if let locationSet = newJob.locations, let location = locationSet.allObjects.first as? JobLocation {
            location.address = selectedAddress
        } else { // for multi jobs we need this to add more
            let location = JobLocation(context: viewContext)
            location.address = selectedAddress
            location.radius = selectedRadius
            newJob.addToLocations(location)
        }

        

        
        
        let uiColor = UIColor(selectedColor)
        let (r, g, b) = uiColor.rgbComponents
        newJob.colorRed = r
        newJob.colorGreen = g
        newJob.colorBlue = b
        
        do {
            try viewContext.save()
            
            self.job = newJob
            
            locationManager.startMonitoringAllLocations()
            
            notificationManager.updateRosterNotifications(viewContext: viewContext)
            
            
            
            // checks if content views selected job is this job
            
            if let jobUUID = jobViewModel.job?.uuid {
                if jobUUID == contentViewModel.selectedJobUUID {
                    contentViewModel.hourlyPay = jobViewModel.job!.hourlyPay
                    contentViewModel.saveHourlyPay()
                    contentViewModel.taxPercentage = jobViewModel.job!.tax
                    contentViewModel.saveTaxPercentage()
                }
                
                
                
                
                // checks if this is the overall selected job
                if jobUUID == selectedJobManager.selectedJobUUID {
                    print("its the selected job yes")
                    
                    //   selectedJobManager.deselectJob(shiftViewModel: viewModel) DOES IT NEED TO BE DESELECTED?
                    
                    selectedJobManager.updateJob(jobViewModel.job!)
                    
                    
                    
                }
            }
 
        } catch {
            print("Failed to save job: \(error.localizedDescription)")
        }
        
     
        
        
    }
    
     func deleteJob(in viewContext: NSManagedObjectContext, selectedJobManager: JobSelectionManager, completion: () -> Void) {
        
        if job!.uuid == selectedJobManager.selectedJobUUID {
            
            selectedJobManager.deselectJob(shiftViewModel: ContentViewModel.shared)
            
        }
        
        viewContext.delete(job!)
        do {
            try viewContext.save()
            
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
}
