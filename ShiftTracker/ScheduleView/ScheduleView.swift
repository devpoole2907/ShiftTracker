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
    
    @StateObject var savedPublisher = ShiftSavedPublisher() // need to look at this
    
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
        
        _dateSelected = State(initialValue: Date().dateComponents)
        
        
        
        
        let appearance = UINavigationBarAppearance()
        appearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        //  UINavigationBar.appearance().scrollEdgeAppearance = appearance
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
        
        NavigationStack(path: $navPath) {
            ZStack{
                if !showAllScheduledShiftsView{
                    // note for ios 17: there is a modifier that reduces this spacing
                    List {
                        let interval = DateInterval(start: .distantPast, end: .distantFuture)
                        Section{
                            CalendarView(interval: interval, shiftStore: shiftStore, dateSelected: $dateSelected, displayEvents: $displayEvents)
                                .padding()
                                .tint(colorScheme == .dark ? .white.opacity(0.7) : nil)
                            
                        } header: {
                            
                            Color.clear
                            
                        }
                        .listRowBackground(Color("SquaresColor"))
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: -10, leading: 10, bottom: -10, trailing: 10))
                        
                        
                        //
                        .onChange(of: dateSelected) { _ in
                       
                            fetchShifts()
                      
                        }
                        
                        .onAppear {
                            
                            if dateSelected == nil {
                                print("Its nil")
                            }
                            
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                                print("heres the fucking date before passing to create shift \(dateSelected?.date)")
                                
                            }
                        }
                        
                        ScheduledShiftsView(dateSelected: $dateSelected, navPath: $navPath, displayedOldShifts: $displayedOldShifts).environmentObject(savedPublisher)
                            .environmentObject(shiftStore)
                            .environmentObject(scheduleModel)
                        
                        
                        
                        
                    }.opacity(showAllScheduledShiftsView ? 0 : 1)
                        .animation(.easeInOut(duration: 1.0), value: showAllScheduledShiftsView)
                        .scrollContentBackground(.hidden)
                    // .listSectionSpacing(0) // iOS 17
                    
                } else {
                    AllScheduledShiftsView(navPath: $navPath).environmentObject(savedPublisher)
                        .opacity(showAllScheduledShiftsView ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0), value: showAllScheduledShiftsView)
                        .onDisappear{
                            
                            dateSelected = Date().dateComponents
                            
                        }
                    
                }
            }.onAppear {
                
                navigationState.gestureEnabled = true
                
                
                fetchShifts()
                
            }
            
            
            .navigationBarTitle("Schedule", displayMode: .inline)
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showAllScheduledShiftsView.toggle()
                        }
                    }) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(showAllScheduledShiftsView ? (colorScheme == .dark ? .black : .white) : Color.accentColor)
                            .bold()
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(showAllScheduledShiftsView ? (colorScheme == .dark ? .white : .black) : .clear)
                                    .padding(-5)
                            )
                    }    // .disabled(true)
                }
                ToolbarItem(placement: .navigationBarTrailing){
                    
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
                            
                            Image(systemName: "plus")
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
                            Image(systemName: "plus")
                                .bold()
                        }
                        .disabled(showAllScheduledShiftsView)
                        
                        
                        
                    }
                    
                    
                    
                }
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
                            .presentationCornerRadius(35)
                            .presentationBackground(colorScheme == .dark ? .black : .white)
                        
                        
                    case .pastShiftSheet:
                        
                        AddShiftView(job: jobSelectionViewModel.fetchJob(in: viewContext)!, dateSelected: dateSelected)
                            .environmentObject(shiftManager)
                            .onDisappear {
                                
                                fetchShifts()
                                
                            }
                        
                            .presentationDetents([.large])
                            .presentationCornerRadius(35)
                            .presentationBackground(colorScheme == .dark ? .black : .white)
                        
                        
                    }
                }
            
            
        }.onAppear{
            
            shiftStore.deleteOldScheduledShifts(in: viewContext)
            
            DispatchQueue.main.async{
                shiftStore.fetchShifts(from: scheduledShifts, and: allShifts, jobModel: jobSelectionViewModel)
            }
            
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
    
    
    
}
/*
 struct ScheduleView_Previews: PreviewProvider {
 static var previews: some View {
 ScheduleView()
 }
 }
 
 
 
 */
