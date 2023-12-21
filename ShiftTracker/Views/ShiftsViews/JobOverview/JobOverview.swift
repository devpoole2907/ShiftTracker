//
//  JobOverview.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI
import CoreData
import Haptics



struct JobOverview: View {
    
    @StateObject var overviewModel: JobOverviewViewModel
    @StateObject var historyModel: HistoryViewModel = HistoryViewModel()
    
    @EnvironmentObject var sortSelection: SortSelection
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var scrollManager: ScrollManager
    @EnvironmentObject var themeManager: ThemeDataManager
    
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    @FetchRequest var weeklyShifts: FetchedResults<OldShift>
    @FetchRequest var lastTenShifts: FetchedResults<OldShift>
    
    let shiftStore = ShiftStore()
    
    func generateTestData() {
        
        guard let selectedJob = selectedJobManager.fetchJob(in: viewContext) else { return }
        var currentDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        for _ in 0..<300 {
            let oldShift = OldShift(context: viewContext)
            
            let duration = Int.random(in: 2...12) * 3600
            let endDate = Calendar.current.date(byAdding: .second, value: duration, to: currentDate)!
            
            let hourlyPay = 30.0
            
            let totalPay = hourlyPay * Double(duration / 3600)
            
            oldShift.shiftStartDate = currentDate
            oldShift.shiftEndDate = endDate
            oldShift.duration = Double(duration)
            oldShift.hourlyPay = 30.0
            oldShift.totalPay = totalPay
            oldShift.taxedPay = totalPay * 0.9
            oldShift.tax = 0.1
            oldShift.totalTips = Double(Int.random(in: 5...48))
            oldShift.job = selectedJob
            oldShift.shiftID = UUID()
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    init(navPath: Binding<NavigationPath>, job: Job? = nil){
        print("job overview itself got reinitialised")
        
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        let weekFetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        let lastTenFetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        
        
        
        let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date().endOfDay) ?? Date()
        
        let weekFetchDatePredicate = NSPredicate(format: "shiftStartDate >= %@", oneWeekAgo as NSDate)
        
        if let jobID = job?.objectID {
            fetchRequest.predicate = NSPredicate(format: "job == %@", jobID)
            
            let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "job == %@", jobID), weekFetchDatePredicate])
            
            weekFetchRequest.predicate = compoundPredicate
            
            lastTenFetchRequest.predicate = NSPredicate(format: "job == %@", jobID)
            
            
        } else {
            weekFetchRequest.predicate = weekFetchDatePredicate
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        weekFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        lastTenFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        _shifts = FetchRequest(fetchRequest: fetchRequest)
        _weeklyShifts = FetchRequest(fetchRequest: weekFetchRequest)
        
        lastTenFetchRequest.fetchLimit = 10
        
        _lastTenShifts = FetchRequest(fetchRequest: lastTenFetchRequest)
        
        
        
        _navPath = navPath
        
        _overviewModel = StateObject(wrappedValue: JobOverviewViewModel(job: job))
        
        
        UITableView.appearance().backgroundColor = UIColor.clear
        
    }
    
    
    @Binding var navPath: NavigationPath
    
    var body: some View {
        
        
        
        ZStack(alignment: .bottomTrailing){
            
            List{
                
             
                    statsSection
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                
                if let theJob = selectedJobManager.fetchJob(in: viewContext) {
                    
                    if theJob.payPeriodEnabled {
                        
                        payPeriodSection
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        
                    }
                    
                    
                }
                
                recentShiftsSection
                    .onAppear {
                        scrollManager.timeSheetsScrolled = false
                    }
                
                
                
                
            }.scrollContentBackground(.hidden)
                .customSectionSpacing()
            
                .listStyle(.plain)
            
            
            
            floatingButtons
                .padding(.bottom, navigationState.hideTabBar ? 49 : 0).animation(.none, value: navigationState.hideTabBar)
            
            
        }.ignoresSafeArea(.keyboard)
        
            .navigationDestination(for: OldShift.self) { shift in
                DetailView(shift: shift, navPath: $navPath)
                
                    .onAppear {
                        withAnimation {
                            shiftManager.showModePicker = false
                        }
                    }
                
                
                
            }
        
            .navigationDestination(for: Int.self) { value in
                
                // lets do some rough code here, we will save the currently navigated to destination to an int
                
                
                
                if value == 1 {
                    
                    // Text("test")
                    
                    
                    
                    ShiftsList(navPath: $navPath).environmentObject(selectedJobManager).environmentObject(shiftManager).environmentObject(navigationState).environmentObject(sortSelection) .environmentObject(scrollManager).environmentObject(overviewModel)
                        .onAppear {
                            withAnimation {
                                shiftManager.showModePicker = false
                            }
                            overviewModel.navigationLocation = 1
                        }
                    
                    
                    
                } else if value == 2 {
                    HistoricalView(navPath: $navPath).environmentObject(overviewModel).environmentObject(historyModel)
                        .onAppear {
                            overviewModel.navigationLocation = 2
                        }
                } else if value == 3 {
                    
                    PayPeriodView(navPath: $navPath, job: selectedJobManager.fetchJob(in: viewContext)).environmentObject(overviewModel)
                    
                }
                
            }
        
            .sheet(item: $overviewModel.activeSheet, onDismiss: {
                // we dont need the current shift anymore
                
                overviewModel.selectedShiftToDupe = nil
                
                // god this is bad but hey, it works!
                
                if !navPath.isEmpty {
                    // if nav stack isnt empty, we have navigated somewhere
                    
                    if overviewModel.navigationLocation == 1 {
                        // if the nav location is 1, we must be in shiftslist so fetch the shifts again for the selection sorter
                        
                        withAnimation {
                            sortSelection.fetchShifts()
                            print("fetched new shifts for sort selector")
                        }
                        
                    }
                    
                    if overviewModel.navigationLocation == 2 {
                        
                        
                        // if the nav location is 2, we must be in historical view so reload the aggregates
                        
                        
                        fetchHistoricalAggregates(historyModel: historyModel, shifts: shifts, selectedJobManager: selectedJobManager, isAnimating: $historyModel.isAnimating)
                        print("reloaded aggregates for historical view")
                        
                    }
                }
                
                
                
            }) { sheet in
                
                switch sheet {
                    
                case .configureExportSheet:
                    
                    
                    
                    if overviewModel.job != nil {
                        
                        
                        ConfigureExportView(shifts: shifts, job: overviewModel.job)
                            .presentationDetents([.large])
                            .customSheetRadius(35)
                            .customSheetBackground()
                        
                    }
                    else {
                        ConfigureExportView(shifts: shifts)
                            .presentationDetents([.large])
                            .customSheetRadius(35)
                            .customSheetBackground()
                    }
                    
                    
                case .addShiftSheet:
                    
                    if overviewModel.job != nil {
                        
                        if let shift = overviewModel.selectedShiftToDupe {
                            NavigationStack{
                                DetailView(shift: shift, isDuplicating: true, presentedAsSheet: true)
                            }
                            
                            .presentationDetents([.large])
                            .customSheetBackground()
                            .customSheetRadius(35)
                            
                            
                            
                        } else {
                            
                            
                            NavigationStack{
                                DetailView(job: overviewModel.job, presentedAsSheet: true)
                            }
                            
                            .presentationDetents([.large])
                            .customSheetBackground()
                            .customSheetRadius(35)
                        }
                    } else {
                        Text("Error")
                    }
                    
                case .symbolSheet:
                    JobIconPicker()
                        .environmentObject(JobViewModel(job: overviewModel.job))
                        .environment(\.managedObjectContext, viewContext)
                        .presentationDetents([ .medium, .fraction(0.7)])
                        .presentationDragIndicator(.visible)
                        .customSheetBackground()
                        .customSheetRadius(35)
                    
                }
                
                
            }
            .onAppear {
                navigationState.gestureEnabled = true
                
                withAnimation {
                    shiftManager.showModePicker = true
                }
                
                overviewModel.appeared.toggle()
                
                
                
            }
        
        // adds icon to navigation title header
        
            .overlay(alignment: .topTrailing){
                
                // it'll always be hidden underneath the tab bar, for perf reasons i dont want a geo reader in this view anymore
                
                if overviewModel.showLargeIcon && overviewModel.job != nil && overviewModel.job?.name?.count ?? 0 <= 16 {
                    
                    NavBarIconView(appeared: $overviewModel.appeared, isLarge: $overviewModel.showLargeIcon, job: overviewModel.job!)
                        .padding(.trailing, 20)
                        .offset(x: 0, y: -55)
                    
                    
                }
            }
        
            .navigationTitle(overviewModel.job?.name ?? "Summary")
        
        
            .onChange(of: selectedJobManager.selectedJobUUID) { jobUUID in
                
                overviewModel.job = selectedJobManager.fetchJob(with: jobUUID, in: viewContext)
            }
        
            .onChange(of: scrollManager.timeSheetsScrolled) { change in
                
                print("scroll manager changed to: \(change)")
                
            }
        
            .fullScreenCover(isPresented: $overviewModel.isEditJobPresented) {
                JobView(job: overviewModel.job, isEditJobPresented: $overviewModel.isEditJobPresented, selectedJobForEditing: $overviewModel.job).environmentObject(ContentViewModel.shared)
                    .customSheetBackground()
                
            }
        
            .toolbar{
                
                
                ToolbarItem(placement: .topBarLeading){
                    Button{
                        withAnimation{
                            navigationState.showMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .bold()
                        
                    }
                }
                
                if overviewModel.job != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            generateTestData()
                        }){
                            Text("Test Data")
                        }
                    }
                }
                
                if !overviewModel.showLargeIcon && overviewModel.job != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavBarIconView(appeared: $overviewModel.appeared, isLarge: $overviewModel.showLargeIcon, job: overviewModel.job!).frame(maxHeight: 25)
                    }
                }
                
                ToolbarTitleMenu {
                    toolbarMenu
                }
                
                ToolbarItem(placement: .keyboard){
                    KeyboardDoneButton()
                }
                
                
            }
        
    }
    
    var recentShiftsSection: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        return Section{
            
            ZStack {
                NavigationLink(value: 1) { EmptyView() }.opacity(0.0)
                HStack {
                    Text("Latest Shifts")
                    
                        .foregroundStyle(textColor)
                        .padding(.leading, overviewModel.job != nil ? 4 : 8)
                        .font(.title2)
                        .bold()
                    
                    Image(systemName: "chevron.right")
                        .bold()
                        .foregroundStyle(.gray)
                    Spacer()
                } //This will be the view that you want to display to the user
            }
            
            ForEach(lastTenShifts, id: \.objectID) { shift in
                
                NavigationLink(value: shift) {
                    ShiftDetailRow(shift: shift)
                }
                
                .background(ContextMenuPreview(shift: shift, themeManager: themeManager, navigationState: navigationState, viewContext: viewContext, deleteAction: {
                    
                    withAnimation {
                        shiftStore.deleteOldShift(shift, in: viewContext)
                        shiftManager.shiftAdded.toggle()
                    }
                    
                }, duplicateAction: {
                    
                    overviewModel.selectedShiftToDupe = shift
                    
                    overviewModel.activeSheet = .addShiftSheet
                    
                }, action: {
                    navPath.append(shift)
                }))
                
                
                .swipeActions {
                    
                    Button(action: {
                        withAnimation {
                            shiftStore.deleteOldShift(shift, in: viewContext)
                            shiftManager.shiftAdded.toggle()
                        }
                    }){
                        Image(systemName: "trash")
                        
                        
                        
                    }.tint(.red)
                    
                    Button(action: {
                        
                        overviewModel.selectedShiftToDupe = shift
                        
                        
                        
                        
                        overviewModel.activeSheet = .addShiftSheet
                        
                        
                        
                    }){
                        Image(systemName: "plus.square.fill.on.square.fill")
                    }.tint(.gray)
                    
                    
                }
                
                
                
                .listRowInsets(.init(top: 10, leading: overviewModel.job != nil ? 20 : 10, bottom: 10, trailing: 20))
                
                
                
            }
            
            
        }
        
        .listRowBackground(Color.clear)
    }
    
    var floatingButtons: some View {
        VStack{
            
            HStack(spacing: 10){
                
                
                
                Button(action: {
                    withAnimation(.spring) {
                        overviewModel.activeSheet = .addShiftSheet
                    }
                }){
                    
                    Image(systemName: "plus").customAnimatedSymbol(value: $overviewModel.activeSheet)
                        .bold()
                    
                }.disabled(overviewModel.job == nil)
                
                
                
                
            }.padding()
                .glassModifier(cornerRadius: 20)
            
                .padding()
            
            Spacer().frame(height: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 50 : 40)
        }
    }
    
    var statsSection: some View {
        
        return Group {
            VStack(alignment: .center, spacing: 16){
                HStack(spacing: 8){
                    VStack(spacing: 0) {
                        
                        StatsSquare(shifts: shifts, shiftsThisWeek: weeklyShifts)
                            .environmentObject(shiftManager)
                        
                        
                        
                        Spacer()
                        
                        ChartSquare(shifts: weeklyShifts, statsMode: shiftManager.statsMode)
                            .environmentObject(shiftManager)
                        
                    }
                    
                    
                    ExportSquare(totalShifts: shifts.count, action: {
                        overviewModel.activeSheet = .configureExportSheet
                    })
                    .environmentObject(shiftManager)
 
                }

                
            }
            .frame(width: getRect().width - 44, height: 230)
            
            
            
        }   .textCase(nil)
        
        
        
    }
    
    var payPeriodSection: some View {
        NavigationLink(value: 3) {
            HStack {
                Image(systemName: "dollarsign.circle.fill").font(.largeTitle)
                VStack(alignment: .leading){
                    HStack {
                        Text("Pay Period").bold().font(.headline)
                        Divider().frame(height: 8)
                        Text("21/12/23 - 27/12/23")
                            .font(.caption)
                            .roundedFontDesign()
                            .foregroundStyle(.gray)
                    }
                    Text("$2632.43") .roundedFontDesign()
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                }
            }
        }
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .frame(width: getRect().width - 44)
            .glassModifier(cornerRadius: 12)
           
    }
    
    var toolbarMenu: some View {
        return Button(action: {
            overviewModel.isEditJobPresented.toggle()
        }){
            HStack {
                Text("Edit Job")
                Image(systemName: "pencil")
            }
        }.disabled(overviewModel.job == nil || ContentViewModel.shared.shift != nil)
    }
    
    
}


extension View {
    
    // this is bad code. I am not proud of it. But it will work to generate aggregates etc for shifts seperated by historical timelines
    
    @MainActor
    func fetchHistoricalAggregates(historyModel: HistoryViewModel,
                                   shifts: FetchedResults<OldShift>,
                                   selectedJobManager: JobSelectionManager,
                                   isAnimating: Binding<Bool>) {
        
        withAnimation {
            if historyModel.aggregatedShifts.isEmpty {
                isAnimating.wrappedValue = true
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
                if historyModel.selectedTab >= newAggregatedShifts.count || historyModel.selectedTab < 0 || !historyModel.appeared {
                    historyModel.selectedTab = newAggregatedShifts.count - 1
                    print("selected tab set to last one")
                }
                
                
                withAnimation {
                    
                    isAnimating.wrappedValue = false
                }
            }
            
        }
    }
}







