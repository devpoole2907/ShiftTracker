//
//  PersonalView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//
// Create/edit jobs, schedule shifts

import SwiftUI
import Haptics
import UIKit
import CoreLocation
import MapKit


struct PersonalView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    
    @Environment(\.managedObjectContext) private var viewContext
       @FetchRequest(entity: Job.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]) private var jobs: FetchedResults<Job>
    
    @State private var showAddJobView = false
    
    @State private var dateSelected: DateComponents?
    @State private var displayEvents = false
    
    @State private var deleteJobAlert = false
    @State private var jobToDelete: Job?
    
    @State private var showAllScheduledShiftsView = false
    
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        
        NavigationStack {
            ZStack{
                if !showAllScheduledShiftsView{
            List {
                if !jobs.isEmpty{
                    Section {
                        ForEach(jobs, id: \.self) { job in
                            
                            NavigationLink(destination: EditJobView(job: job)){
                                
                                HStack(spacing : 10){
                                    Image(systemName: job.icon ?? "briefcase.circle")
                                        .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                                        .font(.system(size: 30))
                                        .frame(width: UIScreen.main.bounds.width / 7)
                                    VStack(alignment: .leading, spacing: 5){
                                        Text(job.name ?? "")
                                            .foregroundColor(textColor)
                                            .font(.title2)
                                            .bold()
                                        Text(job.title ?? "")
                                            .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                                            .font(.subheadline)
                                            .bold()
                                        Text("$\(job.hourlyPay, specifier: "%.2f") / hr")
                                            .foregroundColor(.gray)
                                            .font(.footnote)
                                            .bold()
                                    }
                                    
                                }
                            }
                        }
                        .onDelete(perform: deleteJob)
                    }
                header: {
                    HStack{
                        Text("Jobs")
                            .font(.title)
                            .bold()
                            .textCase(nil)
                            .foregroundColor(textColor)
                            .padding(.leading, -12)
                        Spacer()
                        NavigationLink(destination: AddJobView()) {
                            Image(systemName: "plus")
                                .font(.title2)
                        }
                    }
                    .padding(.trailing, 16)
                }
                    
                }
                else {
                    
                    
                    
                    Section {
                        VStack(alignment: .center, spacing: 15){
                            Text("No jobs found.")
                                .font(.title3)
                                .bold()
                            
                            
                            NavigationLink(destination: AddJobView()){
                                Text("Create one now")
                                    .bold()
                                    .foregroundColor(.orange)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 85)
                            
                        } .frame(maxWidth: .infinity)
                            .padding()
                    } header : {
                        HStack{
                            Text("Jobs")
                                .font(.title)
                                .bold()
                                .textCase(nil)
                                .foregroundColor(textColor)
                                .padding(.leading, -12)
                        }
                    }
                    
                } 
                Section{
                    
                    CalendarView(interval: DateInterval(start: .distantPast, end: .distantFuture), dateSelected: $dateSelected, displayEvents: $displayEvents)
                        //.fixedSize(horizontal: true, vertical: true)
                       // .scaleEffect(CGSize(width: 0.95, height: 0.95))
                        //.padding(.horizontal, 20)
                    
                } header : {
                    HStack{
                        Text("Schedule")
                            .font(.title)
                            .bold()
                            .textCase(nil)
                            .foregroundColor(textColor)
                            .padding(.leading, -12)
                        
                    }
                }
                //.listRowBackground(Color.clear)
                
                
            }.opacity(showAllScheduledShiftsView ? 0 : 1)
                .animation(.easeInOut(duration: 1.0), value: showAllScheduledShiftsView)
        } else {
            AllScheduledShiftsView()
                .opacity(showAllScheduledShiftsView ? 1 : 0)
                .animation(.easeInOut(duration: 1.0), value: showAllScheduledShiftsView)
        }
    }
            
                       .sheet(isPresented: $displayEvents) {
                            ScheduledShiftsView(dateSelected: $dateSelected)
                                .presentationDetents([.medium, .large])
                                //.presentationBackground(.ultraThinMaterial)
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
            
                       .navigationBarTitle(showAllScheduledShiftsView ? "Schedule" : "Personal", displayMode: .inline)
            .toolbar{
                        ToolbarItem(placement: .navigationBarTrailing){
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    showAllScheduledShiftsView.toggle()
                                }
                            }) {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(showAllScheduledShiftsView ? Color.white : Color.orange)
                                    .background(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .fill(showAllScheduledShiftsView ? .orange : .clear)
                                                            .padding(-5)
                                                    )
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

struct PersonalView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalView()
    }
}




