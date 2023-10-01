//
//  UpdatedHistoryPagesView.swift
//  ShiftTracker
//
//  Created by James Poole on 23/09/23.
//

import SwiftUI
import Charts
import CoreData
import Haptics

// duplicated historypagesview due to a system bug (I think)

struct UpdatedHistoryPagesView: View {
    
    @Binding var navPath: NavigationPath
    
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var shiftStore: ShiftStore
    
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    @StateObject var historyModel = HistoryViewModel()
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var shifts: FetchedResults<OldShift>
    
    @State private var isLongPressDetected: Bool = false
    
    
    @State private var isOverlayEnabled: Bool = true
    
    
    
    var body: some View {
        
        ZStack(alignment: .bottomTrailing){
            ZStack(alignment: .bottomLeading){
                
                
                List(selection: $historyModel.selection) {
                    
                    Section {
                        ZStack(alignment: .topTrailing){
                            TabView(selection: $historyModel.selectedTab.animation(.default)) {
                                
                                ForEach(historyModel.groupedShifts.indices, id: \.self) { index in
                                    
                                    let dateRange = historyModel.getDateRange(startDate: historyModel.groupedShifts[index].startDate)
                                    let totalEarnings = historyModel.groupedShifts[index].shifts.reduce(0) { $0 + $1.totalPay }
                                    let totalHours = historyModel.groupedShifts[index].shifts.reduce(0) { $0 + ($1.duration / 3600.0) }
                                    let totalBreaks = historyModel.groupedShifts[index].shifts.reduce(0) { $0 + ($1.breakDuration / 3600.0) }
                                    
                                    
                                    
                                    VStack {
                                        HStack{
                                            VStack(alignment: .leading){
                                                Text("Total")
                                                    .font(.headline)
                                                    .bold()
                                                    .roundedFontDesign()
                                                    .foregroundColor(.gray)
                                                
                                                Text(
                                                    shiftManager.statsMode == .earnings ? "\(shiftManager.currencyFormatter.string(from: NSNumber(value: totalEarnings)) ?? "0")" :
                                                        shiftManager.statsMode == .hours ? shiftManager.formatTime(timeInHours: totalHours) :
                                                        shiftManager.formatTime(timeInHours: totalBreaks)
                                                )
                                                .font(.title2)
                                                .bold()
                                                
                                                
                                            }
                                            Spacer()
                                            
                                            
                                            
                                            
                                            
                                        }.padding(.top, 5)
                                            .opacity(historyModel.chartSelection == nil ? 1.0 : 0.0)
                                        
                                        let shifts = historyModel.groupedShifts[index].shifts
                                        
                                        // gotta do it this way, for some reason doing the check in the chartView fails and builds anyway for ios 16 causing a crash
                                        if #available(iOS 17.0, *){
                                            
                                            ChartView(dateRange: dateRange, shifts: shifts)
                                                .environmentObject(historyModel)
                                                .padding(.leading)
                                            
                                        } else {
                                            iosSixteenChartView(dateRange: dateRange, shifts: shifts)
                                                .environmentObject(historyModel)
                                                .padding(.leading)
                                        }
                                        
                                        
                                    } .padding(.horizontal)
                                        .tag(index)
                                    
                                    
                                    
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
                        .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                    
                    
                    Section {
                        
                        
                        if historyModel.groupedShifts.indices.contains(historyModel.selectedTab) {
                            ForEach(historyModel.groupedShifts[historyModel.selectedTab].shifts, id: \.objectID) { shift in
                                NavigationLink(value: shift) {
                                    ShiftDetailRow(shift: shift)
                                    
                                    
                                }
                                
                                .swipeActions {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            shiftStore.deleteOldShift(shift, in: viewContext)
                                            if let index = historyModel.groupedShifts[historyModel.selectedTab].shifts.firstIndex(of: shift) {
                                                historyModel.groupedShifts[historyModel.selectedTab].shifts.remove(at: index)
                                            }
                                            
                                            if historyModel.groupedShifts[historyModel.selectedTab].shifts.isEmpty {
                                                historyModel.groupedShifts.remove(at: historyModel.selectedTab)
                                                
                                                // changes the current tab if it empties
                                                if historyModel.selectedTab >= historyModel.groupedShifts.count {
                                                    historyModel.selectedTab = max(historyModel.groupedShifts.count - 1, 0)
                                                }
                                            }
                                        }
                                        
                                        // clear cached aggregate annotation values
                                        historyModel.clearCache()
                                        
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                
                            }
                        }
                        
                        
                    }
                    .listRowInsets(.init(top: 10, leading: jobSelectionViewModel.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
                    .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                    
                    
                    
                    
                }.scrollContentBackground(.hidden)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                
                    .background {
                        themeManager.overviewDynamicBackground.ignoresSafeArea()
                    }
                
                    .customSectionSpacing()
                
                
                PageControlView(currentPage: $historyModel.selectedTab, numberOfPages: historyModel.groupedShifts.count)
                    .frame(maxWidth: 175)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                
                    .padding()
                
                    .onChange(of: historyModel.selectedTab){ value in
                        print("Selected tab is \(value)")
                        //  print("count of grouped shifts for page control view: \(groupedShifts.count)")
                    }
                
                
            }
            
            
            
            
            VStack(alignment: .trailing){
                
                HStack(spacing: 10){
                    
                    EditButton()
                    
                    Divider().frame(height: 10)
                    
                    Button(action: {
                        CustomConfirmationAlert(action: deleteItems, cancelAction: nil, title: "Are you sure?").showAndStack()
                    }) {
                        Image(systemName: "trash")
                            .bold()
                        
                            .customAnimatedSymbol(value: $historyModel.selection)
                    }.disabled(historyModel.selection.isEmpty)
                        .tint(.red)
                    
                    
                    
                    
                    
                }.padding()
                    .glassModifier(cornerRadius: 20)
                
                //  .padding()
                
                CustomSegmentedPicker(selection: $historyModel.historyRange, items: HistoryRange.allCases)
                
                
                
                    .glassModifier(cornerRadius: 20)
                
                    .frame(width: 165)
                    .frame(maxHeight: 30)
                
                
                
                
                    .onChange(of: historyModel.historyRange) { value in
                        withAnimation{
                            
                            
                            
                            DispatchQueue.main.async {
                                
                                let groupedDictionary = Dictionary(grouping: shifts.filter({ shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) })) { shift in
                                    historyModel.getGroupingKey(for: shift)
                                }.sorted { $0.key < $1.key }
                                
                                historyModel.groupedShifts = historyModel.convertToGroupedShifts(from: groupedDictionary)
                                
                                historyModel.selectedTab = historyModel.groupedShifts.count - 1
                                
                                
                            }
                            
                            
                            
                            
                            
                        }
                    }
                
                
                Spacer().frame(height: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 75 : 55)
            }  .padding(.horizontal)
            
            
            
            
            
            
            
        }
        
        .onAppear {
            DispatchQueue.global(qos: .background).async {
                
                let shiftsEmpty = historyModel.groupedShifts.isEmpty
                // check if count of shifts has changed
                let totalShiftsInGrouped = historyModel.groupedShifts.reduce(0) { $0 + $1.shifts.count }
                let totalShiftsInFetchedResults = shifts.count
                
                if shiftsEmpty || totalShiftsInGrouped != totalShiftsInFetchedResults {
                    
                    // Possibly expensive operations
                    let filteredShifts = shifts.filter({ shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) })
                    let groupedDictionary = Dictionary(grouping: filteredShifts) { shift in
                        historyModel.getGroupingKey(for: shift)
                    }.sorted { $0.key < $1.key }
                    
                    let newGroupedShifts = historyModel.convertToGroupedShifts(from: groupedDictionary)
                    
                    // Switch back to the main queue to update UI
                    DispatchQueue.main.async {
                        historyModel.groupedShifts = newGroupedShifts
                        historyModel.selectedTab = historyModel.groupedShifts.count - 1
                        historyModel.clearCache()
                    }
                }
            }
        

            
          
        
            
            
            withAnimation {
                shiftManager.showModePicker = true
            }
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                if historyModel.groupedShifts.count < 1 {
                    dismiss()
                }
            }
            
            
        }
        
        
        
        
        .navigationTitle(historyModel.getCurrentDateRangeString())
        
        
    }
    
    
    private func deleteItems() {
        withAnimation {
            
            // for each shift selected
            for objectID in historyModel.selection {
                let itemToDelete = viewContext.object(with: objectID) as? OldShift
                
                // find which group the shift is in
                if let shift = itemToDelete, let groupIndex = historyModel.groupedShifts.firstIndex(where: { group in
                    return group.shifts.contains(where: { $0.objectID == objectID })
                }) {
                    
                    // remove the shift from the group
                    if let shiftIndex = historyModel.groupedShifts[groupIndex].shifts.firstIndex(of: shift) {
                        historyModel.groupedShifts[groupIndex].shifts.remove(at: shiftIndex)
                    }
                    
                    // if there are no more shifts in this group after deleting, remove the group
                    if historyModel.groupedShifts[groupIndex].shifts.isEmpty {
                        historyModel.groupedShifts.remove(at: groupIndex)
                    }
                }
                
                // delete the shift from core data
                if let item = itemToDelete {
                    viewContext.delete(item)
                }
            }
            
            do {
                try viewContext.save()
                historyModel.selection.removeAll()
                
                if historyModel.selectedTab >= historyModel.groupedShifts.count {
                    historyModel.selectedTab = max(historyModel.groupedShifts.count - 1, 0)
                }
                // if no shifts left, dismiss from this view
                if historyModel.groupedShifts.isEmpty {
                    dismiss()
                }
                // clear cached aggregate annotation values
                historyModel.clearCache()
                
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    
    
}



