//
//  JobSelectionManager.swift
//  ShiftTracker
//
//  Created by James Poole on 30/07/23.
//

import Foundation
import CoreData
import SwiftUI

class JobSelectionManager: ObservableObject {
    @Published var selectedJobUUID: UUID?
    @Published var selectedJobOffset: CGFloat = 0.0
    @Published var latestShifts: [OldShift] = []
    @AppStorage("selectedJobUUID") private var storedSelectedJobUUID: String = ""

    private func fetchLatestShifts(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
   
        guard let job = fetchJob(in: context) else {
            print("Job not found.")
            return
        }
        
       
        let jobPredicate = NSPredicate(format: "job == %@", job)
        let activeShiftPredicate = NSPredicate(format: "isActive == NO")
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [jobPredicate, activeShiftPredicate])
        
        fetchRequest.predicate = compoundPredicate
        fetchRequest.fetchLimit = 10 // Limit to 10 latest shifts
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "shiftStartDate", ascending: false)]

        do {
            let shifts = try context.fetch(fetchRequest)
            self.latestShifts = shifts
        } catch {
            print("Failed to fetch old shifts: \(error)")
        }
    }


    
    
    func fetchJob(with uuid: UUID? = nil, in context: NSManagedObjectContext) -> Job? {
        let id = uuid ?? selectedJobUUID
        guard let uuidToFetch = id else { return nil }
        let request: NSFetchRequest<Job> = Job.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", uuidToFetch as CVarArg)
        request.fetchLimit = 1

        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching job: \(error)")
            return nil
        }
    }

    
    func selectJob(_ job: Job, with jobs: FetchedResults<Job>, shiftViewModel: ContentViewModel) {
        //if shiftViewModel.currentShift == nil {
            if let jobUUID = job.uuid {
                let currentIndex = jobs.firstIndex(where: { $0.uuid == jobUUID }) ?? 0
                let selectedIndex = jobs.firstIndex(where: { $0.uuid == selectedJobUUID }) ?? 0
                withAnimation(.spring()) {
                    selectedJobOffset = CGFloat(selectedIndex - currentIndex) * 60
                }
                selectedJobUUID = jobUUID
                shiftViewModel.selectedJobUUID = jobUUID
                storedSelectedJobUUID = jobUUID.uuidString
            }
      /*  } else {
            OkButtonPopup(title: "End your current shift to select another job.").showAndStack()
        }*/
    }
    
    // used when editing the currently selected job
    func updateJob(_ job: Job){
        
        selectedJobUUID = job.uuid
        storedSelectedJobUUID = job.uuid!.uuidString
        
    }
    
    
    func deselectJob(shiftViewModel: ContentViewModel){
        
       // if shiftViewModel.currentShift == nil {
            
            selectedJobUUID = nil
            storedSelectedJobUUID = ""
       /* } else {
            OkButtonPopup(title: "End your current shift to deselect this job.").showAndStack()

        }*/
        
        
        
    }
    
    
    
    
    
}
