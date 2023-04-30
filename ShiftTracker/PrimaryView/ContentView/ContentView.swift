//
//  ContentView.swift
//  ShiftTracker
//
//  Created by James Poole on 18/03/23.
//

import SwiftUI
import CoreData
import CloudKit
import UIKit
import CoreHaptics
import Haptics
import CoreLocation

struct ContentView: View {
    
    
    //TESTING:
    
    @ObservedObject var locationManager: LocationDataManager = LocationDataManager()
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.managedObjectContext) private var context
    
    
    @Environment(\.presentationMode) private var presentationMode
    
    @StateObject var viewModel = ContentViewModel()
    
    @State private var activeSheet: ActiveSheet?
    
    @State private var payShakeTimes: CGFloat = 0
    @State private var jobShakeTimes: CGFloat = 0
    
    private let shiftKeys = ShiftKeys()
    
    
    @FocusState private var payIsFocused: Bool
    
    @AppStorage("autoClockIn") private var autoClockIn: Bool = false
    @AppStorage("autoClockOut") private var autoClockOut: Bool = false
    @AppStorage("clockInReminder") private var clockInReminder: Bool = false
    @AppStorage("clockOutReminder") private var clockOutReminder: Bool = false
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    
    @AppStorage("isProVersion", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isProVersion = false
    
    @State  var isAnimating = false
    
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var shifts: FetchedResults<OldShift>
    
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    
    //@ObservedObject var locationUpdateManager = LocationUpdateManager()
    
    
    @Binding var showMenu: Bool
    
    
    
    
    
    @available(iOS 16.1, *)
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        let backgroundColor: Color = colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : .white
        let buttonColor: Color = colorScheme == .dark ? Color.gray.opacity(0.5) : Color.black
        let disabledButtonColor: Color = colorScheme == .dark ? Color.gray.opacity(0.2) : Color.primary.opacity(0.8)
        let bigImageColor: Color = colorScheme == .dark ? Color.gray.opacity(0.06) : Color.gray.opacity(0.05)
        
        // VStack{
        NavigationStack{
            VStack{
                VStack(spacing: 0){
                    HStack{
                    Button{
                        withAnimation{
                            showMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "person.2.badge.gearshape")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 35, height: 35)
                            //.clipShape(Circle())
                    }
                    .foregroundColor(.black)
                    Spacer()
                    }.padding(.horizontal)
                        .padding(.vertical, 10)
                    
                }
            }
            
            
            ZStack{
                VStack(alignment: .trailing){
                    
                    HStack{
                        Spacer()
                        
                        Image("HomeIconSymbol")
                            .font(.system(size: 200))
                            .foregroundColor(bigImageColor)
                            .rotationEffect(Angle(degrees: 345))
                            .ignoresSafeArea()
                        
                    }
                    .padding(.top, 0)
                    .padding(.trailing, -55)
                    
                    Spacer()
                    //Spacer(minLength: 600)
                }.blur(radius: colorScheme == .dark ? 3.0 : 0)
                ScrollView{
                    Section{
                        TimerView(timeElapsed: $viewModel.timeElapsed)
                    }
                    Section{
                        if viewModel.shift == nil{
                            Text("No current shift")
                                .bold()
                                .padding()
                        }
                        
                        else if viewModel.isOnBreak {
                            VStack{
                                HStack{
                                    BreakTimerView(timeElapsed: $viewModel.breakTimeElapsed)
                                    
                                    DatePicker("Break start: ", selection: Binding(get: { viewModel.tempBreaks.last?.startDate ?? Date() }, set: { newDate in
                                        viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate = newDate }), displayedComponents: [.hourAndMinute])
                                    .onChange(of: viewModel.tempBreaks.last?.startDate){ newDate in
                                        if let newDate = newDate, newDate > Date() {
                                            viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate = Date()
                                        }
                                        if newDate ?? Date() > Date(){
                                            viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate = Date()
                                        }
                                        if newDate ?? Date() < viewModel.shiftStartDate{
                                            viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate = viewModel.shiftStartDate
                                        }
                                        viewModel.stopTimer(timer: &viewModel.breakTimer, timeElapsed: &viewModel.breakTimeElapsed)
                                        viewModel.startBreakTimer(startDate: viewModel.tempBreaks.last?.startDate ?? Date())
                                        
                                    }
                                    .disabled(viewModel.shift == nil || !viewModel.isEditing)
                                    
                                    .bold()
                                    
                                    .padding(.vertical, 8)
                                    
                                    
                                }.padding(.horizontal, 75)
                                
                            }
                        }
                        else{
                            DatePicker("Shift start: ", selection: $viewModel.shiftStartDate, displayedComponents: [.hourAndMinute])
                                .onChange(of: viewModel.shiftStartDate) { newDate in
                                    if newDate > Date(){
                                        viewModel.shiftStartDate = Date()
                                    }
                                    if let currentShift = viewModel.shift {
                                        viewModel.shift = Shift(startDate: newDate, hourlyPay: currentShift.hourlyPay)
                                    }
                                    sharedUserDefaults.set(newDate, forKey: shiftKeys.shiftStartDateKey)
                                    viewModel.stopTimer(timer: &viewModel.timer, timeElapsed: &viewModel.timeElapsed)
                                    //  stopActivity()
                                    // stopActivity()
                                    viewModel.startTimer(startDate: newDate)
                                }
                            
                                .disabled(viewModel.breakTaken || viewModel.shift == nil || !viewModel.isEditing)
                            
                                .bold()
                                .padding(.horizontal, 75)
                                .padding(.vertical, 8)
                        }
                        
                    }
                    Section{
                        VStack{
                            
                            // DISABLED FOR REWRITES!!!!
                            
                            
                            HStack {
                                
                                Text("Hourly pay:")
                                    .foregroundColor(viewModel.shift == nil || viewModel.isEditing ? Color.white.opacity(0.8) : Color.white.opacity(0.5))
                                //Spacer()
                                TextField("", value: $viewModel.hourlyPay, format: .currency(code: Locale.current.currency?.identifier ?? "NZD"))
                                    .keyboardType(.decimalPad)
                                    .focused($payIsFocused)
                                    .disabled(!viewModel.isEditing && viewModel.shift != nil)
                                    .foregroundColor(viewModel.shift == nil || viewModel.isEditing ? Color.white.opacity(0.8) : Color.white.opacity(0.5))
                                    .onChange(of: viewModel.hourlyPay) { _ in
                                        viewModel.saveHourlyPay() // Save the value of hourlyPay whenever it changes
                                    }
                                
                            }.frame(minWidth: UIScreen.main.bounds.width / 3)
                                .bold()
                            
                                .padding(.horizontal, 20)
                                .padding(.vertical, 11)
                                .background(viewModel.shift == nil || viewModel.isEditing ? buttonColor : disabledButtonColor)
                            //.background(Color.gray.opacity(0.5))
                                .foregroundColor(.white)
                                .cornerRadius(18)
                                .shake(times: payShakeTimes)
                            
                            
                            /*    TaxPickerView(taxPercentage: $viewModel.taxPercentage).background(viewModel.shift == nil || viewModel.isEditing ? buttonColor : disabledButtonColor).cornerRadius(20).disabled(!viewModel.isEditing && viewModel.shift != nil) */
                            
                            
                            
                            
                            // DISABLED FOR REWRITES!!!!!!!!
                        /*    if taxEnabled {
                                Button(action: {
                                    activeSheet = .sheet5
                                }) {
                                    HStack {
                                        Text("Estimated Tax:")
                                        Spacer()
                                        Text("\(String(format: "%.1f", viewModel.taxPercentage))%")
                                    }
                                }
                                .disabled(!viewModel.isEditing && viewModel.shift != nil)
                                .foregroundColor(viewModel.shift == nil || viewModel.isEditing ? Color.white.opacity(0.8) : Color.white.opacity(0.5))
                                .onChange(of: viewModel.taxPercentage) { _ in
                                    viewModel.saveTaxPercentage() // Save the value of hourlyPay whenever it changes
                                }
                                .frame(minWidth: UIScreen.main.bounds.width / 3)
                                .bold()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 11)
                                .background(viewModel.shift == nil || viewModel.isEditing ? buttonColor : disabledButtonColor)
                                .cornerRadius(18)
                            } */
                            
                            Button(action: {
                                activeSheet = .sheet8
                            }) {
                                HStack {
                                    Text("Job:")
                                        .bold()
                                    Spacer()
                                    if let job = viewModel.fetchJob(with: viewModel.selectedJobUUID, in: context) {
                                        Image(systemName: job.icon ?? "briefcase.circle")
                                            .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                                        Text(job.name ?? "No Job Selected")
                                            .bold()
                                    } else {
                                        Image(systemName: "briefcase.circle")
                                            .foregroundColor(.cyan)
                                        Text("No Job Selected")
                                            .bold()
                                    }
                                }
                            }
                            .disabled(viewModel.shift != nil)
                            .foregroundColor(Color.white.opacity(0.8))
                            .frame(minWidth: UIScreen.main.bounds.width / 3)
                            .bold()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 11)
                            .background(buttonColor)
                            .cornerRadius(18)
                            .shake(times: jobShakeTimes)
                            
                            
                        }
                        .padding(.horizontal, 50)
                        Section{
                            HStack{
                                
                                if viewModel.shift == nil {
                                    Button(action: {
                                        //viewModel.startShiftButtonAction()
                                        
                                        
                                        
                                        if viewModel.hourlyPay == 0 {
                                            withAnimation(.linear(duration: 0.4)) {
                                                payShakeTimes += 2
                                            }
                                            
                                        }
                                        if viewModel.selectedJobUUID == nil {
                                            withAnimation(.linear(duration: 0.4)) {
                                                jobShakeTimes += 2
                                            }
                                            
                                        }
                                        
                                        
                                        if viewModel.hourlyPay != 0 && viewModel.selectedJobUUID != nil {
                                            activeSheet = .sheet6
                                            withAnimation {
                                                viewModel.isStartShiftTapped = true
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    viewModel.isStartShiftTapped = false
                                                }
                                            }
                                        }
                                    }){
                                        Text("Start shift")
                                            .frame(minWidth: UIScreen.main.bounds.width / 3)
                                            .bold()
                                            .padding()
                                            .background(buttonColor)
                                            .foregroundColor(.white)
                                            .cornerRadius(18)
                                        
                                    }
                                    
                                    .onAppear(perform: viewModel.prepareHaptics)
                                    .frame(maxWidth: .infinity)
                                    .scaleEffect(viewModel.isStartShiftTapped ? 1.1 : 1)
                                    .animation(.easeInOut(duration: 0.3))
                                    
                                    
                                } else {
                                    if !viewModel.isOnBreak{
                                        Button(action: {
                                            activeSheet = .sheet2
                                            
                                            //viewModel.startBreakButtonAction()
                                            
                                            self.isAnimating = true
                                            withAnimation {
                                                viewModel.isBreakTapped = true
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    viewModel.isBreakTapped = false
                                                }
                                            }
                                        }) {
                                            Text("Start break")
                                            
                                                .frame(minWidth: UIScreen.main.bounds.width / 3)
                                                .bold()
                                                .padding()
                                                .background(!viewModel.isEditing ? buttonColor : disabledButtonColor)
                                                .foregroundColor(.white)
                                                .cornerRadius(18)
                                        }.disabled(viewModel.isEditing)
                                        //.disabled(viewModel.breakTaken)
                                            .contextMenu{
                                                Button("\(Image(systemName: "stopwatch")) Deduct 30m break"){
                                                    
                                                }
                                                Button("\(Image(systemName: "stopwatch")) Deduct 15m break"){
                                                    
                                                }
                                            }
                                            .actionSheet(isPresented: $viewModel.showStartBreakAlert) {
                                                ActionSheet(title: Text("Select Break Type"), buttons: [
                                                    .destructive(Text("Unpaid Break"), action: { viewModel.startBreak(startDate: Date(), isUnpaid: true)}),
                                                    .default(Text("Paid Break"), action: { viewModel.startBreak(startDate: Date(), isUnpaid: false)}),
                                                    .cancel()
                                                ])
                                            }
                                            .frame(maxWidth: .infinity)
                                            .scaleEffect(viewModel.isBreakTapped ? 1.1 : 1)
                                            .animation(.easeInOut(duration: 0.3))
                                        
                                    }
                                    else {
                                        Button(action: {
                                            //viewModel.endBreakButtonAction()
                                            
                                            activeSheet = .sheet4
                                            
                                            self.isAnimating = true
                                            withAnimation {
                                                viewModel.isBreakTapped = true
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    viewModel.isBreakTapped = false
                                                }
                                            }
                                        }) {
                                            Text("End break")
                                            
                                                .frame(minWidth: UIScreen.main.bounds.width / 3)
                                                .bold()
                                                .padding()
                                                .background(buttonColor)
                                                .foregroundColor(.white)
                                                .cornerRadius(18)
                                        }
                                        .alert(isPresented: $viewModel.showEndBreakAlert) {
                                            Alert(
                                                title: Text("End break?"),
                                                //message: Text("Are you sure you want to end this shift?"),
                                                primaryButton: .destructive(Text("End break")) {
                                                    viewModel.endBreak()
                                                    presentationMode.wrappedValue.dismiss()
                                                },
                                                secondaryButton: .cancel(){
                                                    
                                                }
                                            )
                                        }
                                        
                                        .frame(maxWidth: .infinity)
                                        .scaleEffect(viewModel.isBreakTapped ? 1.1 : 1)
                                        .animation(.easeInOut(duration: 0.3))
                                    }
                                    
                                    
                                }
                                Button(action: {
                                    
                                    activeSheet = .sheet3
                                    
                                    //viewModel.endShiftButtonAction()
                                    self.isAnimating = true
                                    withAnimation {
                                        viewModel.isEndShiftTapped = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            viewModel.isEndShiftTapped = false
                                        }
                                    }
                                }) {
                                    Text("End shift")
                                    
                                        .frame(minWidth: UIScreen.main.bounds.width / 3)
                                        .bold()
                                        .padding()
                                        .background((viewModel.shift == nil || (viewModel.shift != nil && viewModel.isOnBreak) || viewModel.isEditing) ? disabledButtonColor : buttonColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(18)
                                }.disabled(viewModel.shift == nil || viewModel.isOnBreak || viewModel.isEditing)
                                    .alert(isPresented: $viewModel.showEndAlert) {
                                        
                                        Alert(
                                            title: Text("End shift?"),
                                            message: Text("Are you sure you want to end this shift?"),
                                            primaryButton: .destructive(Text("End shift")) {
                                                viewModel.endShift(using: context, endDate: Date())
                                                presentationMode.wrappedValue.dismiss()
                                            },
                                            secondaryButton: .cancel(){
                                                
                                            }
                                        )
                                    }
                                    .frame(maxWidth: .infinity)
                                    .scaleEffect(viewModel.isEndShiftTapped ? 1.1 : 1)
                                    .animation(.easeInOut(duration: 0.3))
                            }.haptics(onChangeOf: payShakeTimes, type: .error)
                                .haptics(onChangeOf: activeSheet, type: .light)
                                .haptics(onChangeOf: jobShakeTimes, type: .error)
                            
                            
                        }.padding(.horizontal, 50)
                        
                        Section {
                            VStack{
                                Button(action: {
                                    activeSheet = .sheet7
                                }) {
                                    Text("Breaks")
                                    
                                }
                                .foregroundColor(.white.opacity(0.8))
                                .accentColor(.white.opacity(0.7))
                                .frame(minWidth: UIScreen.main.bounds.width / 3)
                                .bold()
                                
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                                .background(!viewModel.tempBreaks.isEmpty ? buttonColor : disabledButtonColor)
                                //.background(buttonColor)
                                //.foregroundColor(.white)
                                .cornerRadius(18)
                            }.padding(.horizontal, 50)
                        }.disabled(viewModel.tempBreaks.isEmpty)
                        
                        
                        
                        
                    }
                    /*  Section{
                     NavigationLink(destination: MoreOptionsView().navigationBarTitle(Text("Shift Settings"))){
                     Text("Shift settings")
                     // .foregroundColor(shift == nil ? Color.white.opacity(0.8) : Color.white.opacity(0.5))
                     .foregroundColor(.white.opacity(0.8))
                     .accentColor(.white.opacity(0.7))
                     .frame(minWidth: UIScreen.main.bounds.width / 3)
                     .bold()
                     
                     .padding(.horizontal, 20)
                     .padding(.vertical, 5)
                     //.background(shift == nil ? buttonColor : disabledButtonColor)
                     .background(buttonColor)
                     //.foregroundColor(.white)
                     .cornerRadius(18)
                     }
                     
                     } */
                    
                }
            }
            .frame(maxWidth: .infinity)
            .toolbar{
                ToolbarItemGroup(placement: .keyboard){
                    Spacer()
                    
                    Button("Done"){
                        payIsFocused = false
                    }
                }
            }
           // .navigationBarTitle(isProVersion ? Text("ShiftTracker Pro") : Text("ShiftTracker"))
         /*   .toolbar{
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isEditing {
                        Button("Done") {
                            if viewModel.isOnBreak && viewModel.tempBreaks[viewModel.tempBreaks.count - 1].isUnpaid{
                                viewModel.updateActivity(startDate: viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate)
                                
                            }
                            else {
                                viewModel.updateActivity(startDate: viewModel.shift?.startDate.addingTimeInterval(viewModel.totalBreakDuration()) ?? Date())
                            }
                            withAnimation {
                                viewModel.isEditing.toggle()
                            }
                        }
                        
                        .disabled(viewModel.shift == nil)
                    } else {
                        Button("\(Image(systemName: "pencil"))") {
                            withAnimation {
                                viewModel.isEditing.toggle()
                                
                            }
                        }
                        
                        
                        .disabled(viewModel.shift == nil)
                    }
                }
            } .haptics(onChangeOf: viewModel.isEditing, type: .light) */
        }
        //}
        
        .sheet(item: $activeSheet){ item in
            
            if #available(iOS 16.4, *) {
                
                switch item {
                case .sheet1:
                    if let thisShift = shifts.first{
                        NavigationStack{
                            DetailView(shift: thisShift).navigationBarTitle("Shift Ended")
                                .environment(\.managedObjectContext, context)
                        }.presentationDetents([ .large])
                        // .presentationBackground(.ultraThinMaterial)
                            .presentationDragIndicator(.visible)
                            .presentationCornerRadius(50)
                    }
                case .sheet2:
                    ActionView(viewModel: viewModel, activeSheet: $activeSheet, navTitle: "Start Break", pickerStartDate: viewModel.tempBreaks.isEmpty ? viewModel.shift?.startDate : viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate, actionType: .startBreak)
                    //StartBreakView(viewModel: viewModel)
                        .environment(\.managedObjectContext, context)
                        .presentationDetents([ .fraction(0.4)])
                    // .presentationBackground(.ultraThinMaterial)
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(50)
                    
                case .sheet3:
                    ActionView(viewModel: viewModel, activeSheet: $activeSheet, navTitle: "End Shift", pickerStartDate: viewModel.tempBreaks.isEmpty ? viewModel.shift?.startDate : viewModel.tempBreaks[viewModel.tempBreaks.count - 1].endDate, actionType: .endShift)
                    //EndShiftConfirmView(activeSheet: $activeSheet, viewModel: viewModel).navigationBarTitle("End Shift", displayMode: .inline)
                        .environment(\.managedObjectContext, context)
                        .presentationDetents([ .fraction(0.4)])
                    // .presentationBackground(.ultraThinMaterial)
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(50)
                case .sheet4:
                    ActionView(viewModel: viewModel, activeSheet: $activeSheet, navTitle: "End Break", pickerStartDate: viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate, actionType: .endBreak)
                        .environment(\.managedObjectContext, context)
                        .presentationDetents([ .fraction(0.4)])
                    // .presentationBackground(.ultraThinMaterial)
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(50)
                case .sheet5:
                    TaxPickerView(taxPercentage: $viewModel.taxPercentage)
                        .environment(\.managedObjectContext, context)
                        .presentationDetents([ .fraction(0.3)])
                    //.presentationBackground(.ultraThinMaterial)
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(50)
                    
                case .sheet6:
                    ActionView(viewModel: viewModel, activeSheet: $activeSheet, navTitle: "Start Shift", actionType: .startShift)
                        .environment(\.managedObjectContext, context)
                        .presentationDetents([ .fraction(0.4)])
                    //.presentationBackground(.ultraThinMaterial)
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(50)
                case .sheet7:
                    
                    
                    
                    
                    NavigationStack{
                        List{
                            ForEach(viewModel.tempBreaks, id: \.self) { breakItem in
                                Section{
                                    VStack(alignment: .leading){
                                        if breakItem.isUnpaid{
                                            Text("Unpaid")
                                                .font(.subheadline)
                                                .foregroundColor(.indigo)
                                                .bold()
                                        }
                                        else {
                                            Text("Paid")
                                                .font(.subheadline)
                                                .foregroundColor(.indigo)
                                                .bold()
                                        }
                                        Text("\(viewModel.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate))")
                                            .listRowSeparator(.hidden)
                                            .font(.subheadline)
                                            .bold()
                                        
                                        Divider()
                                        
                                        DatePicker(
                                            "Start Date",
                                            selection: Binding<Date>(
                                                get: {
                                                    return breakItem.startDate
                                                },
                                                set: { newStartDate in
                                                    let updatedBreak = TempBreak(
                                                        startDate: newStartDate,
                                                        endDate: breakItem.endDate,
                                                        isUnpaid: breakItem.isUnpaid
                                                    )
                                                    viewModel.updateBreak(oldBreak: breakItem, newBreak: updatedBreak)
                                                }
                                            ),
                                            in: viewModel.minimumStartDate(for: breakItem)...Date.distantFuture,
                                            displayedComponents: [.hourAndMinute])
                                        DatePicker(
                                            "End Date",
                                            selection: Binding<Date>(
                                                get: {
                                                    return breakItem.endDate ?? Date()
                                                },
                                                set: { newEndDate in
                                                    let updatedBreak = TempBreak(
                                                        startDate: breakItem.startDate,
                                                        endDate: newEndDate,
                                                        isUnpaid: breakItem.isUnpaid
                                                    )
                                                    viewModel.updateBreak(oldBreak: breakItem, newBreak: updatedBreak)
                                                }
                                            ),
                                            in: breakItem.startDate...Date.distantFuture,
                                            displayedComponents: [.hourAndMinute])
                                        .disabled(viewModel.isOnBreak)
                                        
                                    }
                                    
                                }
                            }.onDelete(perform: viewModel.deleteBreaks)
                        }.navigationBarTitle("Breaks", displayMode: .inline)
                    }
                    .environment(\.managedObjectContext, context)
                    .presentationDetents([ .fraction(0.4), .fraction(0.6)])
                    //.presentationBackground(.ultraThinMaterial)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(50)
                case .sheet8:
                    JobSelectionView(selectedJobUUID: $viewModel.selectedJobUUID)
                        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                        .presentationDetents([ .medium])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(50)
                }
            }
            
            
            
            
            
            else {
                if let thisShift = shifts.first{
                    NavigationView{
                        DetailView(shift: thisShift)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing){
                                    Button("Save"){
                                        viewModel.isPresented = false
                                    }
                                }
                            }
                    }
                }
            }
            
            
        }
        
    /*    .popover(isPresented: $viewModel.isFirstLaunch) {
            if #available(iOS 16.4, *) {
                LaunchView()
                    .presentationDetents([ .large])
                    .presentationBackground(.black)
                    .presentationCornerRadius(50)
                    .interactiveDismissDisabled()
            }
            else {
                LaunchView().background(.black)
            }
        } */
        .onAppear{
            
            if let hourlyPayValue = UserDefaults.standard.object(forKey: shiftKeys.hourlyPayKey) as? Double {
                viewModel.hourlyPay = hourlyPayValue
            }
            
            let randomValue = Int.random(in: 1...100) // Generate a random number between 1 and 100
            viewModel.shouldShowPopup = randomValue <= 20
            viewModel.isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            print("I have appeared")
            if let shiftStartDate = sharedUserDefaults.object(forKey: shiftKeys.shiftStartDateKey) as? Date {
                if viewModel.hourlyPay != 0 {
                    viewModel.startShift(startDate: shiftStartDate)
                    print("Resuming app with saved shift start date")
                    
                    viewModel.loadTempBreaksFromUserDefaults()
                    print("Loading breaks from user defaults")
                } else {
                    viewModel.stopTimer(timer: &viewModel.timer, timeElapsed: &viewModel.timeElapsed)
                    sharedUserDefaults.removeObject(forKey: shiftKeys.shiftStartDateKey)
                }
            }
        }
        .onDisappear{
            // viewModel.stopTimer(timer: &viewModel.timer, timeElapsed: &viewModel.timeElapsed)
            
        }
        .onReceive(NotificationCenter.default.publisher(for: .didEnterRegion), perform: { _ in
            
            if viewModel.shift == nil && autoClockIn && !viewModel.isOnBreak{
                viewModel.startShift(startDate: Date())
            }
            else if clockInReminder{
                // DO SOMETHING HERE JAMES!!
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: .didExitRegion), perform: { _ in
            
            if viewModel.shift != nil && autoClockOut{
                viewModel.endShift(using: context, endDate: Date())
            }
        })
    }
}

private extension TimeInterval {
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let hours = (time / 3600)
        let minutes = (time / 60) % 60
        let seconds = time % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainWithSideBarView()
    }
}



extension NSNotification.Name {
    static let didEnterRegion = NSNotification.Name("didEnterRegionNotification")
    static let didExitRegion = NSNotification.Name("didExitRegionNotification")
}


enum ActiveSheet: Identifiable {
    case sheet1, sheet2, sheet3, sheet4, sheet5, sheet6, sheet7, sheet8
    
    var id: Int {
        hashValue
    }
}

enum ActionType {
    case startBreak, endShift, endBreak, startShift
}

struct ActionView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var actionDate = Date()
    
    
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.managedObjectContext) private var context
    @Binding var activeSheet: ActiveSheet?
    let navTitle: String
    var pickerStartDate: Date?
    
    var actionType: ActionType
    
    var body: some View {
        NavigationStack {
            VStack {
                
                
                
                if actionType == .startBreak {
                    if let limitStartDate = pickerStartDate {
                        DatePicker("", selection: $actionDate, in: limitStartDate...Date(), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    HStack {
                        ActionButtonView(title: "Unpaid Break", backgroundColor: Color.indigo.opacity(0.8), icon: "bed.double.fill", buttonWidth: UIScreen.main.bounds.width / 2 - 30) {
                            viewModel.startBreak(startDate: actionDate, isUnpaid: true)
                            dismiss()
                        }
                        ActionButtonView(title: "Paid Break", backgroundColor: Color.indigo.opacity(0.8), icon: "cup.and.saucer.fill", buttonWidth: UIScreen.main.bounds.width / 2 - 30) {
                            viewModel.startBreak(startDate: actionDate, isUnpaid: false)
                            dismiss()
                        }
                    }
                } else {
                    
                    switch actionType {
                    case .startShift:
                        
                        
                        
                        DatePicker("", selection: $actionDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        ActionButtonView(title: "Start Shift", backgroundColor: Color.orange.opacity(0.8), icon: "figure.walk.arrival", buttonWidth: UIScreen.main.bounds.width - 100) {
                            viewModel.startShiftButtonAction(startDate: actionDate)
                            dismiss()
                        }
                    case .endShift:
                        if let limitStartDate = pickerStartDate {
                            DatePicker("", selection: $actionDate, in: limitStartDate... , displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        ActionButtonView(title: "End Shift", backgroundColor: Color.orange.opacity(0.8), icon: "figure.walk.departure", buttonWidth: UIScreen.main.bounds.width - 100) {
                            viewModel.endShift(using: context, endDate: actionDate)
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                activeSheet = .sheet1
                            }
                        }
                    case .endBreak:
                        
                        if let limitStartDate = pickerStartDate {
                            DatePicker("", selection: $actionDate, in: limitStartDate... , displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        ActionButtonView(title: "End Break", backgroundColor: Color.orange.opacity(0.8), icon: "deskclock.fill", buttonWidth: UIScreen.main.bounds.width - 100) {
                            viewModel.endBreak(endDate: actionDate)
                            dismiss()
                        }
                    default:
                        fatalError("Unsupported action type")
                    }
                    
                }
                
            }
            .navigationBarTitle(navTitle, displayMode: .inline)
        }
        
    }
}


struct Shake: AnimatableModifier {
    var times: CGFloat = 0
    var amplitude: CGFloat = 5
    
    var animatableData: CGFloat {
        get { times }
        set { times = newValue }
    }
    
    func body(content: Content) -> some View {
        content.offset(x: sin(times * .pi * 2) * amplitude)
    }
}

extension View {
    func shake(times: CGFloat) -> some View {
        self.modifier(Shake(times: times))
    }
}
