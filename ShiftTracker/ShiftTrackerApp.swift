//
//  ShiftTrackerApp.swift
//  ShiftTracker
//
//  Created by James Poole on 18/03/23.
//

import SwiftUI
import CoreData
import WatchConnectivity

@main
struct ShiftTrackerApp: App {
    
    private let locationManager = LocationDataManager()
        private let defaults = UserDefaults.standard
    
    @StateObject private var watchConnectivityManager = WatchConnectivityManager.shared

    
    @AppStorage("colorScheme") var userColorScheme: String = "system"
    
    init() {
            WatchConnectivityManager.shared.onDeleteJob = { jobId in
                let context = PersistenceController.shared.container.viewContext
                WatchConnectivityManager.shared.deleteJob(with: jobId, in: context)
            }
        }
    
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(getPreferredColorScheme())
                //.preferredColorScheme(.dark)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    startMonitoringAllJobLocations()
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
    
    private func startMonitoringAllJobLocations() {
        let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
        do {
            let jobs = try persistenceController.container.viewContext.fetch(fetchRequest)
            for job in jobs {
                if let _ = job.address {
                    locationManager.startMonitoring(job: job)
                }
            }
        } catch {
            print("Error fetching jobs: \(error.localizedDescription)")
        }
    }

}


