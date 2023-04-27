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


extension UIColor {
    var rgbComponents: (Float, Float, Float) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: nil)
        return (Float(r), Float(g), Float(b))
    }
}

extension CLPlacemark {
    var formattedAddress: String {
        let components = [subThoroughfare, thoroughfare, locality, administrativeArea, postalCode, country].compactMap { $0 }
        return components.joined(separator: ", ")
    }
}



struct AllScheduledShiftsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ScheduledShift.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ScheduledShift.startDate, ascending: false)]
    ) private var allShifts: FetchedResults<ScheduledShift>

    var groupedShifts: [Date: [ScheduledShift]] {
        Dictionary(grouping: allShifts, by: { $0.startDate?.midnight() ?? Date() })
    }

    @Environment(\.colorScheme) var colorScheme
    
    private var timeFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter
        }
    
    func formattedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d MMM"
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        
        
        List {
            ForEach(groupedShifts.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(formattedDate(date)).textCase(.uppercase).bold().foregroundColor(textColor)) {
                    ForEach(groupedShifts[date] ?? [], id: \.self) { shift in
                        HStack {
                            // Vertical line
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)))
                                .frame(width: 4)
                            
                            VStack(alignment: .leading) {
                                Text(shift.job?.name ?? "")
                                    .bold()
                                Text(shift.job?.title ?? "")
                                    .foregroundColor(.gray)
                                    .bold()
                            }
                            Spacer()
                            
                            VStack(alignment: .trailing){
                                if let startDate = shift.startDate {
                                                                   Text(timeFormatter.string(from: startDate))
                                        .font(.subheadline)
                                        .bold()
                                                               }
                                                               if let endDate = shift.endDate {
                                                                   Text(timeFormatter.string(from: endDate))
                                                                       .font(.subheadline)
                                                                       .bold()
                                                                       .foregroundColor(.gray)
                                                               }
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                viewContext.delete(shift)
                                try? viewContext.save()
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }.listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
    }
}

extension Date {
    func midnight() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: components) ?? self
    }
}

