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
    @EnvironmentObject var themeManager: ThemeDataManager

    @EnvironmentObject var sortSelection: SortSelection

    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) private var editMode
    @Environment(\.dismissSearch) private var dismissSearch
    
    @State private var isShareSheetShowing = false
    
    
    @State private var showingAddShiftSheet: Bool = false
    
    
    
    @Binding var navPath: NavigationPath
    
    @State private var selection = Set<NSManagedObjectID>()
    
    
    var body: some View {
        
        ZStack(alignment: .bottomTrailing){
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
                .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                
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
            Section {
                Spacer(minLength: 100)
            }.listRowBackground(Color.clear)
                .opacity(0)

        }.searchable(text: $sortSelection.searchTerm, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Notes")
            
                .onSubmit(of: .search, sortSelection.fetchShifts)
               
            .tint(Color.gray)
            .scrollContentBackground(.hidden)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
          
                    .background {
                        themeManager.overviewDynamicBackground.ignoresSafeArea()
                    }

            .onAppear {
                
                print(sortSelection.selectedSort)
                
                if navigationState.gestureEnabled || sortSelection.oldShifts.isEmpty {
                    navigationState.gestureEnabled = false
                    sortSelection.fetchShifts()
                }
                
                
                
            }
            
            VStack(alignment: .trailing) {
                
                VStack{
                
                HStack(spacing: 10){
                    
                    EditButton()
                    
                    Divider().frame(height: 10)
                    
                    if editMode?.wrappedValue.isEditing == true {
                        
                        Button(action: {
                            CustomConfirmationAlert(action: deleteItems, cancelAction: nil, title: "Are you sure?").showAndStack()
                        }) {
                            Image(systemName: "trash").customAnimatedSymbol(value: $selection)
                                .bold()
                        }.disabled(selection.isEmpty)
                            .tint(.red)
                        
                    } else {
                        
                        SortSelectionView(selectedSortItem: $sortSelection.selectedSort, sorts: ShiftNSSort.sorts)
                            .onChange(of: sortSelection.selectedSort) { _ in
                                sortSelection.fetchShifts()
                            }
                        
                    }
                    
                    
                    
                    
                }.padding()
                        .glassModifier(cornerRadius: 20)

            }
                
                TagSortView(selectedFilters: $sortSelection.selectedFilters)
                    .frame(width: UIScreen.main.bounds.width - 20)
                    .frame(maxHeight: 40)
                    .padding(5)
                    .glassModifier(cornerRadius: 20)
                
                    .padding(.bottom, 5)
                
                    .onChange(of: sortSelection.selectedFilters) { _ in
                        
                        sortSelection.fetchShifts()
                        
                    }
                
                
            }
        
        }.ignoresSafeArea(.keyboard)

        .navigationBarTitle(sortSelection.selectedSort.name)

            
        
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
