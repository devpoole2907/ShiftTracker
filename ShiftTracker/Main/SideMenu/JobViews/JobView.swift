//
//  JobView.swift
//  ShiftTracker
//
//  Created by James Poole on 4/07/23.
//

import SwiftUI
import UIKit
import MapKit
import CoreData

struct JobView: View {
    
    @AppStorage("isProVersion", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isProVersion = false
    
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var job: Job?
    @ObservedObject private var locationManager = LocationDataManager()
    
    @EnvironmentObject var viewModel: ContentViewModel
    private let addressManager = AddressManager()
    private let notificationManager = ShiftNotificationManager.shared
    
    @State private var miniMapAnnotation: IdentifiablePointAnnotation?
    @State private var name = ""
    @State private var title = ""
    @State private var hourlyPay: String = ""
    @State private var taxPercentage: Double = 0
    @State private var selectedColor = Color.cyan
    @State private var clockInReminder = false
    @State private var autoClockIn = false
    @State private var clockOutReminder = false
    @State private var autoClockOut = false
    
    @State private var payShakeTimes: CGFloat = 0
    @State private var nameShakeTimes: CGFloat = 0
    
    @State private var showOvertimeTimeView = false
    @State private var overtimeRate = 1.25
    @State private var overtimeAppliedAfter: TimeInterval = 8.0
    @State private var overtimeEnabled = false
    
    @State private var selectedIcon: String
    
    @State private var rosterReminder: Bool
    @State private var selectedDay: Int = 1
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
    init(job: Job? = nil) {
        self.job = job
        _name = State(initialValue: job?.name ?? "")
        _title = State(initialValue: job?.title ?? "")
        _hourlyPay = State(initialValue: "\(job?.hourlyPay ?? 0)")
        _taxPercentage = State(initialValue: job?.tax ?? 0)
        _selectedIcon = State(initialValue: job?.icon ?? "briefcase.circle")
        
        if let jobColorRed = job?.colorRed, let jobColorBlue = job?.colorBlue, let jobColorGreen = job?.colorGreen {
            _selectedColor = State(initialValue: Color(red: Double(jobColorRed), green: Double(jobColorGreen), blue: Double(jobColorBlue)))
        }
        
       
        
        // gets the first saved address, with the new address data model system for future multiple location implementation
        
        if let locationSet = job?.locations, let location = locationSet.allObjects.first as? JobLocation {
            _selectedAddress = State(initialValue: location.address)
            _selectedRadius = State(initialValue: location.radius)
            print("job has an address: \(location.address)")
        } else {
            print("job has no address")
            
        }

        
        
        _clockInReminder = State(initialValue: job?.clockInReminder ?? false)
        _clockOutReminder = State(initialValue: job?.clockOutReminder ?? false)
        _autoClockIn = State(initialValue: job?.autoClockIn ?? false)
        _autoClockOut = State(initialValue: job?.autoClockOut ?? false)
        _overtimeEnabled = State(initialValue: job?.overtimeEnabled ?? false)
        _overtimeRate = State(initialValue: job?.overtimeRate ?? 1.25)
        _overtimeAppliedAfter = State(initialValue: job?.overtimeAppliedAfter ?? 8.0)
        _rosterReminder = State(initialValue: job?.rosterReminder ?? false)
        _selectedDay = State(initialValue: Int(job?.rosterDayOfWeek ?? 1))
        _selectedTime = State(initialValue: job?.rosterTime ?? Date())
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
                            
                        }.background(Color("SquaresColor"))
                            .cornerRadius(20)
                        
                        
                        
                        if taxEnabled || taxPercentage > 0 {
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
                        .padding(.horizontal, 5)
                        
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
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding()
                    .navigationBarTitle(job != nil ? "Edit Job" : "Add Job", displayMode: .inline)

                    
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
                                    saveJob()
                                }
                                
                                
                                
                            }) {
                                Image(systemName: "folder.badge.plus")
                                    .bold()
                            }
                        }
                        if let job = job {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    
                                    dismiss()
                                    
                                    CustomConfirmationAlert(action: deleteJob, cancelAction: nil, title: "Are you sure? All associated previous and scheduled shifts will be deleted.").showAndStack()
                                    
                                    
                                }
                                ) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .bold()
                                }
                            }
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            CloseButton {
                                dismiss()
                            }
                        }
                        
                    }
                    
                }
            }
        }
    }
    
    private func saveJob() {
        
        var newJob: Job

        if let job = job {
            newJob = job
        } else {
            newJob = Job(context: viewContext)
            newJob.uuid = UUID()
        }

        
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
        newJob.rosterReminder = rosterReminder
        newJob.rosterTime = selectedTime
        newJob.rosterDayOfWeek = Int16(selectedDay)
        
        // replace this code with adding locations later when multiple address system update releases
        if let locationSet = job?.locations, let location = locationSet.allObjects.first as? JobLocation {
            location.address = selectedAddress
        } else { // for multi jobs we need this to add more
            let location = JobLocation(context: viewContext)
            location.address = selectedAddress
            job?.addToLocations(location)
        }

        

        
        
        let uiColor = UIColor(selectedColor)
        let (r, g, b) = uiColor.rgbComponents
        newJob.colorRed = r
        newJob.colorGreen = g
        newJob.colorBlue = b
        
        do {
            try viewContext.save()
            
        
                locationManager.startMonitoring(job: newJob) // might need to check clock out works with this, ive forgotten my implementation
            notificationManager.updateRosterNotifications(viewContext: viewContext)
            
            dismiss()
        } catch {
            print("Failed to save job: \(error.localizedDescription)")
        }
        
        if newJob.uuid == viewModel.selectedJobUUID {
            viewModel.hourlyPay = newJob.hourlyPay
            viewModel.saveHourlyPay()
            viewModel.taxPercentage = newJob.tax
            viewModel.saveTaxPercentage()
        }
        
        
    }
    
    private func deleteJob() {
        viewContext.delete(job!)
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
}

struct JobView_Previews: PreviewProvider {
    static var previews: some View {
        JobView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}


let jobIcons = [
    "briefcase.circle", "display", "tshirt.fill", "takeoutbag.and.cup.and.straw.fill", "trash.fill",
    "wineglass.fill", "cup.and.saucer.fill", "film.fill", "building.columns.circle.fill", "camera.fill", "camera.macro.circle", "bus.fill", "box.truck", "fuelpump.circle", "popcorn.circle", "cross.case.circle", "frying.pan", "cart.circle", "paintbrush", "wrench.adjustable"]

let jobColors = [
    Color.pink, Color.green, Color.blue, Color.purple, Color.orange, Color.cyan]


struct JobIconPicker: View {
    @Binding var selectedIcon: String
    var iconColor: Color
    @Environment(\.managedObjectContext) private var viewContext
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 50)), count: 4), spacing: 50) {
                    ForEach(jobIcons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            dismiss()
                        }) {
                            VStack {
                                Image(systemName: icon)
                                    .font(.title2)
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
