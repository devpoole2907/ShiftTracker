//
//  LocationDataManager.swift
//  ShiftTracker
//
//  Created by James Poole on 21/03/23.
//

import Foundation
import CoreLocation
import MapKit
import UserNotifications
import CoreData

class LocationDataManager : NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var location: CLLocation?
        @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.33233141, longitude: -122.0312186), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.allowsBackgroundLocationUpdates = true
            //print("requested when in use")
                locationManager.startUpdatingLocation()
    }
    
    func requestLocation() {
            locationManager.requestLocation()
        }
    
    
    func requestWhenInUse() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:  // Location services are available.
            // Insert code here of what should happen when Location services are authorized
            authorizationStatus = .authorizedWhenInUse
            //locationManager.requestLocation()
            break
            
        case .restricted:  // Location services currently unavailable.
            // Insert code here of what should happen when Location services are NOT authorized
            authorizationStatus = .restricted
            break
            
        case .denied:  // Location services currently unavailable.
            // Insert code here of what should happen when Location services are NOT authorized
            authorizationStatus = .denied
            break
            
        case .notDetermined:        // Authorization not determined yet.
            authorizationStatus = .notDetermined
            //manager.requestAlwaysAuthorization()
            break
            
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
                self.location = location
                region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //print("error: \(error.localizedDescription)")
    }
    
    public func startMonitoring(job: Job, clockOut: Bool = false) {
        guard let savedAddress = job.address else { return }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(savedAddress) { placemarks, error in
            if let error = error {
                print("Error geocoding address: \(error.localizedDescription)")
            } else if let placemarks = placemarks, let firstPlacemark = placemarks.first, let location = firstPlacemark.location {
                let region = CLCircularRegion(center: location.coordinate, radius: 75, identifier: job.objectID.uriRepresentation().absoluteString)
                region.notifyOnEntry = !clockOut
                region.notifyOnExit = clockOut

                self.locationManager.startMonitoring(for: region)
            }
        }
    }

    
    
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // ...

        guard let jobURI = URL(string: region.identifier),
              let jobID = PersistenceController.shared.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: jobURI) else {
            return
        }

        let context = PersistenceController.shared.container.viewContext
        if let job = try? context.existingObject(with: jobID) as? Job {
            if job.autoClockIn {
                
                // THIS NEEDS TO BE ADJUSTED, IN CONTENTVIEW WHEN IT RECIEVES THE NOTIFICATION IT MUST START THE CORRESPONDING JOB
                
                let content = UNMutableNotificationContent()
                content.title = "ShiftTracker Pro"
                content.body = "Clocking you in... Enjoy your shift!"
                content.sound = .default
                print("Region entered, sending notification") // debugging
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: "LocationNotification", content: content, trigger: trigger)
                
                // let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
                // let request = UNNotificationRequest(identifier: "LocationNotification", content: content, trigger: trigger)

                let center = UNUserNotificationCenter.current()
                center.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            
                    NotificationCenter.default.post(name: .didEnterRegion, object: nil)
                
                
                
                
            } else if job.clockInReminder {
                // Handle clock-in reminder for the job
                
                let content = UNMutableNotificationContent()
                content.title = "You're near your workplace"
                content.body = "Ready to track your shift? Let's make some bank."
                content.sound = .default
                print("Region entered, sending notification") // debugging
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: "LocationNotification", content: content, trigger: trigger)

                let center = UNUserNotificationCenter.current()
                center.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            
                    NotificationCenter.default.post(name: .didEnterRegion, object: nil)
                
                
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited the region")
        guard let jobURI = URL(string: region.identifier),
              let jobID = PersistenceController.shared.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: jobURI) else {
            return
        }

        let context = PersistenceController.shared.container.viewContext
        if let job = try? context.existingObject(with: jobID) as? Job {
            if job.autoClockOut {
                
                // THIS NEEDS TO BE MODIFIED SAME AS didEnterRegion ABOVE
                
                let content = UNMutableNotificationContent()
                content.title = "ShiftTracker Pro"
                content.body = "Clocking you out... Look at how much you made today!"
                content.sound = .default
                print("Region exited, sending notification") // debugging
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: "LocationNotification", content: content, trigger: trigger)


                let center = UNUserNotificationCenter.current()
                center.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            
            NotificationCenter.default.post(name: .didExitRegion, object: nil)
            } else if job.clockOutReminder {
                let content = UNMutableNotificationContent()
                content.title = "Looks like you're leaving..."
                content.body = "Don't forget to clock out - open ShiftTracker and see how much you made today!"
                content.sound = .default
                print("Region exited, sending notification") // debugging
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: "LocationNotification", content: content, trigger: trigger)
                

                let center = UNUserNotificationCenter.current()
                center.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            
            NotificationCenter.default.post(name: .didExitRegion, object: nil)
            }
        }
    }



    public func startMonitoringJobs() {
        let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "clockInReminder == %@", NSNumber(value: true))

        let context = PersistenceController.shared.container.viewContext
        do {
            let jobsWithReminder = try context.fetch(fetchRequest)
            for job in jobsWithReminder {
                startMonitoring(job: job)
            }
        } catch {
            print("Error fetching jobs with clockInReminder: \(error.localizedDescription)")
        }
    }
    
    public func startMonitoringClockOutJobs() {
        let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "clockOutReminder == %@", NSNumber(value: true))

        let context = PersistenceController.shared.container.viewContext
        do {
            let jobsWithClockOutReminder = try context.fetch(fetchRequest)
            for job in jobsWithClockOutReminder {
                startMonitoring(job: job, clockOut: true)
            }
        } catch {
            print("Error fetching jobs with clockOutReminder: \(error.localizedDescription)")
        }
    }



    
    
}
