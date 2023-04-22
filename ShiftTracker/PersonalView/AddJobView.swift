//
//  AddJobView.swift
//  ShiftTracker
//
//  Created by James Poole on 21/04/23.
//

import SwiftUI
import UIKit

struct AddJobView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject private var locationManager = LocationDataManager()
    
    @State private var name = ""
    @State private var title = ""
    @State private var hourlyPay = ""
    @State private var payPeriodLength = ""
    @State private var payPeriodStartDay: Int? = nil
    @State private var selectedColor = Color.red
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

    
    private let daysOfWeek = [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]
    
    func formattedTimeInterval(_ timeInterval: TimeInterval) -> String {
            let hours = Int(timeInterval) / 3600
            let minutes = Int(timeInterval) % 3600 / 60
            return "\(hours)h \(minutes)m"
        }
    
    var body: some View {
        
        
        NavigationStack {
            Form {
                Section(header: Text("Job Details")) {
                    TextField("Company Name", text: $name)
                    TextField("Job Title", text: $title)
                    TextField("Hourly Pay", text: $hourlyPay)
                        .keyboardType(.decimalPad)
                    ColorPicker("Job Color", selection: $selectedColor, supportsOpacity: false)
                    
                    
                    
                }//.listRowSeparator(.hidden)
                    .focused($textIsFocused)
                
                
                Section(header: Text("Location")){
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
                
                Section(header: Text("Overtime")) {
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
                        self.showOvertimeTimeView = true
                    }.disabled(!overtimeEnabled)
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
