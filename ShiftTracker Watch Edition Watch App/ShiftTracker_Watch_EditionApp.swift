//
//  ShiftTracker_Watch_EditionApp.swift
//  ShiftTracker Watch Edition Watch App
//
//  Created by James Poole on 25/04/23.
//

import SwiftUI

@main
struct ShiftTracker_Watch_Edition_Watch_AppApp: App {
    
   // let persistenceController = WatchPersistenceController.shared
    
    @AppStorage("iCloudEnabled") private var iCloudSyncOn: Bool = true
    
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
