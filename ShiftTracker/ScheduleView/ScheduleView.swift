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
        guard let date = dateSelected?.date else { displayedOldShifts = []; return }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!

        displayedOldShifts = allShifts.filter { ($0.shiftStartDate! as Date) >= startOfDay && ($0.shiftStartDate! as Date) < endOfDay }
    }

    
    
    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack{
                if !showAllScheduledShiftsView{
                    
                    List {
                        let interval = DateInterval(start: .distantPast, end: .distantFuture)
                        Section{
                            CalendarView(interval: interval, shiftStore: shiftStore, dateSelected: $dateSelected, displayEvents: $displayEvents)
                                .padding()
                                .tint(colorScheme == .dark ? .white.opacity(0.7) : nil)
                        }
                                .listRowBackground(Color("SquaresColor"))
                                .listRowSeparator(.hidden)
                                .listRowInsets(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
     
                        
                       //
                                .onChange(of: dateSelected) { _ in
                                    
                                fetchShifts()
                                    
                                }
                           
                        
                       
                         //   .background(.red)
                           
                        
                            
                            
                            
                        
                       // } else {
                        if !isBeforeToday(dateSelected!.date ?? Date()) {
                            ScheduledShiftsView(dateSelected: $dateSelected)
                                .environmentObject(shiftStore)
                                .environmentObject(scheduleModel)
                            
                                .onAppear {
                                    
                                    print("heres the fucking date before passing to create shift \(dateSelected?.date)")
                                    
                                    
                                }
                            
                            
                        } else {
                            
                            CalendarPreviousShiftsList(dateSelected: $dateSelected, navPath: $navPath, displayedOldShifts: $displayedOldShifts)
                               
                            
                                
                            
                                .listRowBackground(isBeforeToday(dateSelected!.date ?? Date()) ? Color("SquaresColor") : Color.clear)
                        }
                    }.opacity(showAllScheduledShiftsView ? 0 : 1)
                        .animation(.easeInOut(duration: 1.0), value: showAllScheduledShiftsView)
                        .scrollContentBackground(.hidden)
                    
                } else {
                    AllScheduledShiftsView()
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
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing){
                        Button(action: {
                            
                            
                               
                            
                            if jobSelectionViewModel.selectedJobUUID == nil {
                                
                                
                                OkButtonPopup(title: "Select a job before scheduling a shift.", action: { navigationState.showMenu.toggle() }).showAndStack()
                               
                                
                            } else {
                                
                                showCreateShiftSheet = true
                                
                            }
                            
                        }) {
                            Image(systemName: "plus")
                                .bold()
                        }.padding()
              
                        .disabled(showAllScheduledShiftsView || isBeforeToday(dateSelected!.date ?? Date()))
                        
                    }
                ToolbarItem(placement: .navigationBarLeading){
                    Button{
                        withAnimation{
                            navigationState.showMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .bold()
                     
                    }.disabled(true)
                }
            }.haptics(onChangeOf: showAllScheduledShiftsView, type: .light)
            
            
                .sheet(isPresented: $showCreateShiftSheet) {
                    
                    
                    CreateShiftForm(dateSelected: $dateSelected)
                    .environmentObject(shiftStore)
                    .environmentObject(jobSelectionViewModel)
                    .environment(\.managedObjectContext, viewContext)
                    .presentationDetents([.large])
                    .presentationCornerRadius(35)
                    .presentationBackground(colorScheme == .dark ? .black : .white)
                }
            
        }.onAppear{
            
            shiftStore.deleteOldScheduledShifts(in: viewContext)
            
            shiftStore.fetchShifts(from: scheduledShifts, and: allShifts, jobModel: jobSelectionViewModel)
          
            
        }
        
        .onReceive(jobSelectionViewModel.$selectedJobUUID){ _ in
            
            shiftStore.fetchShifts(from: scheduledShifts, and: allShifts, jobModel: jobSelectionViewModel)
            
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
