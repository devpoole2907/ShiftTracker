//
//  AddJobView.swift
//  ShiftTracker
//
//  Created by James Poole on 21/04/23.
//

import SwiftUI
import UIKit
import CoreData

struct AddJobView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject private var locationManager = LocationDataManager()
    
    @State private var name = ""
    @State private var title = ""
    @State private var hourlyPay: Double = 0.0
    @State private var payPeriodLength = ""
    @State private var payPeriodStartDay: Int? = nil
    @State private var selectedColor = Color.cyan
    @State private var clockInReminder = true
    @State private var autoClockIn = false
    @State private var clockOutReminder = true
    @State private var autoClockOut = false
    
    @State private var overtimeRate = 1.25
    @State private var overtimeAppliedAfter: TimeInterval = 8.0
    @State private var overtimeEnabled: Bool = false
    
    @State private var selectedAddress: String?
    
    @State private var showOvertimeTimeView = false
    
    @FocusState private var textIsFocused: Bool
    
    @State private var selectedIcon = "briefcase.circle"
    
    @State private var activeSheet: ActiveSheet?
    
    enum ActiveSheet: Identifiable {
        case overtimeSheet, symbolSheet

        var id: Int {
            hashValue
        }
    }

    
    private let daysOfWeek = [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]
    
    func formattedTimeInterval(_ timeInterval: TimeInterval) -> String {
            let hours = Int(timeInterval) / 3600
            let minutes = Int(timeInterval) % 3600 / 60
            return "\(hours)h \(minutes)m"
        }
    
    
    func fetchAllJobs() -> [Job] {
        let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
        do {
            let jobs = try viewContext.fetch(fetchRequest)
            return jobs
        } catch {
            print("Failed to fetch jobs: \(error.localizedDescription)")
            return []
        }
    }

    
    var body: some View {
        
        
        NavigationStack {
            ScrollView {
                    VStack(alignment: .leading, spacing: 20){
                        
                        HStack(spacing: 10) {
                            Image(systemName: selectedIcon)
                                .foregroundColor(selectedColor)
                                .font(.system(size: 60))
                                .frame(width: UIScreen.main.bounds.width / 5)
                            
                                .onTapGesture {
                                    activeSheet = .symbolSheet
                                }
                            Spacer()
                            VStack(alignment: .leading){
                                TextField("Company Name", text: $name)
                                    .font(.title)
                                    .bold()
                                    
                                TextField("Job Title", text: $title)
                                    .bold()
                                    .foregroundColor(.gray)
                                HStack{
                                    TextField("Hourly Pay", value: $hourlyPay, format: .currency(code: Locale.current.currency?.identifier ?? "NZD"))
                                        .bold()
                                        .keyboardType(.decimalPad)
                                }
                            }
                        }
                    .focused($textIsFocused)
                    .padding(.vertical, 15)
                    //.background(Color(.systemGray6))
                   // .cornerRadius(12)
                        
                    
                        ColorPicker("", selection: $selectedColor, supportsOpacity: false)

                
                Section{
                    NavigationLink(destination: AddressFinderView(selectedAddress: $selectedAddress)) {
                        HStack {
                            Image("LocationIconFilled")
                            
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20)
                            
                            Spacer().frame(width: 10)
                            Text("Select Address")
                        }
                    }
                    Toggle(isOn: $clockInReminder){
                        HStack {
                            Image(systemName: "bell.badge.circle")
                            Spacer().frame(width: 10)
                            Text("Remind me to clock in")
                        }
                    }.toggleStyle(OrangeToggleStyle())
                    
                    Toggle(isOn: $clockOutReminder){
                        HStack {
                            Image(systemName: "bell.badge.circle")
                            Spacer().frame(width: 10)
                            Text("Remind me to clock out")
                        }
                    }.toggleStyle(OrangeToggleStyle())
                    
                    Toggle(isOn: $autoClockIn){
                        HStack {
                            Image(systemName: "bell.badge.circle")
                            Spacer().frame(width: 10)
                            Text("Remind me to clock in")
                        }
                    }.toggleStyle(OrangeToggleStyle())
                        .disabled(true)
                    
                    Toggle(isOn: $autoClockOut){
                        HStack {
                            Image(systemName: "bell.badge.circle")
                            Spacer().frame(width: 10)
                            Text("Remind me to clock out")
                        }
                    }.toggleStyle(OrangeToggleStyle())
                        .disabled(true)
                }
                
                Section{
                    Toggle(isOn: $overtimeEnabled) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.clock")
                            Spacer().frame(width: 10)
                            Text("Enable Overtime")
                        }
                    }
                    .toggleStyle(OrangeToggleStyle())
                    
                    Stepper(value: $overtimeRate, in: 1.25...3, step: 0.25) {
                        HStack{
                            Image(systemName: "speedometer")
                            Spacer().frame(width: 10)
                            Text("Rate: \(overtimeRate, specifier: "%.2f")x")
                        }
                    }.disabled(!overtimeEnabled)
                    
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                        Text("Overtime applied after:")
                        Spacer()
                        Text("\(formattedTimeInterval(overtimeAppliedAfter))")
                            .foregroundColor(.gray)
                    }
                    .onTapGesture {
                        activeSheet = .overtimeSheet
                    }.disabled(!overtimeEnabled)
                }
                
                
                
                Section{
                    TextField("Length in Days (Optional)", text: $payPeriodLength)
                        .keyboardType(.numberPad)
                    
                    Picker("Start Day (Optional)", selection: $payPeriodStartDay) {
                        ForEach(0 ..< daysOfWeek.count) { index in
                            Text(self.daysOfWeek[index]).tag(index)
                        }
                    }
                }
                
                
            }
                .padding(.horizontal, 30)
                //.padding(.vertical)
            }.sheet(item: $activeSheet){ item in
                
                switch item {
                case .overtimeSheet:
                    OvertimeView(overtimeAppliedAfter: $overtimeAppliedAfter)
                        .environment(\.managedObjectContext, viewContext)
                            .presentationDetents([ .fraction(0.2)])
                            .presentationBackground(.ultraThinMaterial)
                            .presentationDragIndicator(.visible)
                            .presentationCornerRadius(12)
                    
                    
            case .symbolSheet:
                    JobIconPicker(selectedIcon: $selectedIcon, iconColor: selectedColor)
                    .environment(\.managedObjectContext, viewContext)
                    .presentationDetents([ .medium])
                    .presentationBackground(.ultraThinMaterial)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(12)
            }
            
        }
            
            .toolbar{
                ToolbarItemGroup(placement: .keyboard){
                    Spacer()
                    
                    Button("Done"){
                        textIsFocused = false
                    }
                }
            }
            
            .navigationBarTitle("Add Job")
            .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: saveJob) {
                                    Text("Save")
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 15)
                                        //.foregroundColor(.orange)
                                        //.background(Color(.systemGray4))
                                        .cornerRadius(8)
                                 
                                        
                                }
                            }
                    
                        }
            
        }
    }
    
    private func saveJob() {
        let newJob = Job(context: viewContext)
        newJob.name = name
        newJob.title = title
        newJob.hourlyPay = Double(hourlyPay) ?? 0.0
        newJob.address = selectedAddress
        newJob.clockInReminder = clockInReminder
        newJob.clockOutReminder = clockOutReminder
        newJob.autoClockIn = autoClockIn
        newJob.autoClockOut = autoClockOut
        newJob.overtimeEnabled = overtimeEnabled
        newJob.overtimeAppliedAfter = overtimeAppliedAfter
        newJob.overtimeRate = overtimeRate
        newJob.icon = selectedIcon
        newJob.uuid = UUID()
        
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
            
            let allJobs = fetchAllJobs()
                    //let jobDataArray = allJobs.map { jobData(from: $0) }
                    WatchConnectivityManager.shared.sendJobData(allJobs)
            
            locationManager.startMonitoring(job: newJob)
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

let jobIcons = [
    "briefcase.circle", "display", "tshirt.fill", "takeoutbag.and.cup.and.straw.fill", "trash.fill",
    "wineglass.fill", "cup.and.saucer.fill", "film.fill", "building.columns.circle.fill", "camera.fill", "camera.macro.circle", "bus.fill", "box.truck", "fuelpump.circle", "popcorn.circle", "cross.case.circle", "frying.pan", "cart.circle", "paintbrush", "wrench.adjustable"]


struct JobIconPicker: View {
    @Binding var selectedIcon: String
    var iconColor: Color
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 50)), count: 4), spacing: 50) {
                    ForEach(jobIcons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                        }) {
                            VStack {
                                Image(systemName: icon)
                                    .font(.title2)
                                   // .resizable()
                                    //.scaledToFit()
                                    .frame(height: 20)
                                    .foregroundColor(iconColor)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Job Icon", displayMode: .inline)
        }
    }
}
