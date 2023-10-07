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
    
    @StateObject var jobViewModel: JobViewModel
    
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var job: Job?
    
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var contentViewModel: ContentViewModel
    @EnvironmentObject private var locationManager: LocationDataManager
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    private let addressManager = AddressManager()
    private let notificationManager = ShiftNotificationManager.shared
    
    @Binding var selectedJobForEditing: Job?
    @Binding var isEditJobPresented: Bool
    
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0074), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    @State private var miniMapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3308, longitude: -122.0074), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    
    // Initialize state properties with job values - we shouldnt need to pass the binding for the selected job to edit but here we are for now it works
    init(job: Job? = nil, isEditJobPresented: Binding<Bool>, selectedJobForEditing: Binding<Job?>) {
        self.job = job
        
        if job == nil {
            print("job is nil")
        }
        
        self._jobViewModel = StateObject(wrappedValue: JobViewModel(job: job))

        // shows clear button for textfields
                UITextField.appearance().clearButtonMode = .whileEditing
        
        _isEditJobPresented = isEditJobPresented
        _selectedJobForEditing = selectedJobForEditing
            
        
    }
    
    func formattedTimeInterval(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    
    var body: some View {
    
        
        NavigationStack{
            ZStack(alignment: .bottomTrailing){
                
                themeManager.contentDynamicBackground.opacity(jobViewModel.hasAppeared ? 0 : 1)
                    
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView{
                    VStack(spacing: 15){
                        GeometryReader { geometry in
                            let offset = geometry.frame(in: .global).minY
                            VStack{
                                Spacer()
                                ZStack {
                                    Image(systemName: jobViewModel.selectedIcon)
                                     
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .customAnimatedSymbol(value: $jobViewModel.selectedIcon)
                                        .customAnimatedSymbol(value: $jobViewModel.editToggle)
                                        .foregroundStyle(.white)
                                        .shadow(color: .white, radius: 0.7)
                                        .padding(20)
                                        .background {
                                            
                                            Circle()
                                                .foregroundStyle(jobViewModel.selectedColor.gradient)
                                            
                                            
                                        }
                                        .shadow(color: jobViewModel.selectedColor, radius: 4, x: 0, y: 0)
                                    VStack(alignment: .trailing){
                                        Spacer()
                                        Image(systemName: "pencil") .customAnimatedSymbol(value: $jobViewModel.editToggle)
                                            .font(.caption)
                            
                                            .padding(8)
                                            .background {
                                                
                                                Circle()
                                                    .foregroundStyle(Color("SquaresColor"))
                                                
                                                
                                            }
                                            .padding(.leading, 60)
                                            .padding(.top, 15)
                                        
                                    }
                                    
                                    
                                }
                                .scaleEffect(1 + (offset / 1000))
                                .onTapGesture {
                                    jobViewModel.activeSheet = .symbolSheet
                                    jobViewModel.editToggle.toggle()
                                }
                                .frame(maxWidth: .infinity)
                            }
                            
                        }.frame(height: 80)
                        
                        TextField("Company Name", text: $jobViewModel.name)
                           
                            .font(.title)
                            .bold()
                            .roundedFontDesign()
                            .foregroundStyle(jobViewModel.selectedColor.gradient)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .glassModifier(cornerRadius: 20)
                 
                            .padding(.horizontal)
                            .shake(times: jobViewModel.nameShakeTimes)
                           
                        
                    }
                    .padding(.vertical)
                    .glassModifier(cornerRadius: 20)
              
                    .padding(.horizontal)
                 
                    
                    
                    
                    
                    
                    
                    VStack(spacing: 15){
                        
                        
                        TextField("Job Title", text: $jobViewModel.title)
                            .roundedFontDesign()
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .glassModifier(cornerRadius: 20)
                            .shake(times: jobViewModel.titleShakeTimes)
                        
                        CurrencyTextField(placeholder: "Hourly Pay", text: $jobViewModel.hourlyPay)
                            .roundedFontDesign()
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .glassModifier(cornerRadius: 20)
                            .keyboardType(.decimalPad)
                            .shake(times: jobViewModel.payShakeTimes)

                            .haptics(onChangeOf: jobViewModel.payShakeTimes, type: .error)
                            .haptics(onChangeOf: jobViewModel.nameShakeTimes, type: .error)
                            .haptics(onChangeOf: jobViewModel.titleShakeTimes, type: .error)
                        
                        HStack(spacing: 0){
                            ForEach(1...6, id: \.self) { index in
                                let color = jobViewModel.jobColors[index - 1]
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(content: {
                                        if color == jobViewModel.selectedColor{
                                            Image(systemName: "circle.fill")
                                                .foregroundColor(.white.opacity(0.6))
                                                .font(.caption.bold())
                                            
                                        }
                                    })
                                    .onTapGesture {
                                        withAnimation{
                                            jobViewModel.selectedColor = color
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                            }
                            Divider()
                                .frame(height: 20)
                                .padding(.leading)
                            ColorPicker("", selection: $jobViewModel.selectedColor, supportsOpacity: false)
                                .padding()
                        }
                        
                        
                        
                        VStack(alignment: .leading, spacing: 10){
                            
                            
                            
                            VStack{
                                Toggle(isOn: $jobViewModel.clockInReminder) {
                                    Text("Remind me to clock in")
                                }
                                .disabled(jobViewModel.autoClockIn)
                                .onChange(of: jobViewModel.clockInReminder) { value in
                                    if value {
                                        jobViewModel.autoClockIn = false
                                    }
                                }
                                .toggleStyle(CustomToggleStyle())
                                .padding(.horizontal)
                                .padding(.top, 10)
                                
                                Toggle(isOn: $jobViewModel.clockOutReminder) {
                                    Text("Remind me to clock out")
                                }
                                .disabled(jobViewModel.autoClockOut)
                                .onChange(of: jobViewModel.clockOutReminder) { value in
                                    if value {
                                        jobViewModel.autoClockOut = false
                                    }
                                }
                                .toggleStyle(CustomToggleStyle())
                                .padding(.horizontal)
                                
                                Toggle(isOn: $jobViewModel.autoClockIn) {
                                    Text("Auto clock in")
                                }
                                .disabled(jobViewModel.clockInReminder)
                                .onChange(of: jobViewModel.autoClockIn) { value in
                                    if value {
                                        if !purchaseManager.hasUnlockedPro {
                                            
                                            jobViewModel.showProSheet.toggle()
                                            jobViewModel.autoClockIn = false
                                            
                                        } else {
                                            jobViewModel.clockInReminder = false
                                        }
                                    }
                                }
                                .toggleStyle(CustomToggleStyle())
                                .padding(.horizontal)
                                
                                Toggle(isOn: $jobViewModel.autoClockOut) {
                                    Text("Auto clock out")
                                }
                                .disabled(jobViewModel.clockOutReminder)
                                .onChange(of: jobViewModel.autoClockOut) { value in
                                    if value {
                                        if !purchaseManager.hasUnlockedPro {
                                            
                                            jobViewModel.showProSheet.toggle()
                                            jobViewModel.autoClockOut = false
                                            
                                        } else {
                                            jobViewModel.clockOutReminder = false
                                        }
                                    }
                                }
                                .toggleStyle(CustomToggleStyle())
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                                
                                if #available(iOS 17.0, *){
                                    
                                    NavigationLink(destination: AddressFinderMap(selectedAddressString: $jobViewModel.selectedAddress, selectedRadius: $jobViewModel.selectedRadius, iconColor: jobViewModel.selectedColor, icon: jobViewModel.selectedIcon)
                                        .onDisappear {
                                            self.miniMapRegion = self.mapRegion
                                        }){
                                            VStack(alignment: .leading){
                                                
                                                Map(coordinateRegion: $miniMapRegion, interactionModes: [], showsUserLocation: true, annotationItems: jobViewModel.miniMapAnnotation != nil ? [jobViewModel.miniMapAnnotation!] : []) { annotation in
                                                    MapAnnotation(coordinate: annotation.coordinate) {
                                                        VStack {
                                                            Image(systemName: jobViewModel.selectedIcon)
                                                                .font(.title2)
                                                                .foregroundStyle(.white)
                                                                .padding(10)
                                                                .background{
                                                                    Circle()
                                                                        .foregroundStyle(jobViewModel.selectedColor.gradient)
                                                                    
                                                                }
                                                            
                                                        }
                                                    }
                                                }
                                                .onAppear{
                                                    //locationManager.requestAuthorization()
                                                    addressManager.loadSavedAddress(selectedAddressString: jobViewModel.selectedAddress) { region, annotation in
                                                        self.miniMapRegion = region ?? self.miniMapRegion
                                                        jobViewModel.miniMapAnnotation = annotation
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
                                    
                                } else {
                                    
                                    
                                    
                                    NavigationLink(destination: AddressFinderView(selectedAddress: $jobViewModel.selectedAddress, mapRegion: $mapRegion, selectedRadius: $jobViewModel.selectedRadius, icon: jobViewModel.selectedIcon, iconColor: jobViewModel.selectedColor)
                                        .onDisappear {
                                            self.miniMapRegion = self.mapRegion
                                        }) {
                                            VStack(alignment: .leading){
                                                
                                                Map(coordinateRegion: $miniMapRegion, interactionModes: [], showsUserLocation: true, annotationItems: jobViewModel.miniMapAnnotation != nil ? [jobViewModel.miniMapAnnotation!] : []) { annotation in
                                                    MapAnnotation(coordinate: annotation.coordinate) {
                                                        VStack {
                                                            Image(systemName: jobViewModel.selectedIcon)
                                                                .font(.title2)
                                                                .foregroundStyle(.white)
                                                                .padding(10)
                                                                .background{
                                                                    Circle()
                                                                        .foregroundStyle(jobViewModel.selectedColor.gradient)
                                                                    
                                                                }
                                                            
                                                        }
                                                    }
                                                }
                                                .onAppear{
                                                    //locationManager.requestAuthorization()
                                                    addressManager.loadSavedAddress(selectedAddressString: jobViewModel.selectedAddress) { region, annotation in
                                                        self.miniMapRegion = region ?? self.miniMapRegion
                                                        jobViewModel.miniMapAnnotation = annotation
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
                                
                            }
                            
                        }.glassModifier(cornerRadius: 20)
                        
                        
                        
                        if taxEnabled || jobViewModel.taxPercentage > 0 {
                            EstTaxPicker(taxPercentage: $jobViewModel.taxPercentage, isEditing: .constant(true))
                            
                        }
                        
                
                        
                        VStack(alignment: .leading, spacing: 10){
                            Toggle(isOn: $jobViewModel.rosterReminder){
                                
                                Text("Roster reminders")
                                
                            }.toggleStyle(CustomToggleStyle())
                                .padding(.horizontal)
                                .padding(.top, 10)
                            HStack{
                                Text("Time")
                                Spacer()
                                DatePicker("Time", selection: $jobViewModel.selectedTime, displayedComponents: .hourAndMinute).labelsHidden()
                                Picker(selection: $jobViewModel.selectedDay, label: Text("Day of the week")) {
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
                                .disabled(!jobViewModel.rosterReminder)
                            
                            
                            
                        }.glassModifier(cornerRadius: 20)
                        
                        VStack(alignment: .leading, spacing: 10){
                            Toggle(isOn: $jobViewModel.breakReminder){
                                
                                Text("Break reminder")
                                
                            }.toggleStyle(CustomToggleStyle())
                           
                            
                            if #available(iOS 16.1, *){
                                
                                HStack {
                                   
                                    Text("When:")
                                    TimePicker(timeInterval: $jobViewModel.breakRemindAfter)
                                        .frame(maxHeight: 75)
                                        .frame(maxWidth: getRect().width - 100)
                                    
                                }
                                .disabled(!jobViewModel.breakReminder)
                                .opacity(jobViewModel.breakReminder ? 1.0 : 0.5)
                    
                                
                            } else {
                                
                                // due to a frame issue with overtime views pickers on iOS 16 or lower, overtime view is a sheet in those versions
                                
                                Button(action: { jobViewModel.activeSheet = .breakRemindSheet }){
                                    HStack {
                                    
                                        Text("When: ")
                                        Spacer()
                                        Text("\(formattedTimeInterval(jobViewModel.breakRemindAfter))")
                                        
                                        
                                    }
                                }
                            }
                            
                            
                        }.padding(.horizontal)
                            .padding(.vertical, 10)
                            .glassModifier(cornerRadius: 20)
                    
                        
                        VStack(alignment: .leading, spacing: 10){
                            Toggle(isOn: $jobViewModel.overtimeEnabled) {
                                HStack {
                                    Text("Overtime")
                                }
                            }
                            .toggleStyle(CustomToggleStyle())
                            
                            Stepper(value: $jobViewModel.overtimeRate, in: 1.25...3, step: 0.25) {
                                
                                
                                Text("Rate: \(jobViewModel.overtimeRate, specifier: "%.2f")x")
                                
                            }.disabled(!jobViewModel.overtimeEnabled)
                            
                            if #available(iOS 16.1, *){
                                
                                HStack {
                                 
                                    Text("Apply after:")
                                    TimePicker(timeInterval: $jobViewModel.overtimeAppliedAfter)
                                        .frame(maxHeight: 75)
                                        .frame(maxWidth: getRect().width - 100)
                                    
                                }
                                .disabled(!jobViewModel.overtimeEnabled)
                                .opacity(jobViewModel.overtimeEnabled ? 1.0 : 0.5)
                                .shake(times: jobViewModel.overtimeShakeTimes)
                                
                            } else {
                                
                                // due to a frame issue with overtime views pickers on iOS 16 or lower, overtime view is a sheet in those versions
                                
                                Button(action: { jobViewModel.activeSheet = .overtimeSheet }){
                                    HStack {
                                        
                                        Text("Apply after: ")
                                        Spacer()
                                        Text("\(formattedTimeInterval(jobViewModel.overtimeAppliedAfter))")
                                        
                                        
                                    }
                                }
                            }
                            
                            
                        }.padding(.horizontal)
                            .padding(.vertical, 10)
                            .glassModifier(cornerRadius: 20)
                    
                        
                    }
                     .frame(maxHeight: .infinity, alignment: .top)
                    .padding()
                    .navigationTitle(job != nil ? "Edit Job" : "Add Job")
                    
                    .navigationBarTitleDisplayMode(.inline)
                    
                    .fullScreenCover(isPresented: $jobViewModel.showProSheet){
                        
                        
                        ProView()
                        
                            .customSheetBackground()
                        
                        
                    }
                    
                    .sheet(item: $jobViewModel.activeSheet){ item in
                        
                        switch item {
                        case .overtimeSheet:
                         
                            TimePicker(timeInterval: $jobViewModel.overtimeAppliedAfter)
                                .environment(\.managedObjectContext, viewContext)
                                
                           
                                .presentationDragIndicator(.visible)
                                .presentationDetents([ .fraction(0.4)])
                             
                            
                            
                            
                        case .symbolSheet:
                            JobIconPicker()
                                .environment(\.managedObjectContext, viewContext)
                                .environmentObject(jobViewModel)
                                .presentationDetents([ .medium, .fraction(0.7)])
                                .presentationDragIndicator(.visible)
                                .customSheetBackground()
                                .customSheetRadius(35)
                                .customSheetBackgroundInteraction()
                            
                            
                        case .breakRemindSheet:
                            TimePicker(timeInterval: $jobViewModel.breakRemindAfter)
                                .environment(\.managedObjectContext, viewContext)
                                
                           
                                .presentationDragIndicator(.visible)
                                .presentationDetents([ .fraction(0.4)])
                            
                        }
                        
                    }
                    
                    
                    
                }
                HStack(spacing: 10){
                    
             
                    
                    Button(action: {
                        
                        jobViewModel.buttonBounce.toggle()
                        
                        if jobViewModel.name.isEmpty {
                            withAnimation(.linear(duration: 0.4)) {
                                jobViewModel.nameShakeTimes += 2
                            }
                        }
                        else if jobViewModel.hourlyPay.isEmpty || jobViewModel.hourlyPay == "0.0" {
                            withAnimation(.linear(duration: 0.4)) {
                                jobViewModel.payShakeTimes += 2
                            }
                        } else if jobViewModel.title.isEmpty {
                            withAnimation(.linear(duration: 0.4)) {
                                jobViewModel.titleShakeTimes += 2
                            }
                            
                            
                        } else if jobViewModel.overtimeEnabled && jobViewModel.overtimeAppliedAfter == 0 {
                            withAnimation(.linear(duration: 0.4)) {
                                jobViewModel.overtimeShakeTimes += 2
                            }
                        }
                        else {
                            jobViewModel.saveJob(in: viewContext){
                                locationManager.startMonitoringAllLocations()
                                notificationManager.updateRosterNotifications(viewContext: viewContext)

                               


                                // checks if content views selected job is this job
                                
                                if let jobUUID = jobViewModel.job?.uuid {
                                    if jobUUID == contentViewModel.selectedJobUUID {
                                        contentViewModel.hourlyPay = jobViewModel.job!.hourlyPay
                                        contentViewModel.saveHourlyPay()
                                        contentViewModel.taxPercentage = jobViewModel.job!.tax
                                        contentViewModel.saveTaxPercentage()
                                    }
                                    
                                    
                                    
                                    
                                    // checks if this is the overall selected job
                                    if jobUUID == selectedJobManager.selectedJobUUID {
                                        print("its the selected job yes")
                                        
                                        //   jobSelectionViewModel.deselectJob(shiftViewModel: viewModel) DOES IT NEED TO BE DESELECTED?
                                        
                                        selectedJobManager.updateJob(jobViewModel.job!)
                                        
                                        
                                        
                                    }
                                }
                            }
                            
                            dismiss()
                            
                        }
                        
                        
                        
                    }) {
                        Image(systemName: "folder.badge.plus").customAnimatedSymbol(value: $jobViewModel.buttonBounce)
                            .bold()
                    }
                    
                    if job != nil {
                        
                        Divider().frame(maxHeight: 10)
                        
                      
                            Button(action: {
                                
                                dismiss()
                             
                                CustomConfirmationAlert(action: {
                                    
                                    jobViewModel.deleteJob(in: viewContext, selectedJobManager: selectedJobManager){
                                        notificationManager.scheduleNotifications()
                                        notificationManager.updateRosterNotifications(viewContext: viewContext)
                                        locationManager.startMonitoringAllLocations()
                                    }
                                    
                                }, cancelAction: {
                                    isEditJobPresented = true
                                    selectedJobForEditing = job
                                    
                                    
                                }, title: "Are you sure? All associated previous and scheduled shifts will be deleted.").showAndStack()
                                
                                
                            }
                            ) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .bold()
                            }
                        
                    }
                    
                    
                    
                }.padding()
                    .glassModifier(cornerRadius: 20)
                
                    .padding()
                 //   .shadow(radius: 3)
                
            }.onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        jobViewModel.hasAppeared = true
                    }
                }
            }
                
                .toolbar{
                    ToolbarItemGroup(placement: .keyboard){
                        Spacer()
                        
                        Button("Done"){
                            hideKeyboard()
                        }
                    }
                    
                 
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseButton()
                    }
                    
                }
        }.background(Color.clear)
    }
    

    
}



struct JobIconPicker: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var jobViewModel: JobViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 50)), count: 4), spacing: 50) {
                    ForEach(jobViewModel.jobIcons, id: \.self) { icon in
                        Button(action: {
               
                            jobViewModel.selectedIcon = icon
                            
                            dismiss()
                        }) {
                            VStack {
                                Image(systemName: icon)
                                    .font(.title2)
                                
                                    .frame(height: 20)
                                    .shadow(color: .white, radius: 0.7)
                                    .foregroundStyle(.white)
                                
                            }.padding()
                            .background{
                                Circle()
                                    .foregroundStyle(jobViewModel.selectedColor.gradient)
                                    
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Icon", displayMode: .inline)
            
            
            .toolbar {
                
                
                CloseButton()
                
            }
            
        }
    }
}
