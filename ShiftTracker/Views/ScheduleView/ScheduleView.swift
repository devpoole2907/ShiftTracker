//
//  ScheduleView.swift
//  ShiftTracker
//
//  Created by James Poole on 28/04/23.
//

import SwiftUI
import Haptics
import UIKit
import CoreLocation
import MapKit
import CoreData


struct ScheduleView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    
    @EnvironmentObject var shiftManager: ShiftDataManager
    
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    @EnvironmentObject var shiftStore: ShiftStore
    
 
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Job.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]) private var jobs: FetchedResults<Job>
    
    @State private var showAddJobView = false
    
    @Binding var navPath: NavigationPath
    
    @State private var showCreateShiftSheet = false
    
    @State private var dateSelected: DateComponents? = Date().dateComponents
    @State private var displayEvents = false
    
    @State private var displayedOldShifts: [OldShift] = []
    
    @State private var deleteJobAlert = false
    @State private var jobToDelete: Job?
    
    @State private var activeSheet: ActiveSheet?
    
    @State private var shouldScrollToNextShift = false
    
    enum ActiveSheet: Identifiable {
        case pastShiftSheet, scheduleSheet
        
        var id: Int {
            hashValue
        }
    }
    
    @State private var showAllScheduledShiftsView = false
    
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    
    @FetchRequest var scheduledShifts: FetchedResults<ScheduledShift>
    
    @FetchRequest(
        sortDescriptors: ShiftSort.default.descriptors,
        animation: .default)
    private var allShifts: FetchedResults<OldShift>
    
    init(navPath: Binding<NavigationPath>){
        
        let fetchRequest: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledShift.startDate, ascending: true)]
        _scheduledShifts = FetchRequest(fetchRequest: fetchRequest)
        
        _dateSelected = State(initialValue: Date().startOfDay.dateComponents)

        _navPath = navPath
        
    }
    
    func fetchShifts() {
        let selectedDate = dateSelected?.date ?? Date()
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!
        withAnimation {
            displayedOldShifts = allShifts.filter { ($0.shiftStartDate! as Date) >= startOfDay && ($0.shiftStartDate! as Date) < endOfDay }
        }
    }
    
    
    
    
    
    var body: some View {
        
        ZStack(alignment: .bottomTrailing){
    
            List {
                let interval = DateInterval(start: .distantPast, end: .distantFuture)
                Section{
                    CalendarView(interval: interval, shiftStore: shiftStore, dateSelected: $dateSelected, displayEvents: $displayEvents)
                        .padding()
                        .tint(colorScheme == .dark ? .white.opacity(0.7) : nil)
                    
                } header: {
                    
                    Color.clear
                    
                }
                .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: -10, leading: 0, bottom: -10, trailing: 0))

                .onChange(of: dateSelected) { _ in
                    
                    fetchShifts()
                    
                }
                
                .onAppear {
                    
                    if dateSelected == nil {
                        print("Its nil")
                    }
                    
                    Task {
                        await scheduleModel.loadGroupedShifts(shiftStore: shiftStore, scheduleModel: scheduleModel)
                    }
                    
                    
                }
                
                ScheduledShiftsView(dateSelected: $dateSelected, navPath: $navPath, displayedOldShifts: $displayedOldShifts)
                    .environmentObject(shiftStore)
                    .environmentObject(scheduleModel)
                
                
                
                
            }.blur(radius: showAllScheduledShiftsView ? 2 : 0)
                .animation(.easeInOut(duration: 0.3), value: showAllScheduledShiftsView)
            
                .scrollContentBackground(.hidden)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
               
                .background {
                    
                 
                    Color.clear
                   
                }
            
      
            if showAllScheduledShiftsView {
                allScheduledShifts
            }
            
       floatingButtons
            
            
            
            
            
        }.onAppear {
            
            navigationState.gestureEnabled = true
            
            
            fetchShifts()
            
        }
        
        
        .navigationBarTitle("Schedule", displayMode: .inline)
        .toolbar{
            
            ToolbarItem(placement: .navigationBarLeading){
                Button{
                    withAnimation{
                        navigationState.showMenu.toggle()
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .bold()
                    
                }
            }
        }.haptics(onChangeOf: showAllScheduledShiftsView, type: .light)
        
        
            .sheet(item: $activeSheet){ item in
                
                switch item {
                case .scheduleSheet:
                    
                    CreateShiftForm(dateSelected: $dateSelected)
                    
                        .presentationDetents([.large])
                        .customSheetRadius(35)
                        .customSheetBackground()
                        .interactiveDismissDisabled()
                    
                    
                case .pastShiftSheet:
                    
                    NavigationStack{
                        DetailView(job: jobSelectionViewModel.fetchJob(in: viewContext)!, dateSelected: dateSelected, presentedAsSheet: true)
                    }
                    
                    .environmentObject(shiftManager)
                    .onDisappear {
                        
                        fetchShifts()
                        
                    }
                    
                    .presentationDetents([.large])
                    .customSheetRadius(35)
                    .customSheetBackground()
                    
                    
                }
            }
        
        
            .onAppear{
                
                shiftStore.deleteOldScheduledShifts(in: viewContext)
                
                DispatchQueue.main.async{
                    shiftStore.fetchShifts(from: scheduledShifts, and: allShifts, jobModel: jobSelectionViewModel)
                }
                
                print("selected job is \(jobSelectionViewModel.fetchJob(in: viewContext)?.name)")
                
                
                
            }
        
            .onReceive(jobSelectionViewModel.$selectedJobUUID){ _ in
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    withAnimation {
                        shiftStore.fetchShifts(from: scheduledShifts, and: allShifts, jobModel: jobSelectionViewModel)
                    }
                }
                
                print("Changed job")
                shiftStore.changedJob = jobSelectionViewModel.fetchJob(in: viewContext)
                
            }
        
        
        
    }
    
    var allScheduledShifts: some View {
        return
            AllScheduledShiftsView(navPath: $navPath)
                .animation(.easeInOut(duration: 1.0), value: showAllScheduledShiftsView)
                .onDisappear{
                    
                    
                    shouldScrollToNextShift = true
                    
                }
            
                .onAppear {
                    Task {
                        await scheduleModel.loadGroupedShifts(shiftStore: shiftStore, scheduleModel: scheduleModel)
                    }
                }
            
        
    }
    
    var floatingButtons: some View {
        return VStack{
            
            HStack(spacing: 10){
                
                if !showAllScheduledShiftsView {
                    
                    
                    
                    
                    let dateSelectedDate = dateSelected?.date ?? Date()
                    
                    if isBeforeEndOfToday(dateSelectedDate) && !Calendar.current.isDateInToday(dateSelectedDate) {
                        
                        // button to add previous shift
                        
                        Button(action: {
                            
                            if jobSelectionViewModel.selectedJobUUID == nil {
                                
                                
                                OkButtonPopup(title: "Select a job before adding a past shift.", action: { navigationState.showMenu.toggle() }).showAndStack()
                                
                                
                            } else {
                                
                                activeSheet = .pastShiftSheet
                                
                            }
                            
                            
                            
                            
                        }) {
                            
                            Image(systemName: "plus").customAnimatedSymbol(value: $activeSheet)
                                .bold()
                            
                        }
                        
                    }
                    else if Calendar.current.isDateInToday(dateSelectedDate) {
                        
                        
                        Menu {
                            Button(action: {
                                
                                
                                
                                
                                if jobSelectionViewModel.selectedJobUUID == nil {
                                    
                                    
                                    OkButtonPopup(title: "Select a job before scheduling a shift.", action: { navigationState.showMenu.toggle() }).showAndStack()
                                    
                                    
                                } else {
                                    
                                    activeSheet = .scheduleSheet
                                    
                                }
                                
                            }) {
                                
                                Text("Schedule Shift")
                                    .bold()
                                Image(systemName: "calendar.badge.clock")
                            }
                            
                            Button(action: {
                                
                                
                                
                                
                                if jobSelectionViewModel.selectedJobUUID == nil {
                                    
                                    
                                    OkButtonPopup(title: "Select a job before scheduling a shift.", action: { navigationState.showMenu.toggle() }).showAndStack()
                                    
                                    
                                } else {
                                    
                                    activeSheet = .pastShiftSheet
                                    
                                }
                                
                            }) {
                                
                                Text("Add Past Shift")
                                    .bold()
                                Image(systemName: "clock.arrow.circlepath")
                            }
                            
                            
                            
                            
                            
                            
                        } label: {
                            
                            Image(systemName: "plus")
                                .bold()
                            
                            
                        }.disabled(showAllScheduledShiftsView)
                        
                        
                        
                        
                        
                    }
                    
                    
                    else {
                        
                        // button to add future shift
                        
                        Button(action: {
                            
                            
                            
                            
                            if jobSelectionViewModel.selectedJobUUID == nil {
                                
                                
                                OkButtonPopup(title: "Select a job before scheduling a shift.", action: { navigationState.showMenu.toggle() }).showAndStack()
                                
                                
                            } else {
                                
                                activeSheet = .scheduleSheet
                                
                            }
                            
                        }) {
                            Image(systemName: "plus").customAnimatedSymbol(value: $activeSheet)
                                .bold()
                        }
                        .disabled(showAllScheduledShiftsView)
                        
                        
                        
                    }
                    
                    
                    Divider().frame(height: 10)
                    
                }
                
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        scheduleModel.shouldScrollToNextShift = true
                        showAllScheduledShiftsView.toggle()
                        
                    }
                }) {
                    Image(systemName: "list.bullet")
                        .customAnimatedSymbol(value: $showAllScheduledShiftsView)
                        .foregroundColor(showAllScheduledShiftsView ? (colorScheme == .dark ? .black : .white) : Color.accentColor)
                        .bold()
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(showAllScheduledShiftsView ? (colorScheme == .dark ? .white : .black) : .clear)
                                .padding(-5)
                        )
                }
                
                
                
                
                
                
                
            }.padding()
                .glassModifier(cornerRadius: 20)
            
                .padding()
        }
    }
    
    
    
}
