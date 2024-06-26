//
//  JobOverview.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI
import CoreData
import Haptics
import UIKit



struct JobOverview: View {
    
    @StateObject var overviewModel: JobOverviewViewModel
    @StateObject var historyModel: HistoryViewModel = HistoryViewModel()
    @StateObject var payPeriodManager: PayPeriodManager = PayPeriodManager()
    
    @EnvironmentObject var purchaseManager: PurchaseManager
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
    
    @FetchRequest(entity: PayPeriod.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \PayPeriod.startDate, ascending: false)])
    var payPeriods: FetchedResults<PayPeriod>
    
    @FetchRequest(
            entity: OldShift.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        ) var testShifts: FetchedResults<OldShift>
    
    @State private var refreshPayPeriodID = UUID()
    @State private var lastViewedDate = Date()
    
    
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
            
            oldShift.breakDuration = 3600
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    init(navPath: Binding<NavigationPath>, job: Job? = nil) {
        print("job overview itself got reinitialised")
        
        let excludeActiveShiftPredicate = NSPredicate(format: "isActive == NO")
        
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        let weekFetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        let lastTenFetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        
        let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date().endOfDay) ?? Date()
        let weekFetchDatePredicate = NSPredicate(format: "shiftStartDate >= %@", oneWeekAgo as NSDate)
        
        var predicates: [NSPredicate] = [excludeActiveShiftPredicate]
        if let jobID = job?.objectID {
            predicates.append(NSPredicate(format: "job == %@", jobID))
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        predicates.append(weekFetchDatePredicate)
        weekFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        if let jobObjectId = job?.objectID {
            
            lastTenFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [excludeActiveShiftPredicate, NSPredicate(format: "job == %@", jobObjectId)])
            
        } else {
            lastTenFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [excludeActiveShiftPredicate])
        }
        
   
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        weekFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        lastTenFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        lastTenFetchRequest.fetchLimit = 10
        
        _shifts = FetchRequest(fetchRequest: fetchRequest)
        _weeklyShifts = FetchRequest(fetchRequest: weekFetchRequest)
        _lastTenShifts = FetchRequest(fetchRequest: lastTenFetchRequest)
        
        _navPath = navPath
        _overviewModel = StateObject(wrappedValue: JobOverviewViewModel(job: job))
        
        UITableView.appearance().backgroundColor = UIColor.clear
    }

    
    
    @Binding var navPath: NavigationPath
    
    var body: some View {
        
        
        
        ZStack(alignment: .bottomTrailing){
            
            List{
                
             /*   ForEach(testShifts, id: \.shiftID) { shift in
                    
                    ShiftDetailRow(shift: shift)
                    
                }*/
                
                
                statsSection
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                
                
                recentShiftsSection
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            scrollManager.timeSheetsScrolled = false
                        }
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
        
            .navigationDestination(for: PayPeriod.self) { payPeriod in
                
                // display list of all shifts in that pay period
                
                if let job = selectedJobManager.fetchJob(in: viewContext) {
                    
                    PayPeriodShiftsList(payPeriod: payPeriod, navPath: $navPath, job: job).environmentObject(overviewModel)
                    
                } else {
                    Text("Error")
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
                    
                    
                    if let job = selectedJobManager.fetchJob(in: viewContext) {
                        PayPeriodsList(job: job).environmentObject(payPeriodManager)
                    } else {
                        Text("Error")
                    }
                    
                    
                    // doing this here causes the weirdest visual bug!
                    /*
                     onAppear {
                     withAnimation {
                     shiftManager.showModePicker = false
                     }
                     }*/
                    
                } else if value == 4 {
                    
                    
                    
                    InvoicesListView(job: selectedJobManager.fetchJob(in: viewContext)).environmentObject(selectedJobManager).environmentObject(overviewModel)
                        .onAppear {
                            withAnimation {
                                shiftManager.showModePicker = false
                            }
                        }
                    
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
                // empty set value
                overviewModel.shiftForExport = nil
                overviewModel.shiftSelectionForExport = nil
                
                
            }) { sheet in
                
                switch sheet {
                    
                case .configureExportSheet:
                    
                    
                    
                    
                    
                    if overviewModel.job != nil {
                        
                        
                        ConfigureExportView(shifts: shifts, job: overviewModel.job, selectedShifts: overviewModel.shiftSelectionForExport, singleExportShift: overviewModel.shiftForExport)
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
                    
                   
                        
                        if let shift = overviewModel.selectedShiftToDupe {
                            NavigationStack{
                                DetailView(shift: shift, isDuplicating: true, presentedAsSheet: true)
                            }
                            
                            .presentationDetents([.large])
                            .customSheetBackground()
                            .customSheetRadius(35)
                            
                            
                            
                        } else if overviewModel.job != nil {
                            
                            
                            NavigationStack{
                                DetailView(job: overviewModel.job, presentedAsSheet: true)
                            }
                            
                            .presentationDetents([.large])
                            .customSheetBackground()
                            .customSheetRadius(35)
                        }
                        
                        else {
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
                
             // update all pay periods
                    payPeriodManager.updatePayPeriods(using: viewContext)
                
                
                
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
                
                if let job = selectedJobManager.fetchJob(in: viewContext) {
                    
                    payPeriodManager.updatePayPeriods(using: viewContext, for: job)
                    
                }
            }
        
            .onChange(of: scrollManager.timeSheetsScrolled) { change in
                
                print("scroll manager changed to: \(change)")
                
            }
        
            .fullScreenCover(isPresented: $overviewModel.isEditJobPresented) {
                JobView(job: overviewModel.job, isEditJobPresented: $overviewModel.isEditJobPresented, selectedJobForEditing: $overviewModel.job).environmentObject(ContentViewModel.shared)
                    .customSheetBackground()
                
            }
        
            .fullScreenCover(isPresented: $overviewModel.showProView) {
                ProView()
                    .environmentObject(purchaseManager)
                
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
                
                .background {
                    
                    let deleteUIAction = UIAction(title: "Delete", image: UIImage(systemName: "trash.fill"), attributes: .destructive) { action in
                        
                        
                        
                        deleteShift(shift)
                        
                    }
                    
                    let duplicateUIAction = UIAction(title: "Duplicate", image: UIImage(systemName: "plus.square.fill.on.square.fill")) { action in
                        duplicateShift(shift)
                    }
                    
                    let shareUIAction = UIAction(title: "Export", image: UIImage(systemName: "square.and.arrow.up.fill")) { _ in
                        
                        exportShift(shift)
                        
                    }
                    
                    
                    
                    ContextMenuPreview(shift: shift, themeManager: themeManager, navigationState: navigationState, viewContext: viewContext, actionsArray: [deleteUIAction, duplicateUIAction, shareUIAction], action: {
                        navPath.append(shift)
                    })
                    
                    
                }
                
                
                
                
                .swipeActions {
                    
                    OldShiftSwipeActions(deleteAction: {
                        deleteShift(shift)
                    }, duplicateAction: {
                        duplicateShift(shift)
                    })
                    
                    
                    
                }
                
                .swipeActions(edge: .leading) {
                    Button(action: {
                        exportShift(shift)
                    }){
                        Image(systemName: "square.and.arrow.up.fill")
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
            VStack(alignment: .center, spacing: 8){
                HStack(spacing: 8){
                    VStack(spacing: 8) {
                        
                        StatsSquare(shifts: shifts, shiftsThisWeek: weeklyShifts)
                            .environmentObject(shiftManager)
                        
                        
                        ChartSquare(shifts: weeklyShifts, statsMode: shiftManager.statsMode, navPath: $navPath)
                            .environmentObject(shiftManager)
                        
                        
                    }
                    
                    VStack(spacing: 8) {
                        ExportSquare(totalShifts: shifts.count, action: {
                            overviewModel.activeSheet = .configureExportSheet
                        })
                        .environmentObject(shiftManager)
                        
                        
                        if let theJob = selectedJobManager.fetchJob(in: viewContext) {
                            if theJob.enableInvoices {
                                invoicesSection
                            }
                        } else { // no job selected, show all invoices anyway if any
                            invoicesSection
                        }
                        
                        
                        
                    }
                } .frame(height: 230)
                
                if let theJob = selectedJobManager.fetchJob(in: viewContext), theJob.payPeriodEnabled {
                    
                    
                    
                    
                    payPeriodSection
                        .id(refreshPayPeriodID)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    
                        .onAppear {
                            
                            lastViewedDate = Date()
                            
                        }
                    
                    
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                            
                            let threshold: TimeInterval = 24 * 60 * 60
                            
                            if Date().timeIntervalSince(lastViewedDate) > threshold {
                                // The app was in the background for a long time, force refresh of pay period view
                                refreshPayPeriodID = UUID()
                            }
                        }
                    
                    
                    
                    
                }
                
            }
            //
            
            
            
            
            
        }   .textCase(nil)
        
        
        
    }
    
    var payPeriodSection: some View {
        
        // making this a button fixes the strange visual bug since we can hide the mode picker here
        
        Button(action: {
            
            navPath.append(3)
            
            withAnimation {
                shiftManager.showModePicker = false
            }
            
            
        }) {
            
            if let job = selectedJobManager.fetchJob(in: viewContext), let payPeriod = job.payPeriods?.allObjects.first {
                
                PayPeriodSectionView(payPeriod: payPeriod as? PayPeriod, job: job).environmentObject(overviewModel)
            } else {
                PayPeriodSectionView().environmentObject(overviewModel)
            }
            
            
        }.buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
        // .frame(width: getRect().width - 44)
            .glassModifier(cornerRadius: 12, applyPadding: false)
        
        
        
        
    }
    
    var invoicesSection: some View {
        
        let headerColor: Color = colorScheme == .dark ? .white : .black
        
        return Button(action: {
            navPath.append(4)
        }){
            HStack(spacing: 5){
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Invoices &")
                    Text("Timesheets")
                }
                
                .font(.callout)
                .bold()
                .foregroundStyle(headerColor)
                .padding(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .bold()
                
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                
                    .padding(.trailing, 27)
                
                //   Spacer()
                
            }
            //.padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
        
            .frame(maxHeight: .infinity)
        
        
        
            .glassModifier(cornerRadius: 12, applyPadding: false)
        
        
        
        
    }
    
    var toolbarMenu: some View {
        return Button(action: {
            overviewModel.isEditJobPresented.toggle()
        }){
            HStack {
                Text("Edit Job")
                Image(systemName: "pencil")
            }
        }.disabled(overviewModel.job == nil || ContentViewModel.shared.currentShift != nil)
    }
    
    func deleteShift(_ shift: OldShift) {
        withAnimation {
            shiftStore.deleteOldShift(shift, in: viewContext)
            shiftManager.shiftAdded.toggle()
        }
    }
    
    func duplicateShift(_ shift: OldShift) {
        overviewModel.selectedShiftToDupe = shift
        overviewModel.activeSheet = .addShiftSheet
    }
    
    
    
    func exportShift(_ shift: OldShift) {
        
        if purchaseManager.hasUnlockedPro {
            
            overviewModel.shiftForExport = shift
            overviewModel.activeSheet = .configureExportSheet
            
        } else {
            overviewModel.showProView.toggle()
        }
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








