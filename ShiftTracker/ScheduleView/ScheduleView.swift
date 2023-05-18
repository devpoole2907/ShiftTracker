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
    
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Job.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]) private var jobs: FetchedResults<Job>
    
    @State private var showAddJobView = false
    
    @Binding var showMenu: Bool
    
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
                    Form {
                        Section{
                            CalendarView(interval: DateInterval(start: .now, end: .distantFuture), dateSelected: $dateSelected, displayEvents: $displayEvents)
                        }
                        
                        .listRowBackground(Color.clear)
                        
                        
                    }.opacity(showAllScheduledShiftsView ? 0 : 1)
                        .animation(.easeInOut(duration: 1.0), value: showAllScheduledShiftsView)
                        .scrollContentBackground(.hidden)
                } else {
                    AllScheduledShiftsView()
                        .opacity(showAllScheduledShiftsView ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0), value: showAllScheduledShiftsView)
                }
            }
            
            .sheet(isPresented: $displayEvents) {
                ScheduledShiftsView(dateSelected: $dateSelected)
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(50)
            }
            .alert(isPresented: $deleteJobAlert) {
                Alert(title: Text("Delete Job"),
                      message: Text("Are you sure you want to delete this job and all associated scheduled shifts?"),
                      primaryButton: .destructive(Text("Delete")) {
                    confirmDeleteJob()
                },
                      secondaryButton: .cancel()
                )
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
                            .foregroundColor(showAllScheduledShiftsView ? Color.white : Color.accentColor)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(showAllScheduledShiftsView ? .black : .clear)
                                    .padding(-5)
                            )
                    }
                }
                ToolbarItem(placement: .navigationBarLeading){
                    Button{
                        withAnimation{
                            showMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .bold()
                     
                    }
                }
            }
        }
        
    }
    
    
    private func deleteJob(at offsets: IndexSet) {
        for index in offsets {
            let job = jobs[index]
            jobToDelete = job
            deleteJobAlert = true
        }
    }
    
    
    private func confirmDeleteJob() {
        if let job = jobToDelete {
            // Delete associated ScheduledShifts
            if let scheduledShifts = job.scheduledShifts as? Set<ScheduledShift> {
                for shift in scheduledShifts {
                    viewContext.delete(shift)
                }
            }
            
            // Delete the job
            sharedUserDefaults.removeObject(forKey: "SelectedJobUUID")
            deleteJobFromWatch(job)
            viewContext.delete(job)
            jobToDelete = nil
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete job: \(error.localizedDescription)")
            }
        }
        deleteJobAlert = false
    }
    
    func deleteJobFromWatch(_ job: Job) {
        if let jobId = job.uuid {
            WatchConnectivityManager.shared.sendDeleteJobMessage(jobId)
        }
    }
    
    
    
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView(showMenu: .constant(false))
    }
}




