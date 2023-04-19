//
//  ShiftTrackerApp.swift
//  ShiftTracker
//
//  Created by James Poole on 18/03/23.
//

import SwiftUI
import CoreData


@main
struct ShiftTrackerApp: App {
    
    private let locationManager = LocationDataManager()
        private let defaults = UserDefaults.standard
    
    @AppStorage("colorScheme") var userColorScheme: String = "system"
    
    @StateObject var myEvents = EventStore(preview: true)
    
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(getPreferredColorScheme())
                //.preferredColorScheme(.dark)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(myEvents)
                .onAppear {
                                    startMonitoringSavedAddress()
                                }
        }
        
    }
    
    func getPreferredColorScheme() -> ColorScheme? {
            switch userColorScheme {
                case "light":
                    return .light
                case "dark":
                    return .dark
                default:
                    return nil
            }
        }
    
    private func startMonitoringSavedAddress() {
            if let savedAddress = defaults.string(forKey: "selectedAddress") {
                locationManager.startMonitoring(savedAddress: savedAddress)
            }
        }
}


