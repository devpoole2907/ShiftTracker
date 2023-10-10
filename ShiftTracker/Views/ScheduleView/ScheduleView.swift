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
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    @EnvironmentObject var shiftStore: ShiftStore

    @Binding var navPath: NavigationPath

    @FetchRequest(entity: Job.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]) private var jobs: FetchedResults<Job>
    @FetchRequest(
        sortDescriptors: ShiftSort.default.descriptors,
        animation: .default)
    private var allShifts: FetchedResults<OldShift>
    @FetchRequest var scheduledShifts: FetchedResults<ScheduledShift>
    
    init(navPath: Binding<NavigationPath>){
        
        let fetchRequest: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledShift.startDate, ascending: true)]
        _scheduledShifts = FetchRequest(fetchRequest: fetchRequest)

        _navPath = navPath
        
    }

    var body: some View {
        
        ZStack(alignment: .bottomTrailing){
    
            List {
               
                calendarSection
                
                ScheduledShiftsView(navPath: $navPath)
                    .environmentObject(shiftStore)
                    .environmentObject(scheduleModel)
                
                
                
                
            }.blur(radius: scheduleModel.showAllScheduledShiftsView ? 2 : 0)
                .animation(.easeInOut(duration: 0.3), value: scheduleModel.showAllScheduledShiftsView)
            
                .scrollContentBackground(.hidden)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
               
                .background {
                    
                 
                    Color.clear
                   
                }
            
      
            if scheduleModel.showAllScheduledShiftsView {
                allScheduledShifts
            }
            
       floatingButtons
            
            
            
            
            
        }.onAppear {
            
            navigationState.gestureEnabled = true
            
            
            scheduleModel.fetchShifts(allShifts: allShifts)
            
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
        }.haptics(onChangeOf: scheduleModel.showAllScheduledShiftsView, type: .light)
        
        
            .sheet(item: $scheduleModel.activeSheet){ item in
                
                switch item {
                case .scheduleSheet:
                    
                    CreateShiftForm(dateSelected: $scheduleModel.dateSelected)
                    
                        .presentationDetents([.large])
                        .customSheetRadius(35)
                        .customSheetBackground()
                        .interactiveDismissDisabled()
                    
                    
                case .pastShiftSheet:
                    
                    NavigationStack{
                        DetailView(job: selectedJobManager.fetchJob(in: viewContext)!, dateSelected: scheduleModel.dateSelected, presentedAsSheet: true)
                    }
                    
                    .environmentObject(shiftManager)
                    .onDisappear {
                        
                        scheduleModel.fetchShifts(allShifts: allShifts)
                        
                    }
                    
                    .presentationDetents([.large])
                    .customSheetRadius(35)
                    .customSheetBackground()
                    
                    
                }
            }
        
        
            .onAppear{
                
                shiftStore.deleteOldScheduledShifts(in: viewContext)
                
                DispatchQueue.main.async{
                    shiftStore.fetchShifts(from: scheduledShifts, and: allShifts, jobModel: selectedJobManager)
                }
                
                print("selected job is \(selectedJobManager.fetchJob(in: viewContext)?.name)")
                
                
                
            }
        
            .onReceive(selectedJobManager.$selectedJobUUID){ _ in
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    withAnimation {
                        shiftStore.fetchShifts(from: scheduledShifts, and: allShifts, jobModel: selectedJobManager)
                    }
                }
                
                print("Changed job")
                shiftStore.changedJob = selectedJobManager.fetchJob(in: viewContext)
                
            }
        
        
        
    }
    
    var calendarSection: some View {
        let interval = DateInterval(start: .distantPast, end: .distantFuture)
        return Section{
            CalendarView(interval: interval, shiftStore: shiftStore)
                .padding()
                .tint(colorScheme == .dark ? .white.opacity(0.7) : nil)
            
        } header: {
            
            Color.clear
            
        }
        .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
        .listRowSeparator(.hidden)
        .listRowInsets(.init(top: -10, leading: 0, bottom: -10, trailing: 0))

        .onChange(of: scheduleModel.dateSelected) { _ in
            
            scheduleModel.fetchShifts(allShifts: allShifts)
            
        }
        
        .onAppear {
 
            
            Task {
                await scheduleModel.loadGroupedShifts(shiftStore: shiftStore, scheduleModel: scheduleModel)
            }
            
            
        }
    }
    
    var allScheduledShifts: some View {
        return
            AllScheduledShiftsView(navPath: $navPath)
            .animation(.easeInOut(duration: 1.0), value: scheduleModel.showAllScheduledShiftsView)
                .onDisappear{
                    
                    
                    scheduleModel.shouldScrollToNextShift = true
                    
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
                
                if !scheduleModel.showAllScheduledShiftsView {
                    
                    
                    
                    
                    let dateSelectedDate = scheduleModel.dateSelected?.date ?? Date()
                    
                    if isBeforeEndOfToday(dateSelectedDate) && !Calendar.current.isDateInToday(dateSelectedDate) {
                        
                        // button to add previous shift
                        
                        Button(action: {
                            
                            if selectedJobManager.selectedJobUUID == nil {
                                
                                
                                OkButtonPopup(title: "Select a job before adding a past shift.", action: { navigationState.showMenu.toggle() }).showAndStack()
                                
                                
                            } else {
                                
                                scheduleModel.activeSheet = .pastShiftSheet
                                
                            }
                            
                            
                            
                            
                        }) {
                            
                            Image(systemName: "plus").customAnimatedSymbol(value: $scheduleModel.activeSheet)
                                .bold()
                            
                        }
                        
                    }
                    else if Calendar.current.isDateInToday(dateSelectedDate) {
                        
                        
                        Menu {
                            Button(action: {
                                
                                
                                
                                
                                if selectedJobManager.selectedJobUUID == nil {
                                    
                                    
                                    OkButtonPopup(title: "Select a job before scheduling a shift.", action: { navigationState.showMenu.toggle() }).showAndStack()
                                    
                                    
                                } else {
                                    
                                    scheduleModel.activeSheet = .scheduleSheet
                                    
                                }
                                
                            }) {
                                
                                Text("Schedule Shift")
                                    .bold()
                                Image(systemName: "calendar.badge.clock")
                            }
                            
                            Button(action: {
                                
                                
                                
                                
                                if selectedJobManager.selectedJobUUID == nil {
                                    
                                    
                                    OkButtonPopup(title: "Select a job before scheduling a shift.", action: { navigationState.showMenu.toggle() }).showAndStack()
                                    
                                    
                                } else {
                                    
                                    scheduleModel.activeSheet = .pastShiftSheet
                                    
                                }
                                
                            }) {
                                
                                Text("Add Past Shift")
                                    .bold()
                                Image(systemName: "clock.arrow.circlepath")
                            }
                            
                            
                            
                            
                            
                            
                        } label: {
                            
                            Image(systemName: "plus")
                                .bold()
                            
                            
                        }.disabled(scheduleModel.showAllScheduledShiftsView)
                        
                        
                        
                        
                        
                    }
                    
                    
                    else {
                        
                        // button to add future shift
                        
                        Button(action: {
                            
                            
                            
                            
                            if selectedJobManager.selectedJobUUID == nil {
                                
                                
                                OkButtonPopup(title: "Select a job before scheduling a shift.", action: { navigationState.showMenu.toggle() }).showAndStack()
                                
                                
                            } else {
                                
                                scheduleModel.activeSheet = .scheduleSheet
                                
                            }
                            
                        }) {
                            Image(systemName: "plus").customAnimatedSymbol(value: $scheduleModel.activeSheet)
                                .bold()
                        }
                        .disabled(scheduleModel.showAllScheduledShiftsView)
                        
                        
                        
                    }
                    
                    
                    Divider().frame(height: 10)
                    
                }
                
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        scheduleModel.shouldScrollToNextShift = true
                        scheduleModel.showAllScheduledShiftsView.toggle()
                        
                    }
                }) {
                    Image(systemName: "list.bullet")
                        .customAnimatedSymbol(value: $scheduleModel.showAllScheduledShiftsView)
                        .foregroundStyle(scheduleModel.showAllScheduledShiftsView ? (colorScheme == .dark ? .black : .white) : Color.accentColor)
                        .bold()
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(scheduleModel.showAllScheduledShiftsView ? (colorScheme == .dark ? .white : .black) : .clear)
                                .padding(-5)
                        )
                }
                
                
                
                
                
                
                
            }.padding()
                .glassModifier(cornerRadius: 20)
            
                .padding()
        }
    }
    
    
    
}
