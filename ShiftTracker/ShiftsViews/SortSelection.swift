//
//  SortSelection.swift
//  ShiftTracker
//
//  Created by James Poole on 4/08/23.
//

import Foundation
import CoreData
import SwiftUI

class SortSelection: ObservableObject {
    @Published var selectedSort: ShiftNSSort = .default
    
    @Published var selectedFilters: Set<TagFilter> = []
    
    @Published var oldShifts: [OldShift] = []
    @Published var filteredShifts: [OldShift] = []
    
    @Published var searchTerm: String = "" {
        didSet {
            if searchTerm.isEmpty {
                if oldShifts.isEmpty {
                    fetchShifts()
                }
                filteredShifts = oldShifts
            } else {
                filteredShifts = oldShifts.filter {
                    $0.shiftNote?.lowercased().contains(searchTerm.lowercased()) ?? false
                }
            }
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
    
    func commitSearch() {
            fetchShifts() // we only commit full fetch when searching if they submit the search to be more efficient
        }
    
}
