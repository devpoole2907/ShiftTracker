//
//  ChartWidgetProvider.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import Foundation
import WidgetKit
import Intents
import CoreData

struct ChartWidgetProvider: IntentTimelineProvider {
    typealias Entry = JobEntry
    typealias Intent = SelectJobIntent
    
    
    func placeholder(in context: Context) -> JobEntry {
        
        
        
        JobEntry(date: Date(), job: nil, oldShifts: [])
    }

    func getSnapshot(for configuration: SelectJobIntent, in context: Context, completion: @escaping (JobEntry) -> Void) {
        let job = fetchJob(byName: configuration.job ?? "")
        
        let allOldShifts = (try? fetchShifts(forJob: job)) ?? []
        
        completion(JobEntry(date: Date(), job: job, oldShifts: allOldShifts))
        }

        func getTimeline(for configuration: SelectJobIntent, in context: Context, completion: @escaping (Timeline<JobEntry>) -> Void) {
            let job = fetchJob(byName: configuration.job ?? "")
            
            let allOldShifts = (try? fetchShifts(forJob: job)) ?? []
            
            let entries = [JobEntry(date: Date(), job: job, oldShifts: allOldShifts)]
            let timeline = Timeline<JobEntry>(entries: entries, policy: .atEnd)
            completion(timeline)
        }

    func fetchJob(byName name: String) -> Job? {
        let request = NSFetchRequest<Job>(entityName: "Job")
        request.predicate = NSPredicate(format: "name == %@", name)
        do {
            let fetchedJobs = try PersistenceController.shared.container.viewContext.fetch(request)
            return fetchedJobs.first
        } catch {
            print("Failed to fetch job: \(error)")
            return nil
        }
    }
    
    private func fetchShifts(forJob job: Job?) throws -> [OldShift] {
        let context = PersistenceController.shared.container.viewContext


        
        let request: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        request.predicate = nil
        if let job = job {
            request.predicate = NSPredicate(format: "job == %@", job)

        }
       
        let result = try context.fetch(request)
        return result
    }



}
