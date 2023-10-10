//
//  SortSelection.swift
//  ShiftTracker
//
//  Created by James Poole on 4/08/23.
//

import Foundation
import CoreData
import SwiftUI
import Combine

class SortSelection: ObservableObject {
    @Published var selectedSort: ShiftNSSort = .default
    
    @Published var selectedFilters: Set<TagFilter> = []
    
    @Published var oldShifts: [OldShift] = []
    @Published var filteredShifts: [OldShift] = []
    
    private var searchTask: DispatchWorkItem?
    
    @Published var searchTerm: String = "" {
        
        
        didSet {
                searchTask?.cancel()
                
                let task = DispatchWorkItem { [weak self] in
                    self?.fetchShifts()
                }
                
                searchTask = task
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
            }

    }
    

    private var viewContext: NSManagedObjectContext

    init(in context: NSManagedObjectContext) {
        
        print("I got reinitialised for some god damn reason ")
        self.viewContext = context
        fetchShifts()
    }

    
     func fetchShifts() {
        let request = NSFetchRequest<OldShift>(entityName: "OldShift")
        request.sortDescriptors = selectedSort.descriptors
         
         var predicates = selectedFilters.compactMap { $0.predicate }
         
         if !searchTerm.isEmpty {
                 let searchPredicate = NSPredicate(
                     format: "shiftNote contains[cd] %@", searchTerm)
                 predicates.append(searchPredicate)
             }
         
         if !predicates.isEmpty {
             
             request.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
         }

        do {
            try withAnimation{
                oldShifts = try viewContext.fetch(request)
                filteredShifts = oldShifts
            }
        } catch {
            print("Failed to fetch shifts: \(error)")
        }
    }
}
