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
    
    @EnvironmentObject var sortSelection: SortSelection
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var scrollManager: ScrollManager
    
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
            
            oldShift.shiftStartDate = currentDate
            oldShift.shiftEndDate = endDate
            oldShift.duration = Double(duration)
            oldShift.totalPay = Double.random(in: 100...300)
            oldShift.taxedPay = oldShift.totalPay * 0.9
            oldShift.tax = 0.1
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
        
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing){
           
                    List{
                        
                        
                        
                        recentShiftsSection
                            .onAppear {
                                scrollManager.timeSheetsScrolled = false
                            }
                 
                        
                        
                    }.scrollContentBackground(.hidden)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                        .customSectionSpacing()
                    
                     
                    
                
                
                floatingButtons
                
                .onChange(of: geo.frame(in: .global).minY) { minY in
                    
                    withAnimation {
                        overviewModel.checkTitlePosition(geometry: geo)
                    }
                }
                
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
                
                if value == 1 {
                    ShiftsList(navPath: $navPath).environmentObject(selectedJobManager).environmentObject(shiftManager).environmentObject(navigationState).environmentObject(sortSelection) .environmentObject(scrollManager)
                        .onAppear {
                            withAnimation {
                                shiftManager.showModePicker = false
                            }
                        }
                    
                } else if value == 2 {
                    HistoricalView()
                }
                
            }
            
        }
        .sheet(item: $overviewModel.activeSheet) { sheet in
            
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
                    
                    
                    
                    NavigationStack{
                        DetailView(job: overviewModel.job, presentedAsSheet: true)
                    }
                    
                    .presentationDetents([.large])
                    .customSheetBackground()
                    .customSheetRadius(35)
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
            
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    generateTestData()
                }){
                    Text("Test Data")
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
        
      
        
        return Section{
            
            ForEach(lastTenShifts, id: \.objectID) { shift in
                
                NavigationLink(value: shift) {
                    ShiftDetailRow(shift: shift)
                }
                
            
       
                
                .swipeActions {
                    
                    Button(action: {
                        withAnimation {
                            shiftStore.deleteOldShift(shift, in: viewContext)
                            shiftManager.shiftAdded.toggle()
                        }
                    }){
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                        
                        
                    }.tint(.clear)
                    
                    
                }
                
            
            
                .listRowInsets(.init(top: 10, leading: overviewModel.job != nil ? 20 : 10, bottom: 10, trailing: 20))
                
                
                
            }
            
            
        } header: {
            
            statsSection
                .frame(maxWidth: .infinity)
            
          
        
            
            
            
            
        }
        
        .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
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
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
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
                
                
                
                
            }.frame(width: getRect().width - 44)
            
            
            NavigationLink(value: 1) {
                
                Text("Latest Shifts")
                 
                    .foregroundStyle(textColor)
                    .padding(.leading, overviewModel.job != nil ? 4 : 8)
                    .font(.title2)
                    .bold()
                
                Image(systemName: "chevron.right")
                    .bold()
                    .foregroundStyle(.gray)
                Spacer()
                
            }
            
        }
            .frame(height: 250)
      

        
    }   .textCase(nil)
        
        
        
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


