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
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    @EnvironmentObject var shiftStore: ScheduledShiftStore
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Job.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]) private var jobs: FetchedResults<Job>
    
    @State private var showAddJobView = false
    
    
    @State private var showCreateShiftSheet = false
    
    @State private var dateSelected: DateComponents?// = Date().dateComponents
    @State private var displayEvents = false
    
    @State private var deleteJobAlert = false
    @State private var jobToDelete: Job?
    
    @State private var showAllScheduledShiftsView = false
    
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    
    @FetchRequest var scheduledShifts: FetchedResults<ScheduledShift>
    
    init(){
        
        let fetchRequest: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledShift.startDate, ascending: true)]
        _scheduledShifts = FetchRequest(fetchRequest: fetchRequest)
        
      //  _dateSelected = State(initialValue: Date().dateComponents)
        
      
            let appearance = UINavigationBarAppearance()
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
           // UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack{
                if !showAllScheduledShiftsView{
                    
                    List {
                        let interval = DateInterval(start: .now, end: .distantFuture)
                        CalendarView(interval: interval, shiftStore: shiftStore, dateSelected: $dateSelected, displayEvents: $displayEvents)
                            .padding()
                            .tint(colorScheme == .dark ? .white.opacity(0.7) : nil)
                                .listRowBackground(Color("SquaresColor"))
                                .listRowSeparator(.hidden)
                                .listRowInsets(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
     
                        ScheduledShiftsView(dateSelected: $dateSelected)
                            .environmentObject(shiftStore)
                            .environmentObject(scheduleModel)

                        
                        
                        
                        
                    }.opacity(showAllScheduledShiftsView ? 0 : 1)
                        .animation(.easeInOut(duration: 1.0), value: showAllScheduledShiftsView)
                        .scrollContentBackground(.hidden)
                } else {
                    AllScheduledShiftsView()
                        .opacity(showAllScheduledShiftsView ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0), value: showAllScheduledShiftsView)
                        
                }
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
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(showAllScheduledShiftsView ? (colorScheme == .dark ? .white : .black) : .clear)
                                    .padding(-5)
                            )
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing){
                        Button(action: {
                            
                                showCreateShiftSheet = true
                            
                        }) {
                            Image(systemName: "plus")
                                .bold()
                        }.padding()
                        //.disabled(dateSelected == nil)
                        .disabled(jobSelectionViewModel.selectedJobUUID == nil)
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
            
            
                .sheet(isPresented: $showCreateShiftSheet) {
                    CreateShiftForm(dateSelected: dateSelected?.date)
                    .environmentObject(shiftStore)
                    .environmentObject(jobSelectionViewModel)
                    .environment(\.managedObjectContext, viewContext)
                    .presentationDetents([.large])
                    .presentationCornerRadius(35)
                    .presentationBackground(colorScheme == .dark ? .black : .white)
                }
            
        }.onAppear{
            
            shiftStore.fetchShifts(from: scheduledShifts, jobModel: jobSelectionViewModel)
            
        }
        
        .onReceive(jobSelectionViewModel.$selectedJobUUID){ _ in
            
            shiftStore.fetchShifts(from: scheduledShifts, jobModel: jobSelectionViewModel)
            
            print("Changed job")
            shiftStore.changedJob = jobSelectionViewModel.fetchJob(in: viewContext)
            
        }
        
    }
    
    private func fetchShifts() -> [ScheduledShift] {
            let fetchRequest: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledShift.startDate, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "job.uuid == %@", jobSelectionViewModel.selectedJobUUID! as any CVarArg)

            do {
                let shifts = try viewContext.fetch(fetchRequest)
                return shifts
            } catch {
                print("Failed to fetch shifts: \(error)")
                return []
            }
        }
    
    
    
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}




