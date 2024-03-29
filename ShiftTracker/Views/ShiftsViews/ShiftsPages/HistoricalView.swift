//
//  HistoricalView.swift
//  ShiftTracker
//
//  Created by James Poole on 23/09/23.
//

import SwiftUI
import Charts
import CoreData
import Haptics

struct HistoricalView: View {
    
    @State var editMode = EditMode.inactive
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject var shiftStore: ShiftStore
    
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var scrollManager: ScrollManager
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var overviewModel: JobOverviewViewModel
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    @EnvironmentObject var historyModel: HistoryViewModel
    
    @Binding var navPath: NavigationPath
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    
    init(navPath: Binding<NavigationPath>){
        
        _navPath = navPath
        
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "isActive == NO")
        
        
        
        _shifts = FetchRequest(fetchRequest: fetchRequest, animation: .default)
        
    }
    
    var body: some View {
        
        
        ZStack(alignment: .bottomTrailing){
            ScrollViewReader { proxy in
                
                List(selection: editMode.isEditing ? $historyModel.selection : .constant(Set<NSManagedObjectID>())) {
                    
                    chartSection.id(0)
                        .padding(.vertical, 10)
                        .glassModifier()
                        .padding(.horizontal)
                        .listRowSeparator(.hidden)
                    
                        .onDisappear {
                            scrollManager.timeSheetsScrolled = true
                        }
                        .onAppear {
                            scrollManager.timeSheetsScrolled = false
                        }
                    
                    // if any shifts are selected disable tab changing
                        .disabled(!historyModel.selection.isEmpty)
                    
                    shiftsSection
                    
                }.scrollContentBackground(.hidden)
                    .tint(Color.gray)
                    .listStyle(.plain)
                    .background {
                        // this could be worked into the themeManagers pure dark mode?
                        if colorScheme == .dark {
                            themeManager.overviewDynamicBackground.ignoresSafeArea()
                        } else {
                            Color.clear.ignoresSafeArea()
                        }
                    }
                
                    .customSectionSpacing()
                
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
            
            
            
            floatingButtons
            
        }
        
        
        .environment(\.editMode, $editMode)
        
        .overlay(alignment: .topTrailing){
            
            if let job = selectedJobManager.fetchJob(in: viewContext) {
                if historyModel.showLargeIcon {
                    
                    NavBarIconView(appeared: $historyModel.appeared, isLarge: $historyModel.showLargeIcon, job: job)
                        .padding(.trailing, 20)
                        .offset(x: 0, y: -55)
                    
                        .opacity(scrollManager.timeSheetsScrolled ? 0 : 1).animation(.easeInOut, value: scrollManager.timeSheetsScrolled)
                    
                    
                }
                
            }
        }
        
        .onAppear {
            
            fetchHistoricalAggregates(historyModel: historyModel, shifts: shifts, selectedJobManager: selectedJobManager, isAnimating: $historyModel.isAnimating)
            
            
            withAnimation {
                shiftManager.showModePicker = true
            }
            
            Task {
                try await Task.sleep(nanoseconds: 500_000_000)
                
                await MainActor.run {
                    historyModel.appeared = true
                    if historyModel.aggregatedShifts.count < 1 {
                        dismiss()
                    }
                }
                
            }
            
        }
        
        .navigationTitle(historyModel.selection.isEmpty ? historyModel.getCurrentDateRangeString() : "\(historyModel.selection.count) selected")
                                
        .navigationBarBackButtonHidden(editMode.isEditing)
        
        .toolbar(editMode.isEditing ? .hidden : .visible, for: .tabBar)
    
     .toolbar{
                if editMode.isEditing {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            
                            
                            
                            if historyModel.selection.isEmpty {
                                // add all current tabs shifts to the selection set
                                selectAllShiftsInCurrentTab()
                                
         
                            } else {
                                historyModel.selection = Set()
                            }
                            
                        }){
                            Text(historyModel.selection.isEmpty ? "Select All" : "Unselect All")
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
    
        .onChange(of: editMode.isEditing) { value in
            withAnimation {
            if value {
              
                    navigationState.hideTabBar = true
                    
                } else {
                    navigationState.hideTabBar = false
                }
            }
            
        }
        
        .sheet(isPresented: $historyModel.showExportView, onDismiss: {
            if historyModel.selection.count <= 1 {
                historyModel.selection = Set()
            }
        }) {
            
            ConfigureExportView(shifts: shifts, job: selectedJobManager.fetchJob(in: viewContext), selectedShifts: historyModel.selection)
                .presentationDetents([.large])
                .customSheetRadius(35)
                .customSheetBackground()
            
        }
        
        
        .sheet(isPresented: $historyModel.showInvoiceView, onDismiss: {
                if historyModel.selection.count <= 1 {
                    historyModel.selection = Set()
                }
                
                
            }) {
                GenerateInvoiceView(shifts: shifts, job: selectedJobManager.fetchJob(in: viewContext), selectedShifts: historyModel.selection)
                
                    .customSheetBackground()
                    .customSheetRadius(35)
            }
        
        
        
        .fullScreenCover(isPresented: $historyModel.showingProView) {
            ProView()
                .environmentObject(purchaseManager)
            
                .customSheetBackground()
        }
        
        /*   .toolbar {
         if !historyModel.showLargeIcon {
         
         if let job = selectedJobManager.fetchJob(in: viewContext) {
         
         if !historyModel.showLargeIcon {
         ToolbarItem(placement: .topBarTrailing) {
         
         NavBarIconView(appeared: $historyModel.appeared, isLarge: $historyModel.showLargeIcon, job: .constant(job)).frame(maxHeight: 25)
         
         
         }
         }
         }
         }
         }*/
    }
    
    private func selectAllShiftsInCurrentTab() {
        let shifts = historyModel.aggregatedShifts[historyModel.selectedTab].originalShifts
            historyModel.selection = Set(shifts.map { $0.objectID })
        }
    
    private func deleteItems() {
        withAnimation {
            
            // for each shift selected
            for objectID in historyModel.selection {
                let itemToDelete = viewContext.object(with: objectID) as? OldShift
                
                // find which group the shift is in
                if let shift = itemToDelete, let groupIndex = historyModel.aggregatedShifts.firstIndex(where: { group in
                    return group.originalShifts.contains(where: { $0.objectID == objectID })
                }) {
                    
                    withAnimation {
                        // remove the shift from the group
                        if let shiftIndex = historyModel.aggregatedShifts[groupIndex].originalShifts.firstIndex(of: shift) {
                            historyModel.aggregatedShifts[groupIndex].originalShifts.remove(at: shiftIndex)
                        }
                        
                        historyModel.updateAggregatedShift(afterDeleting: shift, at: historyModel.selectedTab)
                        
                        // if there are no more shifts in this group after deleting, remove the group
                        if historyModel.aggregatedShifts[groupIndex].originalShifts.isEmpty {
                            historyModel.aggregatedShifts.remove(at: groupIndex)
                        }
                        
                    }
                }
                
                // delete the shift from core data
                if let item = itemToDelete {
                    viewContext.delete(item)
                }
            }
            
            do {
                try viewContext.save()
                withAnimation {
                    historyModel.selection.removeAll()
                    
                    if historyModel.selectedTab >= historyModel.aggregatedShifts.count {
                        
                        historyModel.selectedTab = max(historyModel.aggregatedShifts.count - 1, 0)
                        
                    }
                    
                }
                // if no shifts left, dismiss from this view
                if historyModel.aggregatedShifts.isEmpty {
                    dismiss()
                }
                
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            
            editMode = .inactive
            
        }
    }
    
    var chartSection: some View {
        Section {
            ZStack(alignment: .topTrailing){
                TabView(selection: $historyModel.selectedTab.animation(.default)) {
                    
                    if !historyModel.isAnimating {
                        
                        
                        ForEach(historyModel.aggregatedShifts.indices, id: \.self) { index in
                            
                            let dateRange = historyModel.getDateRange(startDate: historyModel.aggregatedShifts[index].startDate)
                            
                            VStack {
                                HStack{
                                    VStack(alignment: .leading){
                                        Text("Total")
                                            .font(.headline)
                                            .bold()
                                            .roundedFontDesign()
                                            .foregroundColor(.gray)
                                        
                                        Text(
                                            shiftManager.statsMode == .earnings ? "\(shiftManager.currencyFormatter.string(from: NSNumber(value: historyModel.aggregatedShifts[index].totalEarnings)) ?? "0")" :
                                                shiftManager.statsMode == .hours ? shiftManager.formatTime(timeInHours: historyModel.aggregatedShifts[index].totalHours) :
                                                shiftManager.formatTime(timeInHours: historyModel.aggregatedShifts[index].totalBreaks)
                                        )
                                        .font(.title2)
                                        .bold()
                                        
                                        
                                    }
                                    Spacer()
                                    
                                    
                                    
                                    
                                    
                                }.padding(.top, 5)
                                    .opacity(historyModel.chartSelection == nil ? 1.0 : 0.0)
                                
                                let barMarks = historyModel.aggregatedShifts[index].dailyOrMonthlyAggregates
                                
                                // gotta do it this way, for some reason doing the check in the chartView fails and builds anyway for ios 16 causing a crash
                                if #available(iOS 17.0, *){
                                    
                                    ChartView(dateRange: dateRange, shifts: barMarks)
                                        .environmentObject(historyModel)
                                        .padding(.leading)
                                    
                                } else {
                                    iosSixteenChartView(dateRange: dateRange, shifts: barMarks)
                                        .environmentObject(historyModel)
                                        .padding(.leading)
                                }
                                
                                
                            } .padding(.horizontal)
                                .tag(index)

                        }
                        
                    } else {
                        ActivityIndicator(isAnimating: historyModel.isAnimating)
                    }
                    
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .haptics(onChangeOf: historyModel.selectedTab, type: .light)
                
                
                HStack(spacing: 20) {
                    
                    Button(action: {
                        historyModel.backButtonAction()
                    }){
                        Image(systemName: "chevron.left").bold()
                        
                            .font(.system(size: 26))
                            .customAnimatedSymbol(value: $historyModel.selectedTab)
                    }.buttonStyle(.plain)
                    
                    Button(action: {
                        historyModel.forwardButtonAction()
                    }){
                        Image(systemName: "chevron.right").bold()
                        
                            .font(.system(size: 26))
                            .customAnimatedSymbol(value: $historyModel.selectedTab)
                    }.buttonStyle(.plain)
                    
                    
                    
                }.padding()
                    .opacity(historyModel.chartSelection == nil ? 1.0 : 0.0)
                
                
            }
            
            
        }.frame(minHeight: 300)
            .listRowInsets(.init(top: 20, leading: 0, bottom: 20, trailing: 0))
            .listRowBackground(Color.clear)
        
    }
    
    var shiftsSection: some View {
        
        return Group {
            Section {
                
                if !historyModel.isAnimating {
                    if historyModel.aggregatedShifts.indices.contains(historyModel.selectedTab) {
                        let reversedIndices = Array(historyModel.aggregatedShifts[historyModel.selectedTab].originalShifts.indices.reversed())
                        let count = reversedIndices.count
                        ForEach(reversedIndices, id: \.self) { index in
                            let normalizedIndex = count - 1 - index
                            
                            let shift = historyModel.aggregatedShifts[historyModel.selectedTab].originalShifts[index]
                            let currentObjectID = shift.objectID
                            
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
                            
                            .id(normalizedIndex + 1)
                            .tag(currentObjectID)
                        }
                    }
                    
                } else {
                    ActivityIndicator(isAnimating: historyModel.isAnimating).frame(maxWidth: .infinity)
                }
                
                
            }
            .listRowInsets(.init(top: 10, leading: selectedJobManager.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
            .listRowBackground(Color.clear)
            
            Section {
                Spacer(minLength: 100).listRowSeparator(.hidden)
            }.listRowBackground(Color.clear)
            
        }
        
    }
    
    var floatingButtons: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack {
                Spacer()
            VStack(alignment: .trailing){
                
                HStack(spacing: 10){
                    
                    
                    if editMode.isEditing {
                        
                        Group {
                            
                            
                            Menu {
                                
                                
                                
                                Button(action: {
                                    
                                    if purchaseManager.hasUnlockedPro {
                                        historyModel.showExportView.toggle()
                                    } else {
                                        
                                        historyModel.showingProView.toggle()
                                        
                                    }
                                    
                                    
                                }){
                                    Text("Export to CSV")
                                    Image(systemName: "tablecells").bold()
                                }
                                
                                // allow invoices if not pro, just dont allow export
                                Button(action: {
                                    
                                  //  if purchaseManager.hasUnlockedPro {
                                        historyModel.showInvoiceView.toggle()
                                  //  } else {
                                        
                                   //     historyModel.showingProView.toggle()
                                        
                                   // }
                                    
                                    
                                }){
                                    Text("Generate Invoice or Timesheet")
                                    Image(systemName: "rectangle.and.paperclip").bold()
                                }.disabled(selectedJobManager.fetchJob(in: viewContext) == nil) // dont allow invoicing if no job is currently selected
                                
                            } label: {
                                
                                Image(systemName: "square.and.arrow.up").bold()
                                
                                
                            }.disabled(historyModel.selection.isEmpty)
                            
                           
                            
                            Divider().frame(height: 10)
                            
                            Button(action: {
                                CustomConfirmationAlert(action: deleteItems, cancelAction: nil, title: "Are you sure?").showAndStack()
                            }) {
                                Image(systemName: "trash")
                                    .bold()
                                
                                    .customAnimatedSymbol(value: $historyModel.selection)
                            }.disabled(historyModel.selection.isEmpty)
                                .tint(.red)
                            
                            Divider().frame(height: 10)
                            
                        }
                        .animation(.easeInOut, value: editMode.isEditing)
                    }
                    
                    CustomEditButton(editMode: $editMode, action: {
                        historyModel.selection.removeAll()
                    })
                    
                    
                    
                }.padding()
                    .glassModifier(cornerRadius: 20)
                    .padding(.trailing)
                //  .padding(.trailing, getRect().height == 667 ? 17 : 0)
                
                
                CustomSegmentedPicker(selection: $historyModel.historyRange, items: HistoryRange.allCases)
                
                    .glassModifier(cornerRadius: 20)
                
                
                    .frame(width: 165)
                    .frame(maxHeight: 30)
                    .padding(.trailing)
                
                    .disabled(editMode.isEditing)
                    .opacity(editMode.isEditing ? 0.5 : 1.0)
                
                    .onChange(of: historyModel.historyRange) { value in
                        scrollManager.timeSheetsScrolled = false
                        withAnimation {
                            historyModel.isAnimating = true
                        }
                        
                        Task {
                            
                            
                            let newAggregatedShifts = historyModel.generateAggregatedShifts(from: shifts, using: selectedJobManager)
                            await MainActor.run {
                                withAnimation {
                                    historyModel.aggregatedShifts = newAggregatedShifts
                                }
                            }
                            
                            
                            try await Task.sleep(nanoseconds: 300_000_000)
                            
                            
                            await MainActor.run {
                                historyModel.selectedTab = historyModel.aggregatedShifts.count - 1
                                withAnimation {
                                    historyModel.isAnimating = false
                                }
                            }
                            
                            
                            
                            
                        }
                        
                        
                    }
                //  .padding(.trailing, getRect().height == 667 ? 17 : 0)
                // this is random, this change appears to simply break the alignment... why is this here? 55 for both currently works fine
                // Spacer().frame(height: (getRect().height) == 667 || (getRect().height) == 736 ? 75 : 55)
              //  Spacer().frame(height: 55)
                
            }
            
            
        }.padding(.bottom, navigationState.hideTabBar ? 49 : 0).animation(.none, value: navigationState.hideTabBar)
            
            HStack(alignment: .bottom) {
                PageControlView(currentPage: $historyModel.selectedTab, numberOfPages: historyModel.aggregatedShifts.count)
                    .frame(maxWidth: 165)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                
                    .padding()
                
                    .onChange(of: historyModel.selectedTab){ value in
                        print("Selected tab is \(value)")
                        //  print("count of grouped shifts for page control view: \(groupedShifts.count)")
                    }
                
                // if any shifts are selected disable tab changing
                    .disabled(!historyModel.selection.isEmpty)
                    .opacity(!historyModel.selection.isEmpty ? 0.5 : 1.0)
                
                Spacer().frame(maxWidth: navigationState.hideTabBar ? 0 : .infinity)
                   // .padding(.bottom, navigationState.hideTabBar ? 49 : 0).animation(.none, value: navigationState.hideTabBar)
                
                
                
                
                
            }
            
        }
    }
    
    func deleteShift(_ shift: OldShift) {
        withAnimation {
            shiftStore.deleteOldShift(shift, in: viewContext)
            if let index = historyModel.aggregatedShifts[historyModel.selectedTab].originalShifts.firstIndex(of: shift) {
                historyModel.aggregatedShifts[historyModel.selectedTab].originalShifts.remove(at: index)
            }
            
            historyModel.updateAggregatedShift(afterDeleting: shift, at: historyModel.selectedTab)
            
            if historyModel.aggregatedShifts[historyModel.selectedTab].originalShifts.isEmpty {
                historyModel.aggregatedShifts.remove(at: historyModel.selectedTab)
                
                // changes the current tab if it empties
                if historyModel.selectedTab >= historyModel.aggregatedShifts.count {
                    historyModel.selectedTab = max(historyModel.aggregatedShifts.count - 1, 0)
                }
            }
        }
    }
    
    func duplicateShift(_ shift: OldShift) {
        overviewModel.selectedShiftToDupe = shift
        overviewModel.activeSheet = .addShiftSheet
    }
    
   
    func exportShift(_ shift: OldShift) {
        
        if purchaseManager.hasUnlockedPro {
            
            historyModel.selection = Set(arrayLiteral: shift.objectID)
            historyModel.showExportView.toggle()
            
        } else {
            historyModel.showingProView.toggle()
        }
    }
    
}

