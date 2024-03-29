//
//  PersistenceController.swift
//  ShiftTracker
//
//  Created by James Poole on 19/03/23.
//

import Foundation
import CoreData

struct PersistenceController {
    // A singleton for our entire app to use
    static let shared = PersistenceController()

    // Storage for Core Data
    var container: NSPersistentContainer

    // A test configuration for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)


        return controller
    }()

    // An initializer to load Core Data, optionally able
    // to use an in-memory store.
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ShiftDataModel")
                let url = URL.storeURL(for: "group.com.poole.james.ShiftTracker", databaseName: "ShiftDataModel")
                let storeDescription = NSPersistentStoreDescription(url: url)
                container.persistentStoreDescriptions = [storeDescription]
                
                if inMemory {
                    container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
                } else {
                    // Enable or disable CloudKit based on the user's preference
                    let iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudEnabled")
                    
                    storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                    
                
                        
                        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                        let containerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.poole.james.ShiftTracker")
                        storeDescription.cloudKitContainerOptions = iCloudEnabled ? containerOptions : nil
                    
                }
        // use this to wipe core data upon launch if modifying the data base
     /*   do {
            try container.persistentStoreCoordinator.destroyPersistentStore(at: container.persistentStoreDescriptions.first!.url!, type: .sqlite)
        } catch {
            
            fatalError("Error: \(error.localizedDescription)")
            
        }
            */
        

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
            
        }
    }
    

    
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Show some error here
            }
        }
    }
    
    func updateCloudKitSyncStatus() {
        let iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudEnabled")
        let storeDescription = container.persistentStoreDescriptions.first!
        
        
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            let containerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.poole.james.ShiftTracker")
            storeDescription.cloudKitContainerOptions = iCloudEnabled ? containerOptions : nil
        

        // Reload persistent stores
        reloadPersistentStores()
    }

    func reloadPersistentStores() {
        let stores = container.persistentStoreCoordinator.persistentStores

        for store in stores {
            guard let storeURL = store.url else { continue }
            do {
                try container.persistentStoreCoordinator.remove(store)
                try container.persistentStoreCoordinator.addPersistentStore(
                    ofType: store.type,
                    configurationName: store.configurationName,
                    at: storeURL,
                    options: store.options
                )
            } catch {
                print("Error updating CloudKit sync status: \(error)")
            }
        }
    }


    
}

public extension URL{
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let FileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Unable to create URL for \(appGroup)")
        }
        return FileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}
