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
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var shiftStore: ShiftStore
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var scrollManager: ScrollManager
    @EnvironmentObject var overviewModel: JobOverviewViewModel
    
    @EnvironmentObject var sortSelection: SortSelection
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismissSearch) private var dismissSearch
    
    @State var editMode = EditMode.inactive
    @State private var showExportView = false
    @State private var showInvoiceView = false
    @State private var showingProView = false
    
    @State private var showingSearch: Bool = false
    
    @State private var scrollPos: CGFloat = 0
    
    @Binding var navPath: NavigationPath
    
    @State private var selection = Set<NSManagedObjectID>()
    
    var body: some View {
        let allShifts = sortSelection.filteredShifts.filter { shiftManager.shouldIncludeShift($0, jobModel: selectedJobManager) }
        ZStack(alignment: .bottomTrailing){
            ScrollViewReader { proxy in
                List(selection: editMode.isEditing ? $selection : .constant(Set<NSManagedObjectID>())) {
                    
                    ForEach(Array(allShifts.enumerated()), id: \.element.objectID) { index, shift in
                        ZStack {
                            NavigationLink(value: shift) {
                                ShiftDetailRow(shift: shift)
                            }
                            
                            .background {
                                
                                
                                
                                let deleteUIAction = UIAction(title: "Delete", image: UIImage(systemName: "trash.fill"), attributes: .destructive) { _ in
                                   
                                    deleteShift(shift)
                                   
                                }
                                
                                let duplicateUIAction = UIAction(title: "Duplicate", image: UIImage(systemName: "plus.square.fill.on.square.fill")) { _ in
                                    
                                   duplicateShift(shift)
                                    
                                }
                                
                                let shareUIAction = UIAction(title: "Export", image: UIImage(systemName: "square.and.arrow.up.fill")) { _ in
                                    
                                    exportShift(shift)
                                    
                                }
                                
                                
                                
                                ContextMenuPreview(shift: shift, themeManager: themeManager, navigationState: navigationState, viewContext: viewContext, actionsArray: [deleteUIAction, duplicateUIAction, shareUIAction], editMode: $editMode, action: {
                                    if !editMode.isEditing {
                                        navPath.append(shift)
                                    }
                                })
                                
                                
                            }
                    
                            
                            if !sortSelection.searchTerm.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(alignment: .trailing){
                                        if selectedJobManager.fetchJob(in: viewContext) == nil {
                                            Spacer()
                                            
                                        }
                                        HStack{
                                            Spacer()
                                            
                                            HighlightedText(text: shift.shiftNote ?? "", highlight: sortSelection.searchTerm)
                                                .padding(.vertical, selectedJobManager.fetchJob(in: viewContext) == nil ? 2 : 3)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(6)
                                                .padding(.bottom, selectedJobManager.fetchJob(in: viewContext) == nil ? 5 : 0)
                                                .padding(.trailing, selectedJobManager.fetchJob(in: viewContext) == nil ? 0 : 12)
                                        }
                                    }.frame(maxWidth: 180)
                                        .frame(maxHeight: 20)
                                        .frame(alignment: .trailing)
                                }
                            }
                        }
                        .listRowInsets(.init(top: 10, leading: selectedJobManager.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
                        .listRowBackground(Color.clear)
                        
                        .background {
                            
                            // we dont need the geometry reader, performance is better just doing this
                            if index == 0 {
                                Color.clear
                                    .onDisappear {
                                        scrollManager.timeSheetsScrolled = true
                                    }
                                    .onAppear {
                                        scrollManager.timeSheetsScrolled = false
                                    }
                            }
                        }
                        
                        .swipeActions {
                            
                            OldShiftSwipeActions(deleteAction: {deleteShift(shift)}, duplicateAction: {duplicateShift(shift)})
                            
                        }
                        
                        .swipeActions(edge: .leading) {
                            Button(action: {
                                exportShift(shift)
                            }){
                                Image(systemName: "square.and.arrow.up.fill")
                            }.tint(.gray)
                            
                        }
                        
         
                        
                        .id(index)
                        
                    }
                    
                    
                    
                    
                    Section {
                        Spacer(minLength: 100)
                    }.listRowBackground(Color.clear)
                        .opacity(0)
                        .listRowSeparator(.hidden)
                    
                    
                }.listStyle(.plain)
                
                    .customSearchable(searchText: $sortSelection.searchTerm, isPresented: $showingSearch, prompt: "Search Notes")
                
                
                    .onSubmit(of: .search, sortSelection.fetchShifts)
                
                
                
                
                    .tint(Color.gray)
                    .scrollContentBackground(.hidden)
                
                
                    .background {
                        // this could be worked into the themeManagers pure dark mode?
                        
                        
                        // weirdly enough it looks good switching to the settings background here
                        if colorScheme == .dark {
                            themeManager.settingsDynamicBackground.ignoresSafeArea()
                        } else {
                            Color.clear.ignoresSafeArea()
                        }
                    }
                
                
                
                    .onAppear {
                        
                        print(sortSelection.selectedSort)
                        
                        if navigationState.gestureEnabled || sortSelection.oldShifts.isEmpty {
                            navigationState.gestureEnabled = false
                            sortSelection.fetchShifts()
                        }
                        
                        
                        
                    }
                
                    .onChange(of: scrollManager.scrollOverviewToTop) { value in
                        if value {
                            withAnimation(.spring) {
                                proxy.scrollTo(0, anchor: .top)
                            }
                            DispatchQueue.main.async {
                                
                                scrollManager.scrollOverviewToTop = false
                            }
                        }
                        
                        
                        
                    }
                
                
            }
            
            floatingButtons .padding(.bottom, navigationState.hideTabBar ? 49 : 0).animation(.none, value: navigationState.hideTabBar)
            
            
            
            
        }.ignoresSafeArea(.keyboard)
        
            .navigationTitle(!selection.isEmpty ? "\(selection.count) selected" : sortSelection.selectedSort.name)
            .navigationBarBackButtonHidden(editMode.isEditing)
        
            .toolbar{
                if editMode.isEditing {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            
                            if selection.isEmpty {
                                let objectIDs = allShifts.map { shift in
                                    return shift.objectID
                                }
                                
                                selection = Set(objectIDs)
                            } else {
                                selection = Set()
                            }
                            
                        }){
                            Text(selection.isEmpty ? "Select All" : "Unselect All")
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
        
        
            .sheet(isPresented: $showExportView, onDismiss: {
                if selection.count <= 1 {
                    selection = Set()
                }
            }) {
                
                ConfigureExportView(job: selectedJobManager.fetchJob(in: viewContext), selectedShifts: selection, arrayShifts: sortSelection.oldShifts)
                    .presentationDetents([.large])
                    .customSheetRadius(35)
                    .customSheetBackground()
                
            }
        
            .sheet(isPresented: $showInvoiceView, onDismiss: {
                if selection.count <= 1 {
                    selection = Set()
                }
            }) {
                GenerateInvoiceView(job: selectedJobManager.fetchJob(in: viewContext), selectedShifts: selection, arrayShifts: sortSelection.oldShifts)
                
                    .customSheetBackground()
                    .customSheetRadius(35)
            }
        
        
        
            .fullScreenCover(isPresented: $showingProView) {
                ProView()
                    .environmentObject(purchaseManager)
                
                    .customSheetBackground()
            }
        
        
            .toolbar(editMode.isEditing ? .hidden : .visible, for: .tabBar)
        
        
            .onChange(of: editMode.isEditing) { value in
                withAnimation {
                if value {
                  
                        navigationState.hideTabBar = true
                        
                    } else {
                        navigationState.hideTabBar = false
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
            
            editMode = .inactive
            
        }
    }
    
    var floatingButtons: some View {
        VStack(alignment: .trailing) {
            
            VStack{
                
                HStack(spacing: 10){
                    
                    
                    
                    Group {
                        
                        
                        if editMode.isEditing {
                            
                            
                            Menu {
                                
                                Button(action: {
                                    
                                    if purchaseManager.hasUnlockedPro {
                                        showExportView.toggle()
                                    } else {
                                        
                                        showingProView.toggle()
                                        
                                    }
                                    
                                    
                                }){
                                    Text("Export to CSV")
                                    Image(systemName: "tablecells").bold()
                                }
                                
                                Button(action: {
                                    
                                    if purchaseManager.hasUnlockedPro {
                                        showInvoiceView.toggle()
                                    } else {
                                        
                                        showingProView.toggle()
                                        
                                    }
                                    
                                    
                                }){
                                    Text("Generate Invoice")
                                    Image(systemName: "paperplane").bold()
                                }
                                
                            } label: {
                                Image(systemName: "square.and.arrow.up").bold()
                            }.disabled(selection.isEmpty)
                            
                           
                            
                            Divider().frame(height: 10)
                            
                            
                            
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
                        
                        
                        Divider().frame(height: 10)
                        
                        
                    }  .animation(.easeInOut, value: editMode.isEditing)
                    
                    
                    CustomEditButton(editMode: $editMode, action: {
                        selection.removeAll()
                    })
                    
                    
                    
                    
                    
                    
                    
                    
                    
                }.padding()
                    .glassModifier(cornerRadius: 20)
                
            }.padding(.trailing)
            
            TagSortView(selectedFilters: $sortSelection.selectedFilters)
                .frame(width: UIScreen.main.bounds.width - 100)
                .frame(maxHeight: 40)
                .padding(5)
                .glassModifier(cornerRadius: 20)
            
                .padding(.bottom, 10)
                .padding(.trailing)
            
            
            
                .onChange(of: sortSelection.selectedFilters) { _ in
                    
                    sortSelection.fetchShifts()
                    
                }
            
            
        }
    }
    
    func deleteShift(_ shift: OldShift) {
        withAnimation {
            shiftStore.deleteOldShift(shift, in: viewContext)
            
            // duct tape fix
            sortSelection.fetchShifts()
            
            if sortSelection.oldShifts.isEmpty {
                // navigates back if all shifts are deleted
                navPath.removeLast()
                
            }
        }
    }
    
    func duplicateShift(_ shift: OldShift) {
        overviewModel.selectedShiftToDupe = shift
        
        overviewModel.activeSheet = .addShiftSheet
    }
    
    func exportShift(_ shift: OldShift) {
        
        selection = Set(arrayLiteral: shift.objectID)
        showExportView.toggle()
    }
    
}
