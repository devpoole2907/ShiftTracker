//
//  EditJobView.swift
//  ShiftTracker
//
//  Created by James Poole on 21/04/23.
//

import SwiftUI
import UIKit
import MapKit

struct EditJobView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var job: Job
    @ObservedObject private var locationManager = LocationDataManager()
    
    @State private var name: String
    @State private var title: String
    @State private var hourlyPay: String
    @State private var payPeriodLength: String
    @State private var payPeriodStartDay: Int?
    @State private var selectedColor: Color
    @State private var clockInReminder = true
    @State private var autoClockIn = false
    @State private var clockOutReminder = true
    @State private var autoClockOut = false
    
    @State private var showOvertimeTimeView = false
    @State private var overtimeRate = 1.25
    @State private var overtimeAppliedAfter: TimeInterval = 8.0
    @State private var overtimeEnabled = false
    
    @State private var selectedAddress: String?
    
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0074), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))


    // Initialize state properties with job values
    init(job: Job) {
        self.job = job
        _name = State(initialValue: job.name ?? "")
        _title = State(initialValue: job.title ?? "")
        _hourlyPay = State(initialValue: "\(job.hourlyPay)")
        _payPeriodLength = State(initialValue: job.payPeriodLength >= 0 ? "\(job.payPeriodLength)" : "")
        _payPeriodStartDay = State(initialValue: job.payPeriodStartDay >= 0 ? Int(job.payPeriodStartDay) : nil)
        _selectedColor = State(initialValue: Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
        _selectedAddress = State(initialValue: job.address)
        _clockInReminder = State(initialValue: job.clockInReminder)
        _clockOutReminder = State(initialValue: job.clockOutReminder)
        _autoClockIn = State(initialValue: job.autoClockIn)
        _autoClockOut = State(initialValue: job.autoClockOut)
        _overtimeEnabled = State(initialValue: job.overtimeEnabled)
        _overtimeRate = State(initialValue: job.overtimeRate)
        _overtimeAppliedAfter = State(initialValue: job.overtimeAppliedAfter)
    }
    
    private let daysOfWeek = [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]
    
    func formattedTimeInterval(_ timeInterval: TimeInterval) -> String {
            let hours = Int(timeInterval) / 3600
            let minutes = Int(timeInterval) % 3600 / 60
            return "\(hours)h \(minutes)m"
        }
    
    
    var body: some View {
        NavigationView{
            Form {
                Section(header: Text("Job Details")) {
                    TextField("Company Name", text: $name)
                    TextField("Job Title", text: $title)
                    TextField("Hourly Pay", text: $hourlyPay)
                        .keyboardType(.decimalPad)
                    ColorPicker("Job Color", selection: $selectedColor, supportsOpacity: false)
                    
                    
                    
                }
                
                Section(header: Text("Location")){
                    NavigationLink(destination: AddressFinderView(selectedAddress: $selectedAddress, mapRegion: $mapRegion)) {
                        HStack {
                            Image("LocationIconFilled")
                            
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20)
                            
                            Spacer().frame(width: 10)
                            Text("Select Address")
                        }
                    }
                    .onChange(of: selectedAddress) { newAddress in
                        job.address = newAddress
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
                
                Section(header: Text("Overtime")){
                    
                    Toggle(isOn: $overtimeEnabled){
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
                        self.showOvertimeTimeView = true
                    }
                    
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
                
                
                
                
                
            }.sheet(isPresented: $showOvertimeTimeView){
                OvertimeView(overtimeAppliedAfter: $overtimeAppliedAfter)
                    .environment(\.managedObjectContext, viewContext)
                    .presentationDetents([ .fraction(0.2)])
                    .presentationBackground(.ultraThinMaterial)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(12)
            }
            
            .navigationBarTitle("Edit Job", displayMode: .inline)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveJob) {
                        Text("Save")
                            .bold()
                    }
                }
            }
        }
    }
    
    private func saveJob() {
        job.name = name
        job.title = title
        job.hourlyPay = Double(hourlyPay) ?? 0.0
        job.address = selectedAddress
        job.clockInReminder = clockInReminder
        job.clockOutReminder = clockOutReminder
        job.autoClockIn = autoClockIn
        job.autoClockOut = autoClockOut
        job.overtimeEnabled = overtimeEnabled
        job.overtimeAppliedAfter = overtimeAppliedAfter
        job.overtimeRate = overtimeRate
        
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
            
            locationManager.startMonitoring(job: job)
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save job: \(error.localizedDescription)")
        }
    }
}
