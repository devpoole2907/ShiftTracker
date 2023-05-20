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
        
        
        if let locationSet = job.locations, let jobLocation = locationSet.allObjects.first as? JobLocation {
            if let savedAddress = jobLocation.address {
                print("got an address to monitor, \(savedAddress)")
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(savedAddress) { placemarks, error in
                if let error = error {
                    print("Error geocoding address: \(error.localizedDescription)")
                } else if let placemarks = placemarks, let firstPlacemark = placemarks.first, let location = firstPlacemark.location {
                    let region = CLCircularRegion(center: location.coordinate, radius: jobLocation.radius, identifier: job.objectID.uriRepresentation().absoluteString)
                    region.notifyOnEntry = !clockOut
                    region.notifyOnExit = clockOut
                    
                    self.locationManager.startMonitoring(for: region)
                }
            }
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
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited the region")
        guard let jobURI = URL(string: region.identifier),
              let jobID = PersistenceController.shared.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: jobURI) else {
            return
        }

        let context = PersistenceController.shared.container.viewContext
        if let job = try? context.existingObject(with: jobID) as? Job {
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
