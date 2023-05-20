//
//  EditFirebaseJobView.swift
//  ShiftTracker
//
//  Created by James Poole on 30/04/23.
//

import SwiftUI
import UIKit
import CoreData
import Firebase
import MapKit

struct EditFirebaseJobView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var model = JobsViewModel()
    
    let jobToEdit: FirebaseJob
    
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
    @State private var selectedRadius: Double = 75
    
    @State private var showOvertimeTimeView = false
    
    @FocusState private var textIsFocused: Bool
    
    @State private var selectedIcon = "briefcase.circle"
    
    @State private var activeSheet: ActiveSheet?
    
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0074), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    enum ActiveSheet: Identifiable {
        case overtimeSheet, symbolSheet

        var id: Int {
            hashValue
        }
    }
    
    init(job: FirebaseJob) {
        self.jobToEdit = job
        _name = State(initialValue: job.name ?? "")
        _title = State(initialValue: job.title ?? "")
        _hourlyPay = State(initialValue: job.hourlyPay)
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
        _overtimeAppliedAfter = State(initialValue: TimeInterval(job.overtimeAppliedAfter))
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
                    NavigationLink(destination: AddressFinderView(selectedAddress: $selectedAddress, mapRegion: $mapRegion, selectedRadius: $selectedRadius)) {
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
            
            .navigationBarTitle("Edit Job")
            .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                updateJobInFirebase()
                            }) {
                                Text("Save")
                                    .bold()
                            }
                        }
                    }
            .toolbarRole(.editor)
            
        
    }

    
    private func updateJobInFirebase() {
            let uiColor = UIColor($selectedColor.wrappedValue)
            let colorComponents = uiColor.cgColor.components?.map { Float($0) } ?? [0, 0, 0, 0]

            // Update the existing job with new values
            model.updateData(
                jobToUpdate: jobToEdit,
                name: name,
                title: title,
                hourlyPay: hourlyPay,
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




    
    
    
    
    
}

struct EditFirebaseJobView_Previews: PreviewProvider {
    static var previews: some View {
        AddJobView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

