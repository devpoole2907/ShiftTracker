//
//  AddJobView.swift
//  ShiftTracker
//
//  Created by James Poole on 21/04/23.
//

import SwiftUI
import UIKit
import CoreData
import Firebase
import MapKit
import Haptics

struct AddJobView: View {
    
    @AppStorage("isProVersion", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isProVersion = false
    
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var model = JobsViewModel()
    
    @ObservedObject private var locationManager = LocationDataManager()
    
    private let addressManager = AddressManager()
    private let notificationManager = ShiftNotificationManager.shared
    
    @State private var name = ""
    @State private var title = ""
    @State private var hourlyPay: String = ""
    @State private var taxPercentage: Double = 0
    @State private var payPeriodLength = ""
    @State private var payPeriodStartDay: Int? = nil
    @State private var selectedColor = Color.cyan
    @State private var clockInReminder = false
    @State private var autoClockIn = false
    @State private var clockOutReminder = false
    @State private var autoClockOut = false
    
    @State private var payShakeTimes: CGFloat = 0
    @State private var nameShakeTimes: CGFloat = 0
    
    @State private var overtimeRate = 1.25
    @State private var overtimeAppliedAfter: TimeInterval = 8.0
    @State private var overtimeEnabled: Bool = false
    
    @State private var selectedAddress: String?
    @State private var selectedRadius: Double = 75
    @State private var miniMapAnnotation: IdentifiablePointAnnotation?
    
    @State private var showFullCover = false
    
    @State private var rosterReminder = false
    @State private var selectedDay: Int = 1
        @State private var selectedTime = Date()
    
    @State private var showOvertimeTimeView = false
    
    @FocusState private var textIsFocused: Bool
    
    @State private var selectedIcon = "briefcase.circle"
    
    @State private var activeSheet: ActiveSheet?
    
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0074), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    @State private var miniMapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0074), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    enum ActiveSheet: Identifiable {
        case overtimeSheet, symbolSheet, proSheet
        
        var id: Int {
            hashValue
        }
    }
    
    private func centerMapOnCurrentLocation() {
        guard let currentLocation = locationManager.location else { return }
        
        miniMapRegion = MKCoordinateRegion(
            center: currentLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
    
    
    
    

    
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
                                .background(Color("SquaresColor"),in:
                                                RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .shake(times: nameShakeTimes)
                            
                            TextField("Job Title", text: $title)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color("SquaresColor"),in:
                                                RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            CurrencyTextField(placeholder: "Hourly Pay", text: $hourlyPay)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color("SquaresColor"), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                                .toggleStyle(CustomToggleStyle())
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
                                .toggleStyle(CustomToggleStyle())
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
                                .toggleStyle(CustomToggleStyle())
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
                                .toggleStyle(CustomToggleStyle())
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                                
                                
                                NavigationLink(destination: AddressFinderView(selectedAddress: $selectedAddress, mapRegion: $mapRegion, selectedRadius: $selectedRadius, iconColor: selectedColor)
                                    .onDisappear {
                                        // When the AddressFinderView disappears, update miniMapRegion to match mapRegion
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
                                
                                
                            }
                            
                            
                        }.background(Color("SquaresColor"))
                            .cornerRadius(20)
                        
                        if taxEnabled {
                        VStack(alignment: .leading, spacing: 10){
                            Text("Estimated Tax")
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color("SquaresColor"))
                                .cornerRadius(20)
                            Picker("Estimated tax:", selection: $taxPercentage) {
                                ForEach(Array(stride(from: 0, to: 50, by: 0.5)), id: \.self) { index in
                                    Text(index / 100, format: .percent)
                                }
                                
                            }.pickerStyle(.wheel)
                                .frame(maxHeight: 100)
                        }
                        .padding(.horizontal, 10)
                    }
                        
                        VStack(alignment: .leading, spacing: 10){
                            Toggle(isOn: $rosterReminder){
                                
                                Text("Roster reminders")
                                
                            }.toggleStyle(CustomToggleStyle())
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
                            
                            
                            
                            
                        }.background(Color("SquaresColor"))
                            .cornerRadius(20)
                        
                        /* VStack(alignment: .leading, spacing: 10){
                            Toggle(isOn: $overtimeEnabled) {
                                HStack {
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
                    .navigationBarTitle("Add Job", displayMode: .inline)
                    
        
                     
                     

                     
                     
                     /*
                     
                     
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
                                .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
                                .presentationCornerRadius(50)
                            
                            
                        case .symbolSheet:
                            JobIconPicker(selectedIcon: $selectedIcon, iconColor: selectedColor)
                                .environment(\.managedObjectContext, viewContext)
                                .presentationDetents([ .medium, .large])
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
                                    saveJobToCoreData()
                                    print("saving job to core data!")
                                }
                         
                            }) {
                                Image(systemName: "folder.badge.plus")
                                    .bold()
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarLeading) {
                            CloseButton{
                                dismiss()
                            }
                       
                        }
                        
                    }
                    
                    
                    
                }
            }
        }
    }
    
    private func saveJobToCoreData() {
        let newJob = Job(context: viewContext)
        newJob.name = name
        newJob.title = title
        newJob.hourlyPay = Double(hourlyPay) ?? 0.0
        newJob.clockInReminder = clockInReminder
        newJob.clockOutReminder = clockOutReminder
        newJob.tax = taxPercentage
        newJob.autoClockIn = autoClockIn
        newJob.autoClockOut = autoClockOut
        newJob.overtimeEnabled = overtimeEnabled
        newJob.overtimeAppliedAfter = overtimeAppliedAfter
        newJob.overtimeRate = overtimeRate
        newJob.icon = selectedIcon
        newJob.uuid = UUID()
        newJob.rosterReminder = rosterReminder
        newJob.rosterTime = selectedTime
        newJob.rosterDayOfWeek = Int16(selectedDay)
        
        let newLocation = JobLocation(context: viewContext)
        
        newLocation.address = selectedAddress
        print("Selected Address: \(String(describing: selectedAddress))")
        print("New Location Address: \(String(describing: newLocation.address))")
        newLocation.job = newJob
        newLocation.radius = selectedRadius
        
        newJob.addToLocations(newLocation)
        
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
            

                locationManager.startMonitoring(job: newJob) // might need to check clock out works with this, ive forgotten my implementation
            
            notificationManager.updateRosterNotifications(viewContext: viewContext)
            
            
           dismiss()
        } catch {
            print("Failed to save job: \(error.localizedDescription)")
        }
    }
    
    
    
    
}



