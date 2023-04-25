//
//  PersistenceController.swift
//  ShiftTracker Watch Edition Watch App
//
//  Created by James Poole on 25/04/23.
//

import Foundation
import CoreData

class WatchPersistenceController: ObservableObject {
    static let shared = WatchPersistenceController()

    let container: NSPersistentContainer


    static var preview: WatchPersistenceController = {
        let controller = WatchPersistenceController(inMemory: true)



        return controller
    }()


    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ShiftTrackerWatchDataModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

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
                // error here
            }
        }
    }
    
}
