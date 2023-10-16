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
    
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var shiftStore: ShiftStore
    
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var scrollManager: ScrollManager
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    @StateObject var historyModel = HistoryViewModel()
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var shifts: FetchedResults<OldShift>
    
    @State var isAnimating = false
    
    var body: some View {
        
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing){
                ZStack(alignment: .bottomLeading){
                    ScrollViewReader { proxy in
                        List(selection: $historyModel.selection) {
                            
                            chartSection.id(0)
                            // if we are editing, disable tab changing
                                .disabled((editMode?.wrappedValue.isEditing ?? true))
                               
                            shiftsSection .background {
                                Color.clear.preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).minY)
                            }
                            
                        }.scrollContentBackground(.hidden)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                        
                            .background {
                                themeManager.overviewDynamicBackground.ignoresSafeArea()
                            }
                        
                            .customSectionSpacing()
                        
                            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                                if !(offset <= 0) && !scrollManager.timeSheetsScrolled {
                                    print("offset is \(offset)")
                                    scrollManager.timeSheetsScrolled = true
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

                    PageControlView(currentPage: $historyModel.selectedTab, numberOfPages: historyModel.aggregatedShifts.count)
                        .frame(maxWidth: 175)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                    
                        .padding()
                    
                        .onChange(of: historyModel.selectedTab){ value in
                            print("Selected tab is \(value)")
                            //  print("count of grouped shifts for page control view: \(groupedShifts.count)")
                        }
                    // if we are editing, disable tab changing
                        .disabled((editMode?.wrappedValue.isEditing ?? true))

                }

                VStack(alignment: .trailing){
                    
                    HStack(spacing: 10){
                        
                        EditButton()
                        
                        Divider().frame(height: 10)
                        
                        Button(action: {
                            
                            if purchaseManager.hasUnlockedPro {
                                historyModel.showExportView.toggle()
                            } else {
                                
                                historyModel.showingProView.toggle()
                                
                            }
                            
                           
                        }){
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
                        
                    }.padding()
                        .glassModifier(cornerRadius: 20)
                    
                    CustomSegmentedPicker(selection: $historyModel.historyRange, items: HistoryRange.allCases)

                        .glassModifier(cornerRadius: 20)
                    
                        .frame(width: 165)
                        .frame(maxHeight: 30)
                    
                        .disabled(editMode?.wrappedValue.isEditing ?? false)
                        .opacity(editMode!.wrappedValue.isEditing ? 0.5 : 1.0)

                        .onChange(of: historyModel.historyRange) { value in
                            scrollManager.timeSheetsScrolled = false
                            withAnimation {
                                self.isAnimating = true
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
                                                    self.isAnimating = false
                                                }
                                            }
                                        
                                    
                                
                                
                            }
                      
                            
                        }
                    
                    Spacer().frame(height: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 75 : 55)
                }  .padding(.horizontal)

            }
            
            .onChange(of: geo.frame(in: .global).minY) { minY in
                
                withAnimation {
                    historyModel.checkTitlePosition(geometry: geo)
                }
            }
            
        }
        
        .overlay(alignment: .topTrailing){
            
            if let job = selectedJobManager.fetchJob(in: viewContext) {
                if historyModel.showLargeIcon {

                    NavBarIconView(appeared: $historyModel.appeared, isLarge: $historyModel.showLargeIcon, job: job)
                        .padding(.trailing, 20)
                        .offset(x: 0, y: -55)
                    
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                scrollManager.timeSheetsScrolled = false
                            }
                        }

                }
                
            }
        }
        
        .onAppear {
            
            
            // this is bad code. I am not proud of it. But it will work.
            
            withAnimation {
                if historyModel.aggregatedShifts.isEmpty {
                    // only appear to load if its the first time loading the aggregated shifts
                    self.isAnimating = true
                }
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
                                if historyModel.selectedTab >= newAggregatedShifts.count || historyModel.selectedTab < 0 || historyModel.appeared == false {
                                    historyModel.selectedTab = newAggregatedShifts.count - 1
                                    
                                    
                                    print("selected tab set to last one")
                                }
                                withAnimation {
                                    self.isAnimating = false
                                }
                            }
                        
                    
                
                
            }
            

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
        
        .navigationTitle(historyModel.getCurrentDateRangeString())
        
        .sheet(isPresented: $historyModel.showExportView) {
            
            ConfigureExportView(shifts: shifts, job: selectedJobManager.fetchJob(in: viewContext), selectedShifts: historyModel.selection)
                .presentationDetents([.large])
                .customSheetRadius(35)
                .customSheetBackground()
        
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
    
    var chartSection: some View {
        Section {
            ZStack(alignment: .topTrailing){
                TabView(selection: $historyModel.selectedTab.animation(.default)) {
                    
                    if !isAnimating {
                    
                    
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
                        
                        
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    scrollManager.timeSheetsScrolled = false
                                }
                            }
                        
                        
                        
                    }
                    
                    } else {
                        ActivityIndicator(isAnimating: isAnimating)
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
        
    }
    
    var shiftsSection: some View {
        
        return Group {
            Section {
                
                if !isAnimating {
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
                        
                       .swipeActions {
                         
                            
                            Button(action: {
                                
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
                                
                            }){
                                Image(systemName: "trash")
                            }
                            
                            .tint(.clear)
                            
                            
                            
                        }
                        
                        .id(normalizedIndex + 1)
                        .tag(currentObjectID)
                    }
                }
                
                } else {
                    ActivityIndicator(isAnimating: isAnimating).frame(maxWidth: .infinity)
                }
            
            
        }
        .listRowInsets(.init(top: 10, leading: selectedJobManager.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
        .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
        
        Section {
            Spacer(minLength: 100)
        }.listRowBackground(Color.clear)
        
    }
        
    }
    
}



