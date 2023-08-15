//
//  IntentHandler.swift
//  SelectJobIntentExtent
//
//  Created by James Poole on 15/08/23.
//
 
 import CoreData
 import Intents

class IntentHandler: INExtension, SelectJobIntentHandling {
    
    let persistenceController = PersistenceController.shared
    
    func provideJobOptionsCollection(for intent: SelectJobIntent, searchTerm: String?, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
        let jobIdentifiers = persistenceController.fetchAllJobIdentifiers()
        let jobNames = jobIdentifiers.map { NSString(string: $0.name) } // Just use the job name
   
        completion(INObjectCollection(items: jobNames), nil)
    }
    
     


     override func handler(for intent: INIntent) -> Any {
         return self
     }
 }



 class JobIdentifier {
     var uuidString: String
     var name: String

     init(uuidString: String, name: String) {
         self.uuidString = uuidString
         self.name = name
     }
 }



 extension PersistenceController {
     func fetchAllJobIdentifiers() -> [JobIdentifier] {
         var jobIdentifiers = [JobIdentifier]()
         let context = container.viewContext
         let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Job")

         do {
             let jobs = try context.fetch(fetchRequest)
             
             print("theres so many jobs \(jobs.count)")
             
             for job in jobs {
                 if let uuid = job.value(forKey: "uuid") as? UUID,
                    let name = job.value(forKey: "name") as? String {
                     jobIdentifiers.append(JobIdentifier(uuidString: uuid.uuidString, name: name))
                 }
             }
         } catch {
             print("Failed to fetch jobs: \(error)")
         }

         return jobIdentifiers
     }
 }
