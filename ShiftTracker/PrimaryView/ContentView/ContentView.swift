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
import MapKit

struct ContentView: View {
    
    
    
    @ObservedObject var locationManager: LocationDataManager = LocationDataManager()
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.managedObjectContext) private var context
    
    
    
    @FetchRequest(entity: Job.entity(), sortDescriptors: [])
    private var jobs: FetchedResults<Job>
    
    
    
    @Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    
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
    
    
    @Binding var showMenu: Bool
    
    
    @available(iOS 16.1, *)
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        let buttonColor: Color = colorScheme == .dark ? Color.gray.opacity(0.5) : Color.black
        let disabledButtonColor: Color = colorScheme == .dark ? Color.gray.opacity(0.2) : Color.primary.opacity(0.8)
        
        NavigationStack{
                Form{
                    Section{
                            if viewModel.shift == nil{
                                UpcomingShiftView()
                                    
                            }
                            else {
                                CurrentShiftView(startDate: viewModel.shift!.startDate)
                            }
                        }.frame(maxWidth: UIScreen.main.bounds.width - 40, alignment: .leading)
                        .listRowBackground(Color.clear)
                    
                    Section{
                        TimerView(timeElapsed: $viewModel.timeElapsed)
                    }.listRowBackground(Color.clear)
                    Section{
                        if viewModel.shift == nil{
                            Button(action: {
                                showMenu.toggle()
                            }) {
                                if let job = jobSelectionViewModel.fetchJob(in: context) {
                                    
                                    SelectedJobView(jobName: job.name, jobTitle: job.title, jobIcon: job.icon, jobColor: Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                                } else {
                                    SelectedJobView()
                                }
                                
                            }
                            .disabled(viewModel.shift != nil)
                            .frame(maxWidth: UIScreen.main.bounds.width - 40, alignment: .leading)
                            .shake(times: jobShakeTimes)
                            .haptics(onChangeOf: jobSelectionViewModel.selectedJobUUID, type: .light)
                            
                        }
                       
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
                                        if jobSelectionViewModel.selectedJobUUID == nil {
                                            withAnimation(.linear(duration: 0.4)) {
                                                jobShakeTimes += 2
                                            }
                                            
                                        }
                                        
                                        
                                        if viewModel.hourlyPay != 0 && jobSelectionViewModel.selectedJobUUID != nil {
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
                                        
                                    }.buttonStyle(.borderless)
                                    
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
                                        }.buttonStyle(.borderless)
                                        .disabled(viewModel.isEditing)
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
                                        }.buttonStyle(.borderless)
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
                                    .buttonStyle(.borderless)
                                    .alert(isPresented: $viewModel.showEndAlert) {
                                        
                                        Alert(
                                            title: Text("End shift?"),
                                            message: Text("Are you sure you want to end this shift?"),
                                            primaryButton: .destructive(Text("End shift")) {
                                                viewModel.endShift(using: context, endDate: Date(), job: jobSelectionViewModel.fetchJob(in: context)!)
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
                            .listRowSeparator(.hidden)
                        
                        if viewModel.shift != nil {
                            Section(header:
                                        VStack(alignment: .leading){
                                Text("Breaks").font(.title2).bold()
                                    .textCase(nil)
                                    .foregroundColor(textColor)
                                    .listRowSeparator(.hidden)
                                Divider()
                                    .frame(maxWidth: 300, alignment: .leading)
                                    .listRowSeparator(.hidden)
                            }){
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
                                            if viewModel.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate) == "N/A" {
                                                HStack{
                                                    Text("In progress")
                                                        .listRowSeparator(.hidden)
                                                        .font(.subheadline)
                                                        .bold()
                                                    BreakTimerView(timeElapsed: $viewModel.breakTimeElapsed)
                                                }
                                            }
                                            else {
                                                Text("\(viewModel.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate))")
                                                    .listRowSeparator(.hidden)
                                                    .font(.subheadline)
                                                    .bold()
                                            }
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
                            }.listRowBackground(Color.clear)
                        }
                        
                        
                    }.listRowBackground(Color.clear)
                 
                    
                }.scrollContentBackground(.hidden)
            
            .frame(maxWidth: .infinity)
            .toolbar{
                ToolbarItemGroup(placement: .keyboard){
                    Spacer()
                    
                    Button("Done"){
                        payIsFocused = false
                    }
                }
            }
            
            .toolbar{
                ToolbarItem(placement: .navigationBarLeading){
                    Button{
                        withAnimation{
                            showMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .bold()
                     
                    }
                    .foregroundColor(textColor)
                }
            }
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
                    if let thisShift = viewModel.lastEndedShift {
                        NavigationStack{
                            DetailView(shift: thisShift).navigationBarTitle("Shift Ended")
                                .environment(\.managedObjectContext, context)
                        }.presentationDetents([ .large])
                            .presentationDragIndicator(.visible)
                            .presentationCornerRadius(50)
                            .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
                    }
                case .sheet2:
                    ActionView(viewModel: viewModel, jobSelectionViewModel: jobSelectionViewModel, activeSheet: $activeSheet, navTitle: "Start Break", pickerStartDate: viewModel.tempBreaks.isEmpty ? viewModel.shift?.startDate : viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate, actionType: .startBreak)
                        .environment(\.managedObjectContext, context)
                        .presentationDetents([ .fraction(0.4)])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(50)
                        .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
                    
                case .sheet3:
                    ActionView(viewModel: viewModel, jobSelectionViewModel: jobSelectionViewModel, activeSheet: $activeSheet, navTitle: "End Shift", pickerStartDate: viewModel.tempBreaks.isEmpty ? viewModel.shift?.startDate : viewModel.tempBreaks[viewModel.tempBreaks.count - 1].endDate, actionType: .endShift)
                        .environment(\.managedObjectContext, context)
                        .presentationDetents([ .fraction(0.4)])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(50)
                        .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
                case .sheet4:
                    ActionView(viewModel: viewModel, jobSelectionViewModel: jobSelectionViewModel, activeSheet: $activeSheet, navTitle: "End Break", pickerStartDate: viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate, actionType: .endBreak)
                        .environment(\.managedObjectContext, context)
                        .presentationDetents([ .fraction(0.4)])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(50)
                        .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
                case .sheet5:
                    TaxPickerView(taxPercentage: $viewModel.taxPercentage)
                        .environment(\.managedObjectContext, context)
                        .presentationDetents([ .fraction(0.3)])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(50)
                        .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
                    
                case .sheet6:
                    ActionView(viewModel: viewModel, jobSelectionViewModel: jobSelectionViewModel, activeSheet: $activeSheet, navTitle: "Start Shift", actionType: .startShift)
                        .environment(\.managedObjectContext, context)
                        .presentationDetents([ .fraction(0.4)])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(50)
                        .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
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
                    .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
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
                    viewModel.startShift(using: context, startDate: shiftStartDate, job: jobSelectionViewModel.fetchJob(in: context)!)
                    print("Resuming app with saved shift start date")
                    
                    viewModel.loadTempBreaksFromUserDefaults()
                    print("Loading breaks from user defaults")
                } else {
                    viewModel.stopTimer(timer: &viewModel.timer, timeElapsed: &viewModel.timeElapsed)
                    sharedUserDefaults.removeObject(forKey: shiftKeys.shiftStartDateKey)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didEnterRegion), perform: { notification in
            
            if let jobID = notification.userInfo?["jobID"] as? UUID, let job = jobSelectionViewModel.fetchJob(with: jobID, in: context), viewModel.shift == nil && !viewModel.isOnBreak{
                jobSelectionViewModel.selectJob(job, with: jobs, shiftViewModel: viewModel)
                viewModel.startShift(using: context, startDate: Date(), job: job)
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: .didExitRegion), perform: { _ in
            
            if viewModel.shift != nil && !viewModel.isOnBreak {
                viewModel.endShift(using: context, endDate: Date(), job: jobSelectionViewModel.fetchJob(in: context)!)
            }
        })
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
    case sheet1, sheet2, sheet3, sheet4, sheet5, sheet6, sheet7
    
    var id: Int {
        hashValue
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

/*
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
} */

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


/*
Section{
    
    if viewModel.isOnBreak {
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
    
    
}.listRowBackground(Color.clear) */




/*      Section {
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
    .listRowSeparator(.hidden) */
