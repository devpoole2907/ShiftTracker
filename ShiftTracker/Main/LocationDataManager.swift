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

class LocationDataManager : NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var location: CLLocation?
        @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.33233141, longitude: -122.0312186), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    
    
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
                //
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
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        let locationReminders = UserDefaults.standard.bool(forKey: "clockInReminder") // only send notification to them
            // if they have location reminders on
        
        let autoClockingIn = UserDefaults.standard.bool(forKey: "autoClockIn")

        
        
        if autoClockingIn {
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
             

            }
        
        else if locationReminders {
                let content = UNMutableNotificationContent()
                content.title = "You're near your workplace"
                content.body = "Ready to track your shift? Let's make some bank."
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
             

            }
    }
    
    public func startMonitoring(savedAddress: String) {
        print("MONITORING LOCATION")
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(savedAddress) { placemarks, error in
            if let error = error {
                print("Error geocoding address: \(error.localizedDescription)")
            } else if let placemarks = placemarks, let firstPlacemark = placemarks.first, let location = firstPlacemark.location {
                let region = CLCircularRegion(center: location.coordinate, radius: 75, identifier: "SavedLocation")
                region.notifyOnEntry = true
                region.notifyOnExit = true

                self.locationManager.startMonitoring(for: region)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // Perform an action when the user exits the region
        print("Exited the region")
        let clockOutReminder = UserDefaults.standard.bool(forKey: "clockOutReminder")
        let autoClockOut = UserDefaults.standard.bool(forKey: "autoClockOut")
        if autoClockOut{
                let content = UNMutableNotificationContent()
                content.title = "ShiftTracker Pro"
                content.body = "Clocking you out... Look at how much you made today!"
                content.sound = .default
                print("Region exited, sending notification") // debugging
                
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
            
            NotificationCenter.default.post(name: .didExitRegion, object: nil)
             

            }
        else if clockOutReminder {
                let content = UNMutableNotificationContent()
                content.title = "Looks like you're leaving..."
                content.body = "Don't forget to clock out - open ShiftTracker and see how much you made today!"
                content.sound = .default
                print("Region exited, sending notification") // debugging
                
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
            
            NotificationCenter.default.post(name: .didExitRegion, object: nil)
             

            }
        
        
        
        
    }



    
    
}
