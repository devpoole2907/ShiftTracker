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
        sortDescriptors: ShiftSort.sorts[1].descriptors, predicate: NSPredicate(format: "isActive == NO"),
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
                
                ScheduledShiftsView(navPath: $navPath, allShifts: allShifts, selectedDate: scheduleModel.dateSelected?.date, selectedJobManager: selectedJobManager)
                    .environmentObject(shiftStore)
                    .environmentObject(scheduleModel)
                
                
                
                
            }.listStyle(.plain)
                .scrollContentBackground(.hidden)
                //.shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
               
                .background {
                    
                 
                    Color.clear
                   
                }
            
  
       floatingButtons.padding(.bottom, navigationState.hideTabBar ? 49 : 0).animation(.none, value: navigationState.hideTabBar)
            
            
            
            
            
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
        }
        
        
        .sheet(item: $scheduleModel.activeSheet, onDismiss: {
            
            // we dont need the shift to duplicate anymore
            
            scheduleModel.selectedShiftToDupe = nil
            
            // we dont need the shift to export anymore
            scheduleModel.shiftForExport = nil
            
          
                    
                
                    
                
        
            
        }){ item in
                
                switch item {
                case .scheduleSheet:
                    
                    CreateShiftForm(dateSelected: $scheduleModel.dateSelected, job: selectedJobManager.fetchJob(in: viewContext))
                    
                        .presentationDetents([.large])
                        .customSheetRadius(35)
                        .customSheetBackground()
                        .interactiveDismissDisabled()
                    
                    
                case .pastShiftSheet:
                    
                    if let shift = scheduleModel.selectedShiftToDupe {
                        NavigationStack{
                            DetailView(shift: shift, isDuplicating: true, presentedAsSheet: true)
                        }
                        .environmentObject(shiftManager)
                        .onDisappear {
                            
                            scheduleModel.fetchShifts(allShifts: allShifts)
                            
                        }
                        
                        .presentationDetents([.large])
                        .customSheetBackground()
                        .customSheetRadius(35)
                        
                    
                
                    } else {
                        
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
                    
                case .configureExportSheet:
                    ConfigureExportView(job: selectedJobManager.fetchJob(in: viewContext), singleExportShift: scheduleModel.shiftForExport)
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
                .padding(.horizontal)
                .padding(.vertical, 5)
                .tint(colorScheme == .dark ? .white.opacity(0.7) : nil)
            
                .glassModifier()
                .padding(.horizontal)
         .padding(.top, 8)
            
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(.init(top: -10, leading: 0, bottom: -10, trailing: 0))

        .onChange(of: scheduleModel.dateSelected) { _ in
            
            scheduleModel.fetchShifts(allShifts: allShifts)
            
        }

    }

    
    var floatingButtons: some View {
        return VStack{
            
            HStack(spacing: 10){

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
                            
                            
                        }
                        
                        
                        
                        
                        
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
                     
                        
                        
                        
                    }
                    
                    
                
                
                
             
                
                
                
                
                
                
            }.padding()
                .glassModifier(cornerRadius: 20)
            
                .padding()
        }
    }
    
    
    
}
