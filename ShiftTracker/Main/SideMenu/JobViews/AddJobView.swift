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
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var model = JobsViewModel()
    
    @ObservedObject private var locationManager = LocationDataManager()
    
    private let addressManager = AddressManager()
    
    @State private var name = ""
    @State private var title = ""
    @State private var hourlyPay: String = ""
    @State private var taxPercentage: Double = 0
    @State private var payPeriodLength = ""
    @State private var payPeriodStartDay: Int? = nil
    @State private var selectedColor = Color.cyan
    @State private var clockInReminder = true
    @State private var autoClockIn = false
    @State private var clockOutReminder = true
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
    
    
    
    @State private var showOvertimeTimeView = false
    
    @FocusState private var textIsFocused: Bool
    
    @State private var selectedIcon = "briefcase.circle"
    
    @State private var activeSheet: ActiveSheet?
    
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0074), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    @State private var miniMapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0074), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    enum ActiveSheet: Identifiable {
        case overtimeSheet, symbolSheet
        
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
                                    
                                NavigationLink(destination: AddressFinderView(selectedAddress: $selectedAddress, mapRegion: $mapRegion, selectedRadius: $selectedRadius, iconColor: selectedColor)
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
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                            .padding(.horizontal, 10)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10){
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
                        }.padding(.horizontal, 5)
                        
                        
                        
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
                                // if isSubscriptionActive() {
                                //    saveJobToFirebase()
                                //    print("saving job to firebase!")
                                //} else {
                                
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
                                //}
                            }) {
                                Text("Save")
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
    
    private func saveJobToFirebase() {
        let uiColor = UIColor($selectedColor.wrappedValue)
        let colorComponents = uiColor.cgColor.components?.map { Float($0) } ?? [0, 0, 0, 0]
        
        
        model.addData(
            name: name,
            title: title,
            hourlyPay: Double(hourlyPay) ?? 0,
            address: selectedAddress ?? "",
            clockInReminder: clockInReminder,
            clockOutReminder: clockOutReminder,
            autoClockIn: autoClockIn,
            autoClockOut: autoClockOut,
            overtimeEnabled: overtimeEnabled,
            overtimeAppliedAfter: Int16(overtimeAppliedAfter),
            overtimeRate: overtimeRate,
            icon: selectedIcon,
            colorRed: colorComponents[0],
            colorGreen: colorComponents[1],
            colorBlue: colorComponents[2],
            payPeriodLength: Int16(payPeriodLength) ?? 0,
            payPeriodStartDay: Int16(payPeriodStartDay ?? 0)
        )
        presentationMode.wrappedValue.dismiss()
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
        
        let newLocation = JobLocation(context: viewContext)
        
        newLocation.address = selectedAddress
        print("Selected Address: \(String(describing: selectedAddress))")
        print("New Location Address: \(String(describing: newLocation.address))")
        newLocation.job = newJob
        newLocation.radius = selectedRadius ?? 75
        
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

let jobColors = [
    Color.pink, Color.green, Color.blue, Color.purple, Color.orange, Color.cyan]


struct JobIconPicker: View {
    @Binding var selectedIcon: String
    var iconColor: Color
    @Environment(\.managedObjectContext) private var viewContext
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 50)), count: 4), spacing: 50) {
                    ForEach(jobIcons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            presentationMode.wrappedValue.dismiss()
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

struct CurrencyTextField: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(Locale.current.currencySymbol ?? "")
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
        }
    }
}
