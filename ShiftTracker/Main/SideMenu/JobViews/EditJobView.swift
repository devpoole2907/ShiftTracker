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
    
    @AppStorage("isProVersion", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isProVersion = false
    
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var job: Job
    @ObservedObject private var locationManager = LocationDataManager()
    
    @EnvironmentObject var viewModel: ContentViewModel
    private let addressManager = AddressManager()
    private let notificationManager = ShiftNotificationManager.shared
    
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
    
    @State private var rosterReminder: Bool
    @State private var selectedDay: Int
    @State private var selectedTime: Date
    
    @State private var selectedRadius: Double = 75
    
    @State private var activeSheet: ActiveSheet?
    
    @FocusState private var textIsFocused: Bool
    
    @State private var selectedAddress: String?
    
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0074), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    @State private var miniMapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0074), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    enum ActiveSheet: Identifiable {
        case overtimeSheet, symbolSheet, proSheet
        
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
            _selectedRadius = State(initialValue: location.radius)
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
        _rosterReminder = State(initialValue: job.rosterReminder)
        _selectedDay = State(initialValue: Int(job.rosterDayOfWeek))
        _selectedTime = State(initialValue: job.rosterTime ?? Date())
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
                    
                    GeometryReader { geometry in
                                    let offset = geometry.frame(in: .global).minY
                        VStack{
                            Spacer()
                            Image(systemName: selectedIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(selectedColor)
                                .scaleEffect(1 + (offset / 1000))
                                .onTapGesture {
                                    activeSheet = .symbolSheet
                                }
                                .frame(maxWidth: .infinity)
                        }
                    }.frame(height: 80)
                    
                    
                    
                    VStack(spacing: 15){
                        
                        Group{
                            TextField("Company Name", text: $name)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color.primary.opacity(0.04),in:
                                                RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .shake(times: nameShakeTimes)
                            
                            
                            TextField("Job Title", text: $title)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color.primary.opacity(0.04),in:
                                                RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            
                            CurrencyTextField(placeholder: "Hourly Pay", text: $hourlyPay)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .keyboardType(.decimalPad)
                                .shake(times: payShakeTimes)
                            
                        }.focused($textIsFocused)
                            .haptics(onChangeOf: payShakeTimes, type: .error)
                            .haptics(onChangeOf: nameShakeTimes, type: .error)
                        
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard){
                                    Spacer()
                                    
                                    Button("Done"){
                                        textIsFocused = false
                                    }
                                }
                            }
                        
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
                        
                        
                        
                        VStack(alignment: .leading, spacing: 10){
                            
                            
                            
                            VStack{
                                Toggle(isOn: $clockInReminder) {
                                    Text("Remind me to clock in")
                                }
                                .disabled(autoClockIn)
                                .onChange(of: clockInReminder) { value in
                                    if value {
                                        autoClockIn = false
                                    }
                                }
                                .toggleStyle(OrangeToggleStyle())
                                .padding(.horizontal)
                                .padding(.top, 10)
                                
                                Toggle(isOn: $clockOutReminder) {
                                    Text("Remind me to clock out")
                                }
                                .disabled(autoClockOut)
                                .onChange(of: clockOutReminder) { value in
                                    if value {
                                        autoClockOut = false
                                    }
                                }
                                .toggleStyle(OrangeToggleStyle())
                                .padding(.horizontal)
                                
                                Toggle(isOn: $autoClockIn) {
                                    Text("Auto clock in")
                                }
                                .disabled(clockInReminder)
                                .onChange(of: autoClockIn) { value in
                                    if value {
                                        if !isProVersion {
                                            
                                            activeSheet = .proSheet
                                            autoClockIn = false
                                            
                                        } else {
                                            clockInReminder = false
                                        }
                                    }
                                }
                                .toggleStyle(OrangeToggleStyle())
                                .padding(.horizontal)
                                
                                Toggle(isOn: $autoClockOut) {
                                    Text("Auto clock out")
                                }
                                .disabled(clockOutReminder)
                                .onChange(of: autoClockOut) { value in
                                    if value {
                                        if !isProVersion {
                                            
                                            activeSheet = .proSheet
                                            autoClockOut = false
                                            
                                        } else {
                                            clockOutReminder = false
                                        }
                                    }
                                }
                                .toggleStyle(OrangeToggleStyle())
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                                
                                
                                NavigationLink(destination: AddressFinderView(selectedAddress: $selectedAddress, mapRegion: $mapRegion, selectedRadius: $selectedRadius, iconColor: selectedColor)
                                    .onDisappear {
                                        self.miniMapRegion = self.mapRegion
                                    }) {
                                        VStack(alignment: .leading){
                                            
                                            Map(coordinateRegion: $miniMapRegion, interactionModes: [], showsUserLocation: true, annotationItems: miniMapAnnotation != nil ? [miniMapAnnotation!] : []) { annotation in
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
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .cornerRadius(20)
                                
                            }
                            
                        }.background(Color.primary.opacity(0.04))
                            .cornerRadius(20)
                        
                        
                        
                        if taxEnabled || taxPercentage > 0 {
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
                        
                    }
                        
                        VStack(alignment: .leading, spacing: 10){
                            Toggle(isOn: $rosterReminder){
                                
                                Text("Roster reminders")
                                
                            }.toggleStyle(OrangeToggleStyle())
                                .padding(.horizontal)
                                .padding(.top, 10)
                            HStack{
                                Text("Time")
                                Spacer()
                                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute).labelsHidden()
                                Picker(selection: $selectedDay, label: Text("Day of the week")) {
                                    Text("Sunday").tag(1)
                                    Text("Monday").tag(2)
                                    Text("Tuesday").tag(3)
                                    Text("Wednesday").tag(4)
                                    Text("Thursday").tag(5)
                                    Text("Friday").tag(6)
                                    Text("Saturday").tag(7)
                                }.buttonStyle(.bordered)
                                
                            }.padding(.horizontal)
                                .padding(.vertical, 10)
                                .disabled(!rosterReminder)
                            
                  
                            
                        }.background(Color.primary.opacity(0.04))
                            .cornerRadius(20)
                        
                        /*
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
                        }.padding(.horizontal, 5) */ 
                        
                        
                        
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
                            .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
                                .presentationDragIndicator(.visible)
                                .presentationCornerRadius(50)
                            
                            
                        case .symbolSheet:
                            JobIconPicker(selectedIcon: $selectedIcon, iconColor: selectedColor)
                                .environment(\.managedObjectContext, viewContext)
                                .presentationDetents([ .medium])
                                .presentationDragIndicator(.visible)
                                .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
                                .presentationCornerRadius(50)
                        case .proSheet:
                            NavigationStack{
                                ProView()
                            }
                                .environment(\.managedObjectContext, viewContext)
                                .presentationDetents([ .large])
                                .presentationDragIndicator(.visible)
                                .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
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
                                Image(systemName: "folder.badge.plus")
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
        job.rosterReminder = rosterReminder
        job.rosterTime = selectedTime
        job.rosterDayOfWeek = Int16(selectedDay)
        
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
            notificationManager.updateRosterNotifications(viewContext: viewContext)
            
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
