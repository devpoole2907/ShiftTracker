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

    @EnvironmentObject var sortSelection: SortSelection

    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) private var editMode
    @Environment(\.dismissSearch) private var dismissSearch
    
    @State private var showExportView = false
    @State private var showingProView = false
    
    @State private var showingSearch: Bool = false
    
    @State private var scrollPos: CGFloat = 0
    
    
    @Binding var navPath: NavigationPath
    
    @State private var selection = Set<NSManagedObjectID>()
    
    
    var body: some View {
        
        ZStack(alignment: .bottomTrailing){
            ScrollViewReader { proxy in
            List(selection: $selection){
                ForEach(Array(sortSelection.filteredShifts.filter { shiftManager.shouldIncludeShift($0, jobModel: selectedJobManager) }.enumerated()), id: \.element.objectID) { index, shift in
                    ZStack {
                        NavigationLink(value: shift) {
                            ShiftDetailRow(shift: shift)
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
                    .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                    
                    .background {
                        if index == 0 {
                            GeometryReader { geometry in
                                                Color.clear.preference(key: ScrollOffsetKey.self, value: geometry.frame(in: .global).minY)
                                            }
                            
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    scrollManager.timeSheetsScrolled = false
                                }
                            }
                        }
                    }
                    
                    .swipeActions {
                        
                        Button(action: {
                            withAnimation {
                                shiftStore.deleteOldShift(shift, in: viewContext)
                                
                                // duct tape fix
                                sortSelection.fetchShifts()
                                
                                if sortSelection.oldShifts.isEmpty {
                                    // navigates back if all shifts are deleted
                                    navPath.removeLast()
                                    
                                }
                            }
                        }){
                            Image(systemName: "trash")
                        }
                        
                        .tint(.clear)
                    }
                    
                    .id(index)
                    
                }
                
                
                
                
                Section {
                    Spacer(minLength: 100)
                }.listRowBackground(Color.clear)
                    .opacity(0)
                
               
            }.customSearchable(searchText: $sortSelection.searchTerm, isPresented: $showingSearch, prompt: "Search Notes")
            
            
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
                
                .onPreferenceChange(ScrollOffsetKey.self) { offset in
                    if !(offset <= 0) && !scrollManager.timeSheetsScrolled {
                        print("offset is \(offset)")
                        scrollManager.timeSheetsScrolled = true
                        self.scrollPos = offset
                    }
                }

                
                .onChange(of: scrollManager.scrollOverviewToTop) { value in
                                if value {
                                    withAnimation {
                                        proxy.scrollTo(0, anchor: .top)
                                    }
                                    DispatchQueue.main.async {
                                    
                                        scrollManager.scrollOverviewToTop = false
                                    }
                                }
                            }
                
              
        }
            
            VStack(alignment: .trailing) {
                
                VStack{
                
                HStack(spacing: 10){
                    
                    EditButton()
                    
                    Divider().frame(height: 10)
                    
                   
                    
                    Button(action: {
                        
                        if purchaseManager.hasUnlockedPro {
                            showExportView.toggle()
                        } else {
                            
                            showingProView.toggle()
                            
                        }
                        
                       
                    }){
                        Image(systemName: "square.and.arrow.up").bold()
                    }.disabled(selection.isEmpty)
                    
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

        .navigationTitle(sortSelection.selectedSort.name)
        .navigationBarBackButtonHidden(editMode?.wrappedValue.isEditing ?? false)
        .onAppear {
            print("scroll pos is \(scrollPos)")
            if scrollPos > 50 {
                scrollManager.timeSheetsScrolled = true
            }
        }

        .sheet(isPresented: $showExportView) {
            
            ConfigureExportView(job: selectedJobManager.fetchJob(in: viewContext), selectedShifts: selection, arrayShifts: sortSelection.oldShifts)
                .presentationDetents([.large])
                .customSheetRadius(35)
                .customSheetBackground()
        
        }
        

        
        .fullScreenCover(isPresented: $showingProView) {
            ProView()
                .environmentObject(purchaseManager)
            
                .customSheetBackground()
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

struct ScrollOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}
