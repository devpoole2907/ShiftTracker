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
        private let defaults = UserDefaults.standard
    
    @StateObject private var watchConnectivityManager = WatchConnectivityManager.shared
    
    @StateObject private var purchaseManager = PurchaseManager()
    //@StateObject var locationManager = LocationDataManager()
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
                .environmentObject(LocationDataManager.shared)
                .environmentObject(purchaseManager)
            
                .task{
                    
                    await purchaseManager.updatePurchasedProducts()
                    
                }
            
            // deep link tests
                .onOpenURL { url in
                    print("got a URL boss man")
                    print(url.path)
                    if url.scheme == "shifttrackerapp" && url.path == "/schedule" {
                        selectedTab = .schedule
                    }
                }
                .onAppear {
              //      locationManager.startMonitoringAllLocations()
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
    



}


