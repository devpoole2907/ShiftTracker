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


struct ScheduleView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ScheduledShift.startDate, ascending: true)], animation: .default)
    private var scheduledShifts: FetchedResults<ScheduledShift>
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Job.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]) private var jobs: FetchedResults<Job>
    
    @State private var showAddJobView = false
    
    
    @State private var showCreateShiftSheet = false
    
    @State private var dateSelected: DateComponents?
    @State private var displayEvents = false
    
    @State private var deleteJobAlert = false
    @State private var jobToDelete: Job?
    
    @State private var showAllScheduledShiftsView = false
    
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    var body: some View {
        NavigationStack {
            ZStack{
                if !showAllScheduledShiftsView{
                    
                    List {
                       // Section{
                            CalendarView(interval: DateInterval(start: .now, end: .distantFuture), dateSelected: $dateSelected, displayEvents: $displayEvents, someScheduledShifts: scheduledShifts)
                                .id(scheduledShifts.count)
                     //   
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                    //    Section{
                        ScheduledShiftsView(dateSelected: $dateSelected)
                  //      }
                        
                        
                        
                        
                    }.opacity(showAllScheduledShiftsView ? 0 : 1)
                        .animation(.easeInOut(duration: 1.0), value: showAllScheduledShiftsView)
                        .scrollContentBackground(.hidden)
                } else {
                    AllScheduledShiftsView()
                        .opacity(showAllScheduledShiftsView ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0), value: showAllScheduledShiftsView)
                        
                }
            }
            
            
            
          /*  .sheet(isPresented: $displayEvents) {
                ScheduledShiftsView(dateSelected: $dateSelected, showMenu: $showMenu)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(35)
                    .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
            }*/
            
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
                        .disabled(dateSelected == nil)
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
                    CreateShiftForm(jobs: jobs, dateSelected: dateSelected?.date, onShiftCreated: {
                        showCreateShiftSheet = false
                    })
                    .environment(\.managedObjectContext, viewContext)
                    .presentationDetents([.large])
                    .presentationCornerRadius(35)
                    .presentationBackground(colorScheme == .dark ? .black : .white)
                }
            
        }
        
    }
    // old
    func deleteJobFromWatch(_ job: Job) {
        if let jobId = job.uuid {
            WatchConnectivityManager.shared.sendDeleteJobMessage(jobId)
        }
    }
    
    
    
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}




