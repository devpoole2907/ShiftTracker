//
//  EditJobView.swift
//  ShiftTracker
//
//  Created by James Poole on 21/04/23.
//

import SwiftUI
import UIKit
import MapKit
import CoreData

struct EditJobView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var job: Job
    @ObservedObject private var locationManager = LocationDataManager()
    
    @EnvironmentObject var viewModel: ContentViewModel
    private let addressManager = AddressManager()
    
    @State private var miniMapAnnotation: IdentifiablePointAnnotation?
    @State private var name: String
    @State private var title: String
    @State private var hourlyPay: String
    @State private var taxPercentage: Double
    @State private var payPeriodLength: String
    @State private var payPeriodStartDay: Int?
    @State private var selectedColor: Color
    @State private var clockInReminder = true
    @State private var autoClockIn = false
    @State private var clockOutReminder = true
    @State private var autoClockOut = false
    
    @State private var payShakeTimes: CGFloat = 0
    @State private var nameShakeTimes: CGFloat = 0
    
    @State private var showOvertimeTimeView = false
    @State private var overtimeRate = 1.25
    @State private var overtimeAppliedAfter: TimeInterval = 8.0
    @State private var overtimeEnabled = false
    
    @State private var selectedIcon: String
    
    @State private var activeSheet: ActiveSheet?
    
    @FocusState private var textIsFocused: Bool
    
    @State private var selectedAddress: String?
    
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0074), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    @State private var miniMapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0074), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    enum ActiveSheet: Identifiable {
        case overtimeSheet, symbolSheet
        
        var id: Int {
            hashValue
        }
    }
    
    
    // Initialize state properties with job values
    init(job: Job) {
        self.job = job
        _name = State(initialValue: job.name ?? "")
        _title = State(initialValue: job.title ?? "")
        _hourlyPay = State(initialValue: "\(job.hourlyPay)")
        _taxPercentage = State(initialValue: job.tax)
        _selectedIcon = State(initialValue: job.icon ?? "briefcase.circle")
        _payPeriodLength = State(initialValue: job.payPeriodLength >= 0 ? "\(job.payPeriodLength)" : "")
        _payPeriodStartDay = State(initialValue: job.payPeriodStartDay >= 0 ? Int(job.payPeriodStartDay) : nil)
        _selectedColor = State(initialValue: Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
        
        // gets the first saved address, with the new address data model system for future multiple location implementation
        
        if let locationSet = job.locations, let location = locationSet.allObjects.first as? JobLocation {
            _selectedAddress = State(initialValue: location.address)
            print("job has an address: \(location.address)")
        } else {
            print("job has no address")
        }

        
        
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
        
        NavigationStack{
            ZStack{
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                ScrollView{
                    VStack(spacing: 15){
                        
                        Image(systemName: selectedIcon)
                            .foregroundColor(selectedColor)
                            .font(.system(size: 60))
                            .frame(width: UIScreen.main.bounds.width / 5)
                        
                            .onTapGesture {
                                activeSheet = .symbolSheet
                            }
                        
                        Group{
                            TextField("Company Name", text: $name)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color.primary.opacity(0.04),in:
                                                RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .shake(times: nameShakeTimes)
                            
                            TextField("Job Title", text: $title)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color.primary.opacity(0.04),in:
                                                RoundedRectangle(cornerRadius: 6, style: .continuous))
                            
                            CurrencyTextField(placeholder: "Hourly Pay", text: $hourlyPay)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .keyboardType(.decimalPad)
                                .shake(times: payShakeTimes)
                        }.focused($textIsFocused)
                            .haptics(onChangeOf: payShakeTimes, type: .error)
                            .haptics(onChangeOf: nameShakeTimes, type: .error)
                        
                        HStack(spacing: 0){
                            ForEach(1...6, id: \.self) { index in
                                let color = jobColors[index - 1]
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(content: {
                                        if color == selectedColor{
                                            Image(systemName: "circle.fill")
                                                .foregroundColor(.white.opacity(0.6))
                                                .font(.caption.bold())
                                            
                                        }
                                    })
                                    .onTapGesture {
                                        withAnimation{
                                            selectedColor = color
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                            }
                            Divider()
                                .frame(height: 20)
                                .padding(.leading)
                            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                                .padding()
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10){
                            
                            
                            
                            VStack{
                                Toggle(isOn: $clockInReminder){
                                    
                                    Text("Remind me to clock in")
                                    
                                }.toggleStyle(OrangeToggleStyle())
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                                    
                                
                                Toggle(isOn: $clockOutReminder){
                                    
                                    Text("Remind me to clock out")
                                    
                                }.toggleStyle(OrangeToggleStyle())
                                    .padding(.horizontal)
                                   
                                Toggle(isOn: $autoClockIn){
                                    Text("Auto clock in")
                                    
                                }.toggleStyle(OrangeToggleStyle())
                                    .padding(.horizontal)
                                    
                                Toggle(isOn: $autoClockOut){
                                    
                                    Text("Auto clock out")
                                    
                                }.toggleStyle(OrangeToggleStyle())
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)
                                    
                                NavigationLink(destination: AddressFinderView(selectedAddress: $selectedAddress, mapRegion: $mapRegion)
                                    .onDisappear {
                                        // When the AddressFinderView disappears, update miniMapRegion to match mapRegion
                                        self.miniMapRegion = self.mapRegion
                                    }) {
                                        VStack(alignment: .leading){
                                            
                                            Map(coordinateRegion: $miniMapRegion, showsUserLocation: true, annotationItems: miniMapAnnotation != nil ? [miniMapAnnotation!] : []) { annotation in
                                                MapAnnotation(coordinate: annotation.coordinate) {
                                                    VStack {
                                                        Image(systemName: selectedIcon)
                                                            .font(.title2)
                                                            .foregroundColor(selectedColor)
                                                        
                                                    }
                                                }
                                            }
                                            .onAppear{
                                                //locationManager.requestAuthorization()
                                                addressManager.loadSavedAddress(selectedAddressString: selectedAddress) { region, annotation in
                                                    self.miniMapRegion = region ?? self.miniMapRegion
                                                    self.miniMapAnnotation = annotation
                                                }
                                            }
                                            HStack{
                                                Text("Work Location")
                                                
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                            }.bold()
                                                .padding(.bottom, 10)
                                                .padding(.horizontal)
                                        }
                                    }.frame(minHeight: 120)
                                    .background(Color.clear,in:
                                                    RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    .cornerRadius(20)
                                
                            }
                                
                        }.background(Color.primary.opacity(0.04))
                            .cornerRadius(20)
                        
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10){
                            Text("Estimated Tax")
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(20)
                            Picker("Estimated tax:", selection: $taxPercentage) {
                                ForEach(Array(stride(from: 0, to: 50, by: 0.5)), id: \.self) { index in
                                    Text(index / 100, format: .percent)
                                }
                                
                            }.pickerStyle(.wheel)
                                .frame(maxHeight: 100)
                        }
                            .padding(.horizontal, 5)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10){
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
                        }.padding(.horizontal, 5)
                        
                        
                        
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding()
                    .navigationBarTitle("Edit Job", displayMode: .inline)
                    /*
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
                     } */
                    
                    
                    .sheet(item: $activeSheet){ item in
                        
                        switch item {
                        case .overtimeSheet:
                            OvertimeView(overtimeAppliedAfter: $overtimeAppliedAfter)
                                .environment(\.managedObjectContext, viewContext)
                                .presentationDetents([ .fraction(0.4)])
                            
                                .presentationDragIndicator(.visible)
                                .presentationCornerRadius(50)
                            
                            
                        case .symbolSheet:
                            JobIconPicker(selectedIcon: $selectedIcon, iconColor: selectedColor)
                                .environment(\.managedObjectContext, viewContext)
                                .presentationDetents([ .medium])
                                .presentationDragIndicator(.visible)
                                .presentationCornerRadius(50)
                        }
                        
                    }
                    
                    .toolbar{
                        ToolbarItemGroup(placement: .keyboard){
                            Spacer()
                            
                            Button("Done"){
                                textIsFocused = false
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                
                                if name.isEmpty {
                                    withAnimation(.linear(duration: 0.4)) {
                                        nameShakeTimes += 2
                                    }
                                }
                                else if hourlyPay.isEmpty {
                                    withAnimation(.linear(duration: 0.4)) {
                                        payShakeTimes += 2
                                    }
                                }
                                else {
                                    saveJob()
                                    
                                    
                                }
                                
                                
                                
                            }) {
                                Text("Save")
                                    .bold()
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                
                                presentationMode.wrappedValue.dismiss()
                                
                                CustomConfirmationAlert(action: deleteJob, title: "Are you sure? All associated previous and scheduled shifts will be deleted.").present()
                                
                                
                            }
                            ) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .bold()
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .bold()
                            }
                        }
                        
                    }
                    
                }
            }
        }
    }
    
    private func saveJob() {
        job.name = name
        job.title = title
        job.hourlyPay = Double(hourlyPay) ?? 0.0
        job.tax = taxPercentage
        job.icon = selectedIcon
        job.clockInReminder = clockInReminder
        job.clockOutReminder = clockOutReminder
        job.autoClockIn = autoClockIn
        job.autoClockOut = autoClockOut
        job.overtimeEnabled = overtimeEnabled
        job.overtimeAppliedAfter = overtimeAppliedAfter
        job.overtimeRate = overtimeRate
        
        // replace this code with adding locations later when multiple address system update releases
        if let locationSet = job.locations, let location = locationSet.allObjects.first as? JobLocation {
            location.address = selectedAddress
        } else { // for multi jobs we need this to add more
            let location = JobLocation(context: viewContext)
            location.address = selectedAddress
            job.addToLocations(location)
        }

        

        
        
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
            
        
                locationManager.startMonitoring(job: job) // might need to check clock out works with this, ive forgotten my implementation
            
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save job: \(error.localizedDescription)")
        }
        
        if job.uuid == viewModel.selectedJobUUID {
            viewModel.hourlyPay = job.hourlyPay
            viewModel.saveHourlyPay()
            viewModel.taxPercentage = job.tax
            viewModel.saveTaxPercentage()
        }
        
        
    }
    
    private func deleteJob() {
        viewContext.delete(job)
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
}
