//
//  ShiftsList.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI
import CoreData
import Foundation

struct ShiftsList: View {
    
   // @StateObject var temporaryViewModel = ContentViewModel()
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    @EnvironmentObject var shiftManager: ShiftDataManager
    
    
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) private var editMode
    
    @State private var isShareSheetShowing = false
    
    @State private var searchTerm = ""
    
    @State private var showingAddShiftSheet: Bool = false
    
    var searchQuery: Binding<String> {
      Binding {
        searchTerm
      } set: { newValue in
        searchTerm = newValue
        
        guard !newValue.isEmpty else {
          shifts.nsPredicate = nil
          return
        }
        shifts.nsPredicate = NSPredicate(
          format: "shiftNote contains[cd] %@",
          newValue)
      }
    }

    
    @FetchRequest(
        sortDescriptors: ShiftSort.default.descriptors,
        predicate: nil,
      animation: .default)
    private var shifts: FetchedResults<OldShift>

    @State private var selectedSort = ShiftSort.default
    
    @Binding var navPath: NavigationPath
    
    @State private var selection = Set<NSManagedObjectID>()
    
    
    
    var body: some View {
        
      
           
        List(selection: $selection){
            /*    Section {
             TagButtonView().environmentObject(temporaryViewModel)
             .frame(maxWidth: .infinity)
             }.listRowBackground(Color.clear)
             .listRowInsets(EdgeInsets()) */
            
            ForEach(shifts.filter { shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) }, id: \.objectID) { shift in
                
                
                NavigationLink(value: shift) {
                    ShiftDetailRow(shift: shift)
                }
                
                .navigationDestination(for: OldShift.self) { shift in
                    DetailView(shift: shift, presentedAsSheet: false, navPath: $navPath).navigationBarTitle(jobSelectionViewModel.fetchJob(in: viewContext) == nil ? (shift.job?.name ?? "Shift Details") : "Shift Details")
                    
                }
                
                .listRowInsets(.init(top: 10, leading: jobSelectionViewModel.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
                .listRowBackground(Color("SquaresColor"))
                
                .swipeActions {
                    Button(role: .destructive) {
                        shiftManager.deleteShift(shift, in: viewContext)
                        
                        if shifts.isEmpty {
                            // navigates back if all shifts are deleted
                            navPath.removeLast()
                            
                        }
                        
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                
            }
            
            
            
        }.searchable(text: searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Notes")
            .tint(Color.gray)
            .scrollContentBackground(.hidden)
          //  .padding(.top, 25)
        
        
            .onAppear {
                navigationState.gestureEnabled = false
                
            }
            
        
    
        
            .navigationBarTitle(selectedSort.name)
          
        
        .toolbar{
            
            
            
            ToolbarItem(placement: .navigationBarTrailing){
                
                
                if editMode?.wrappedValue.isEditing == true {
                    
                        Button(action: {
                            CustomConfirmationAlert(action: deleteItems, cancelAction: nil, title: "Are you sure?").showAndStack()
                        }) {
                            Image(systemName: "trash")
                        }.disabled(selection.isEmpty)
                    
                }
                
                
            }
            
            
            ToolbarItem(placement: .navigationBarTrailing){
                 
         EditButton()
                 
                 
             }
            
            ToolbarItem(placement: .navigationBarTrailing){
                
                Menu {
                
                Menu {
                    Picker("Sort By", selection: $selectedSort) {
                        ForEach(ShiftSort.sorts, id: \.self) { sort in
                            Text("\(sort.name)")
                        }
                    }
                } label: {
                    Label(
                        "Sort",
                        systemImage: "line.horizontal.3.decrease.circle")
                }
                .disabled(!selection.isEmpty)
                .onChange(of: selectedSort) { _ in
                    let request = shifts
                    request.sortDescriptors = selectedSort.descriptors
                }
                    
                    Menu {
                        Picker("Sort By", selection: $selectedSort) {
                            ForEach(ShiftSort.sorts, id: \.self) { sort in
                                Text("\(sort.name)")
                            }
                        }
                    } label: {
                        Label(
                            "Tags",
                            systemImage: "number.circle")
                    }
                    .disabled(!selection.isEmpty)
                    .onChange(of: selectedSort) { _ in
                        let request = shifts
                        request.nsPredicate = nil
                    }
                
                
                } label: {
                    
                    
                    
                        Image(systemName: "ellipsis.circle")
                    
                }
            }
         
            
        }
        
    }
    
    private func deleteItems() {
        withAnimation {
            selection.forEach { objectID in
                let itemToDelete = viewContext.object(with: objectID)
                viewContext.delete(itemToDelete)
            }
            
            do {
                try viewContext.save()
                selection.removeAll()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    


    
}

struct ShiftSort: Hashable, Identifiable {
  let id: Int
  let name: String
  let descriptors: [SortDescriptor<OldShift>]
    
    
    static let sorts: [ShiftSort] = [
      ShiftSort(
        id: 0,
        name: "Latest",
        descriptors: [
          SortDescriptor(\OldShift.shiftStartDate, order: .reverse)
        ]),
      ShiftSort(
        id: 1,
        name: "Oldest",
        descriptors: [
          SortDescriptor(\OldShift.shiftStartDate, order: .forward)
        ]),
      ShiftSort(
        id: 2,
        name: "Pay | Ascending",
        descriptors: [
            SortDescriptor(\OldShift.taxedPay, order: .reverse)
        ]),
      ShiftSort(
        id: 3,
        name: "Pay | Descending",
        descriptors: [
            SortDescriptor(\OldShift.taxedPay, order: .forward)
        ]),
      ShiftSort(
        id: 4,
        name: "Longest",
        descriptors: [
          SortDescriptor(\OldShift.duration, order: .reverse)
        ]),
      ShiftSort(
        id: 5,
        name: "Shortest",
        descriptors: [
          SortDescriptor(\OldShift.duration, order: .forward)
        ])
    ]

    // 4
    static var `default`: ShiftSort { sorts[0] }
    
    
}




