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
    
    private let notificationManager = ShiftNotificationManager.shared
    
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
    
    func requestAlways() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            authorizationStatus = .authorizedAlways
            break
            
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
    
    
    public func startMonitoringAllLocations() {
        stopMonitoringAllRegions()

        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<JobLocation> = JobLocation.fetchRequest()

        do {
            let locations = try context.fetch(fetchRequest)
            locations.forEach { startMonitoring(location: $0) }
            print("monitoring \(locations.count) locations")
        } catch let error {
            print("Could not fetch locations: \(error.localizedDescription)")
        }
    }

    
    
    public func startMonitoring(location: JobLocation) {
        print("Starting to monitor for location with ID: \(location.objectID.uriRepresentation().absoluteString)")
        
        if let savedAddress = location.address {
            print("got an address to monitor, \(savedAddress)")
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(savedAddress) { placemarks, error in
                if let error = error {
                    print("Error geocoding address: \(error.localizedDescription)")
                } else if let placemarks = placemarks, let firstPlacemark = placemarks.first, let locationCoordinate = firstPlacemark.location {
                    let region = CLCircularRegion(center: locationCoordinate.coordinate, radius: location.radius, identifier: location.objectID.uriRepresentation().absoluteString)
                    region.notifyOnEntry = true
                    region.notifyOnExit = true
                    
                    self.locationManager.startMonitoring(for: region)
                }
            }
        }
    }



    
    
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered the region")

        guard let locationURI = URL(string: region.identifier),
              let locationID = PersistenceController.shared.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: locationURI) else {
            return
        }

        let context = PersistenceController.shared.container.viewContext
        if let location = try? context.existingObject(with: locationID) as? JobLocation {
            if let job = location.job {
                if job.autoClockIn {
                    print("Region entered, sending notification") // debugging
                    
                    if let jobName = job.name {
                        notificationManager.sendLocationNotification(with: "ShiftTracker Pro", body: "You're near \(jobName) - clocking you in... Enjoy your shift!")
                    }
                    
                    NotificationCenter.default.post(name: .didEnterRegion, object: nil, userInfo: ["jobID": job.uuid!])
                } else if job.clockInReminder {
                    // Handle clock-in reminder for the job
                    print("Region entered, sending notification") // debugging
                    if let jobName = job.name {
                        notificationManager.sendLocationNotification(with: "You're near \(jobName)", body: "Ready to track your shift? Let's make some bank.")
                    }
                
                    NotificationCenter.default.post(name: .didEnterRegion, object: nil)
                }
            }
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited the region")

        guard let locationURI = URL(string: region.identifier),
              let locationID = PersistenceController.shared.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: locationURI) else {
            return
        }

        let context = PersistenceController.shared.container.viewContext
        if let location = try? context.existingObject(with: locationID) as? JobLocation {
            if let job = location.job {
                if job.autoClockOut {
                    print("Region exited, sending notification") // debugging
                    
                    if let jobName = job.name {
                        notificationManager.sendLocationNotification(with: "ShiftTracker Pro", body: "Looks like you're leaving \(jobName) - clocking you out. Open ShiftTracker and see how much you made!")
                    }

                    NotificationCenter.default.post(name: .didExitRegion, object: nil)
                } else if job.clockOutReminder {
                    if let jobName = job.name {
                        notificationManager.sendLocationNotification(with: "Looks like you're leaving \(jobName)...", body: "Don't forget to clock out - open ShiftTracker and see how much you made today!")
                    }

                    print("Region exited, sending notification") // debugging

                    NotificationCenter.default.post(name: .didExitRegion, object: nil)
                }
            }
        }
    }


    func stopMonitoringAllRegions() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }


    
    
}
