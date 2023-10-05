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
    
    @State private var appeared: Bool = false
    
    @State private var showLargeIcon: Bool = true
    
    private func checkTitlePosition(geometry: GeometryProxy) {
        let minY = geometry.frame(in: .global).minY
        showLargeIcon = minY > 100  // adjust this threshold as needed
    }
    
    
    var body: some View {
        
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing){
                ZStack(alignment: .bottomLeading){
                    
                    
                    List(selection: $historyModel.selection) {
                        
                        Section {
                            ZStack(alignment: .topTrailing){
                                TabView(selection: $historyModel.selectedTab.animation(.default)) {
                                    
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
                                            
                                            let shifts = historyModel.aggregatedShifts[index].originalShifts
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
                            
                            
                            if historyModel.aggregatedShifts.indices.contains(historyModel.selectedTab) {
                                ForEach(historyModel.aggregatedShifts[historyModel.selectedTab].originalShifts, id: \.objectID) { shift in
                                    NavigationLink(value: shift) {
                                        ShiftDetailRow(shift: shift)
                                        
                                        
                                    }
                                    
                                    .swipeActions {
                                        Button(role: .destructive) {
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
                    
                    
                    PageControlView(currentPage: $historyModel.selectedTab, numberOfPages: historyModel.aggregatedShifts.count)
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
                    
                    CustomSegmentedPicker(selection: $historyModel.historyRange, items: HistoryRange.allCases)
                    
                    
                    
                        .glassModifier(cornerRadius: 20)
                    
                        .frame(width: 165)
                        .frame(maxHeight: 30)
                    
                    
                    
                    
                        .onChange(of: historyModel.historyRange) { value in
                            withAnimation{
                                
                                DispatchQueue.global(qos: .background).async {
                                    let newAggregatedShifts = historyModel.generateAggregatedShifts(from: shifts)
                                    DispatchQueue.main.async {
                                        historyModel.aggregatedShifts = newAggregatedShifts
                                     //   historyModel.selectedTab = historyModel.aggregatedShifts.count - 1
                                    }
                                   
                                }
                                
                                
                                
                                
                                
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                                withAnimation {
                                    historyModel.selectedTab = historyModel.aggregatedShifts.count - 1
                                }
                            }
                            
                        }
                    
                    
                    Spacer().frame(height: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 75 : 55)
                }  .padding(.horizontal)
                
                
                
                
                
                
                
            }
            
            .onChange(of: geo.frame(in: .global).minY) { minY in
                
                withAnimation {
                    checkTitlePosition(geometry: geo)
                }
            }
            
        }
        
        .overlay(alignment: .topTrailing){
            
            if let job = jobSelectionViewModel.fetchJob(in: viewContext) {
                let jobColor = Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue))
                if showLargeIcon {
                    
                    
                    
                    NavBarIconView(appeared: $appeared, isLarge: $showLargeIcon, icon: job.icon ?? "", color: jobColor)
                        .padding(.trailing, 20)
                        .offset(x: 0, y: -55)
                    
                    
                }
                
            }
        }
        
        .onAppear {
            
            // this is bad code. I am not proud of it. But it will work.
            
            if shiftManager.showModePicker == false {
                // we must have been in detail view if its false.
                
                
                DispatchQueue.global(qos: .background).async {
                    
                    let newAggregatedShifts = historyModel.generateAggregatedShifts(from: shifts)
                    
                    DispatchQueue.main.async {
                        withAnimation {
                            historyModel.aggregatedShifts = newAggregatedShifts
                            
                        }
                                
                    }
                }
            }
            
            appeared.toggle()
            
            if historyModel.lastKnownShiftCount != shifts.count {
                
                historyModel.lastKnownShiftCount = shifts.count
                
                DispatchQueue.global(qos: .background).async {
                    
                    let newAggregatedShifts = historyModel.generateAggregatedShifts(from: shifts)
                    
                    DispatchQueue.main.async {
                        withAnimation {
                            historyModel.aggregatedShifts = newAggregatedShifts
                            
                        }
                        historyModel.selectedTab = historyModel.aggregatedShifts.count - 1
                    }
                }
                
            }

            withAnimation {
                shiftManager.showModePicker = true
            }
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                if historyModel.aggregatedShifts.count < 1 {
                    dismiss()
                }
            }
            
            
        }
        
        
        
        
        .navigationTitle(historyModel.getCurrentDateRangeString())
        
        .toolbar {
            if !showLargeIcon {
                
                if let job = jobSelectionViewModel.fetchJob(in: viewContext) {
                    let jobColor = Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue))
                    let jobIcon = job.icon ?? "briefcase"
                    
                    if !showLargeIcon {
                        ToolbarItem(placement: .topBarTrailing) {
                            
                            NavBarIconView(appeared: $appeared, isLarge: $showLargeIcon, icon: jobIcon, color: jobColor).frame(maxHeight: 25)
                            
                            
                        }
                    }
                }
            }
        }
        
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
        }
    }
    
    
    
}



