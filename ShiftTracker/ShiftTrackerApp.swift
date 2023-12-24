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
import TipKit

@main
struct ShiftTrackerApp: App {
    
    //@State private var selectedTab: Tab = .home
        private let defaults = UserDefaults.standard
    
    @StateObject private var purchaseManager = PurchaseManager()
   // @StateObject var navigationState = NavigationState()
    //@StateObject var locationManager = LocationDataManager()
    @StateObject var themeManager = ThemeDataManager()
    
    @StateObject var navigationState = NavigationState.shared

    @AppStorage("colorScheme") var userColorScheme: String = "system"
    

    
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            //MainWithSideBarView(currentTab: $selectedTab)
            MainWithSideBarView()
                .implementPopupView()
                .preferredColorScheme(getPreferredColorScheme())
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
                .environmentObject(LocationDataManager.shared)
                .environmentObject(purchaseManager)
                .environmentObject(navigationState)
                .environmentObject(ShiftStore.shared)
            
            
                .task{
                    
                    await purchaseManager.updatePurchasedProducts()
                    
            if #available(iOS 17.0, *){
                    try? Tips.resetDatastore()
                    
           
                        try? Tips.configure([
                            .displayFrequency(.immediate),
                            .datastoreLocation(.applicationDefault)
                            
                            
                            
                        ])
                    }
                                        
                    
                }
            
            // deep link tests
                .onOpenURL { url in
                    print("got a URL boss man")
                    print("url is: \(url)")
                    print("url path is: \(url.path)")
                    print("url scheme is: \(url.scheme)")
                    if url.scheme == "shifttrackerapp"  {
                        
                        if url.host == "schedule" {
                            navigationState.currentTab = .schedule
                        }
                        if url.host == "summary" {
                            navigationState.currentTab = .timesheets
                        }
                        
                        if url.host == "endshift" {
                            navigationState.currentTab = .home
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                                navigationState.activeSheet = .endShiftSheet
                            }
                        }
                   
                        if url.host == "endbreak" {
                            navigationState.currentTab = .home
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                                navigationState.activeSheet = .endBreakSheet
                            }
                        }
                        
                        if url.host == "startbreak" {
                            navigationState.currentTab = .home
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                                navigationState.activeSheet = .startBreakSheet
                            }
                        }
                   
                     
                        
                        
                        
                       
                        
                    }
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


