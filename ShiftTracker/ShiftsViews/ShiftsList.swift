//
//  ShiftsList.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI
import CoreData
import Foundation
import Combine

struct ShiftsList: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var shiftStore: ShiftStore
    
    @EnvironmentObject var savedPublisher: ShiftSavedPublisher
    
    @EnvironmentObject var sortSelection: SortSelection

    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) private var editMode
    @Environment(\.dismissSearch) private var dismissSearch
    
    @State private var isShareSheetShowing = false
    
    
    @State private var showingAddShiftSheet: Bool = false
    
    
    
    @Binding var navPath: NavigationPath
    
    @State private var selection = Set<NSManagedObjectID>()
    
    
    
    
    var body: some View {
        
        ZStack(alignment: .bottom){
        List(selection: $selection){
            ForEach(sortSelection.filteredShifts.filter { shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) }, id: \.objectID) { shift in
                ZStack {
                    NavigationLink(value: shift) {
                        ShiftDetailRow(shift: shift)
                    }
                    if !sortSelection.searchTerm.isEmpty {
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing){
                                if jobSelectionViewModel.fetchJob(in: viewContext) == nil {
                                    Spacer()
                                    
                                }
                                HStack{
                                    Spacer()
                                    
                                    HighlightedText(text: shift.shiftNote ?? "", highlight: sortSelection.searchTerm)
                                        .padding(.vertical, jobSelectionViewModel.fetchJob(in: viewContext) == nil ? 2 : 5)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(6)
                                        .padding(.bottom, jobSelectionViewModel.fetchJob(in: viewContext) == nil ? 5 : 0)
                                        .padding(.trailing, jobSelectionViewModel.fetchJob(in: viewContext) == nil ? 0 : 12)
                                }
                            }.frame(maxWidth: 180)
                                .frame(alignment: .trailing)
                        }
                    }
                }
                .listRowInsets(.init(top: 10, leading: jobSelectionViewModel.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
                .listRowBackground(Color("SquaresColor"))
                
                .swipeActions {
                    Button(role: .destructive) {
                        shiftStore.deleteOldShift(shift, in: viewContext)
                        
                        if sortSelection.oldShifts.isEmpty {
                            // navigates back if all shifts are deleted
                            navPath.removeLast()
                            
                        }
                        
                    } label: {
                        Image(systemName: "trash")
                    }
                }

            }
            
            // bottom "padding" if the list is long, as the tag picker will overlap 
            
            if sortSelection.filteredShifts.filter({ shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) }).count >= 5 {
                Color.clear
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color("SquaresColor"))
            }

        }.searchable(text: $sortSelection.searchTerm, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Notes")
            
                .onSubmit(of: .search, sortSelection.fetchShifts)
               
            .tint(Color.gray)
            .scrollContentBackground(.hidden)

            .onAppear {
                
                print(sortSelection.selectedSort)
                
                if navigationState.gestureEnabled || sortSelection.oldShifts.isEmpty {
                    navigationState.gestureEnabled = false
                    sortSelection.fetchShifts()
                }
                
                
                
            }

            TagSortView(selectedFilters: $sortSelection.selectedFilters)
                .padding(.bottom)
                .background {
                    
                    colorScheme == .dark ? Color.black : Color.white
                        
                    
                } //.padding(.top)
                .frame(width: UIScreen.main.bounds.width)
                .frame(maxHeight: 30)
            
                .onChange(of: sortSelection.selectedFilters) { _ in
                    
                    sortSelection.fetchShifts()
                    
                }
        
    }
        
        
        
        
        .navigationBarTitle(sortSelection.selectedSort.name)
        
        
            .toolbar{
                
                ToolbarItemGroup(placement: .keyboard){
                    
                    Spacer()
                    
                    Button("Done"){
                        
                        hideKeyboard()
                        
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing){
                    
                   
                    
                    EditButton()
                    
                    if editMode?.wrappedValue.isEditing == true {
                        
                        Button(action: {
                            CustomConfirmationAlert(action: deleteItems, cancelAction: nil, title: "Are you sure?").showAndStack()
                        }) {
                            Image(systemName: "trash")
                                .bold()
                        }.disabled(selection.isEmpty)
                        
                    } else {
                        
                        SortSelectionView(selectedSortItem: $sortSelection.selectedSort, sorts: ShiftNSSort.sorts)
                            .onChange(of: sortSelection.selectedSort) { _ in
                                sortSelection.fetchShifts()
                            }
                        
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






class ShiftSavedPublisher: ObservableObject {
    let shiftChanged = PassthroughSubject<Void, Never>()

    func changedShift() {
        shiftChanged.send()
    }
}
