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


struct PersonalView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    
    @EnvironmentObject var eventStore: EventStore
    
    @Environment(\.managedObjectContext) private var viewContext
       @FetchRequest(entity: Job.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]) private var jobs: FetchedResults<Job>
    
    @State private var showAddJobView = false
    

    
    @State private var dateSelected: DateComponents?
    @State private var displayEvents = false
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        NavigationStack {
            
            List {
               //Spacer(minLength: 300)
                 
                
                
                if !jobs.isEmpty{
                    Section {
                    ForEach(jobs, id: \.self) { job in
                        
                        NavigationLink(destination: EditJobView(job: job)){
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
                    .onDelete(perform: deleteJob)
                }
                    header : {
                        HStack{
                            Text("Jobs")
                                .font(.title)
                                .bold()
                                .textCase(nil)
                                .foregroundColor(textColor)
                                .padding(.leading, -12)
                            Spacer()
                            Button(action: {
                                showAddJobView = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                            }
                        }
                    }
                }
                else {
                    Section {
                        VStack(alignment: .center, spacing: 15){
                            Text("No jobs found.")
                                .font(.title3)
                                .bold()
                            Button(action: {
                                showAddJobView = true
                            }) {
                                Text("Create one now")
                                    .bold()
                            }
                        } .frame(maxWidth: .infinity, alignment: .center)
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
                   
                        CalendarView(interval: DateInterval(start: .distantPast, end: .distantFuture), eventStore: eventStore, dateSelected: $dateSelected, displayEvents: $displayEvents)
                        
                    
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
                .listRowBackground(Color.clear)
                
            
            }.sheet(isPresented: $showAddJobView) {
                AddJobView()
                    .environment(\.managedObjectContext, viewContext)
                    .presentationDetents([.fraction(0.7)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.thinMaterial)
            }
            .navigationBarTitle("Personal", displayMode: .inline)
        }
        
    }
    
    
    private func deleteJob(at offsets: IndexSet) {
            for index in offsets {
                let job = jobs[index]
                viewContext.delete(job)
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete job: \(error.localizedDescription)")
            }
        }
    
}

struct PersonalView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalView()
            .environmentObject(EventStore(preview: true))
    }
}

struct AddJobView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    
    @State private var name = ""
    @State private var title = ""
    @State private var hourlyPay = ""
    @State private var payPeriodLength = ""
    @State private var payPeriodStartDay: Int? = nil
    @State private var selectedColor = Color.red
    
    @State private var selectedAddress: String?


    
    private let daysOfWeek = [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Job Details")) {
                    TextField("Company Name", text: $name)
                    TextField("Job Title", text: $title)
                    TextField("Hourly Pay", text: $hourlyPay)
                        .keyboardType(.decimalPad)
                    ColorPicker("Job Color", selection: $selectedColor, supportsOpacity: false)


                    
                }
                
                Section(header: Text("Pay Period")) {
                    TextField("Length in Days (Optional)", text: $payPeriodLength)
                        .keyboardType(.numberPad)
                    
                    Picker("Start Day (Optional)", selection: $payPeriodStartDay) {
                        ForEach(0 ..< daysOfWeek.count) { index in
                            Text(self.daysOfWeek[index]).tag(index)
                        }
                    }
                }
                
                Button(action: saveJob) {
                    Text("Save Job")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .navigationBarTitle("Add Job", displayMode: .inline)
            }
            
        }
    }
    
    private func saveJob() {
        let newJob = Job(context: viewContext)
        newJob.name = name
        newJob.title = title
        newJob.hourlyPay = Double(hourlyPay) ?? 0.0
        
        let uiColor = UIColor(selectedColor)
            let (r, g, b) = uiColor.rgbComponents
            newJob.colorRed = r
            newJob.colorGreen = g
            newJob.colorBlue = b
        
        if let length = Int16(payPeriodLength) {
            newJob.payPeriodLength = length
        } else {
            newJob.payPeriodLength = -1
        }
        
        if let startDay = payPeriodStartDay {
            newJob.payPeriodStartDay = Int16(startDay)
        } else {
            newJob.payPeriodStartDay = -1
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save job: \(error.localizedDescription)")
        }
    }
}

struct AddJobView_Previews: PreviewProvider {
    static var previews: some View {
        AddJobView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
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

struct EditJobView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var job: Job
    
    @State private var name: String
    @State private var title: String
    @State private var hourlyPay: String
    @State private var payPeriodLength: String
    @State private var payPeriodStartDay: Int?
    @State private var selectedColor: Color
    
    @State private var selectedAddress: String?


    // Initialize state properties with job values
    init(job: Job) {
        self.job = job
        _name = State(initialValue: job.name ?? "")
        _title = State(initialValue: job.title ?? "")
        _hourlyPay = State(initialValue: "\(job.hourlyPay)")
        _payPeriodLength = State(initialValue: job.payPeriodLength >= 0 ? "\(job.payPeriodLength)" : "")
        _payPeriodStartDay = State(initialValue: job.payPeriodStartDay >= 0 ? Int(job.payPeriodStartDay) : nil)
        _selectedColor = State(initialValue: Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
    }
    
    private let daysOfWeek = [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Job Details")) {
                    TextField("Company Name", text: $name)
                    TextField("Job Title", text: $title)
                    TextField("Hourly Pay", text: $hourlyPay)
                        .keyboardType(.decimalPad)
                    ColorPicker("Job Color", selection: $selectedColor, supportsOpacity: false)


                    
                }
                
                Section(header: Text("Pay Period")) {
                    TextField("Length in Days (Optional)", text: $payPeriodLength)
                        .keyboardType(.numberPad)
                    
                    Picker("Start Day (Optional)", selection: $payPeriodStartDay) {
                        ForEach(0 ..< daysOfWeek.count) { index in
                            Text(self.daysOfWeek[index]).tag(index)
                        }
                    }
                }
                
                Button(action: saveJob) {
                    Text("Save Job")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .navigationBarTitle("Edit Job", displayMode: .inline)
            }
        }
    }
    
    private func saveJob() {
        job.name = name
        job.title = title
        job.hourlyPay = Double(hourlyPay) ?? 0.0
        
        let uiColor = UIColor(selectedColor)
        let (r, g, b) = uiColor.rgbComponents
        job.colorRed = r
        job.colorGreen = g
        job.colorBlue = b
        
        if let length = Int16(payPeriodLength) {
            job.payPeriodLength = length
        } else {
            job.payPeriodLength = -1
        }
        
        if let startDay = payPeriodStartDay {
            job.payPeriodStartDay = Int16(startDay)
        } else {
            job.payPeriodStartDay = -1
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save job: \(error.localizedDescription)")
        }
    }
}
