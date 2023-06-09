//
//  ShiftTrackerApp.swift
//  ShiftTracker
//
//  Created by James Poole on 18/03/23.
//

import SwiftUI
import CoreData
import WatchConnectivity
import PopupView

@main
struct ShiftTrackerApp: App {
    
    @State private var selectedTab: Tab = .home
    
    private let locationManager = LocationDataManager()
        private let defaults = UserDefaults.standard
    
    @StateObject private var watchConnectivityManager = WatchConnectivityManager.shared
    
    @StateObject var themeManager = ThemeDataManager()

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
            MainWithSideBarView(currentTab: $selectedTab)
                .implementPopupView()
                .preferredColorScheme(getPreferredColorScheme())
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
            // deep link tests
                .onOpenURL { url in
                    print("got a URL boss man")
                    print(url.path)
                    if url.scheme == "shifttrackerapp" && url.path == "/schedule" {
                        selectedTab = .schedule
                    }
                }
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
        locationManager.stopMonitoringAllRegions()
        
        let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
        do {
            let jobs = try persistenceController.container.viewContext.fetch(fetchRequest)
            for job in jobs {
                if let locations = job.locations as? Set<JobLocation>, !locations.isEmpty {
                    locationManager.startMonitoring(job: job)
                }
            }
        } catch {
            print("Error fetching jobs: \(error.localizedDescription)")
        }
    }


}


