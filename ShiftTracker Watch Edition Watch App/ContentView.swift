//
//  ContentView.swift
//  ShiftTracker Watch Edition Watch App
//
//  Created by James Poole on 25/04/23.
//

import SwiftUI
import WatchConnectivity
import CoreData
import CloudKit

#if os(watchOS)
import WatchDatePicker
#endif
struct ContentView: View {
    
    private let connectivityManager = WatchConnectivityManager.shared
    @Environment(\.managedObjectContext) private var context
    
    
    
    @FetchRequest(
        entity: Job.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]
    ) private var jobs: FetchedResults<Job>
    
    @State private var showAlert = false
    @State private var jobToDelete: Job?
    
    private func deleteJob(at offsets: IndexSet) {
        if let index = offsets.first {
            jobToDelete = jobs[index]
            showAlert = true
        }
    }
    
    private func confirmDelete() {
        if let job = jobToDelete {
            context.delete(job)
            do {
                try context.save()
                connectivityManager.deleteJob(job)
            } catch {
                print("Failed to delete job: \(error.localizedDescription)")
            }
        }
        jobToDelete = nil
        showAlert = false
    }
    
    var body: some View {
        NavigationStack{
            if !jobs.isEmpty {
                List{
                    ForEach(jobs, id: \.self) { job in
                        NavigationLink(destination: TimerView(job: job, viewModel: ContentViewModel()).environment(\.managedObjectContext, context)){
                            JobRow(job: job).environment(\.managedObjectContext, context)
                        }
                    }
                }
                
                .listStyle(CarouselListStyle())
                .navigationBarTitle("ShiftTracker")
            }
            else {
                VStack(alignment: .center, spacing: 5){
                    Text("No Jobs")
                        .font(.title2)
                        .bold()
                    Text("Add a job in the iOS app")
                        .bold()
                }
                .navigationBarTitle("ShiftTracker")
            }
        }
        .onAppear {
            WatchConnectivityManager.shared.requestJobsFromPhone()
        }
        
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct TimerView: View {
    
    var job: Job
    
    @ObservedObject var viewModel: ContentViewModel
    
    @State private var activeSheet: ActiveSheet?
    
    private let shiftKeys = ShiftKeys()
    
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View{
        
        NavigationStack{
            TabView{
                
                VStack(spacing: 2){
                    
                    WatchTimerView(timeElapsed: $viewModel.timeElapsed)
                    
                    if viewModel.isOnBreak {
                        WatchBreakTimerView(timeElapsed: $viewModel.breakTimeElapsed)
                    }
                    
                    HStack{
                        if viewModel.shift == nil {
                            Button(action: {
                                activeSheet = .startShiftSheet
                            }) {
                                Text("Start")
                                    .bold()
                            }
                        }
                        else if !viewModel.isOnBreak{
                            Button(action: {
                                activeSheet = .startBreakSheet
                            }) {
                                Text("Break")
                                    .bold()
                            }
                        }
                        else {
                            Button(action: {
                                activeSheet = .endBreakSheet
                            }) {
                                Text("Break")
                                    .foregroundColor(.indigo)
                                    .bold()
                            }
                        }
                        Button(action: {
                            activeSheet = .endShiftSheet
                        }) {
                            Text("End")
                                .bold()
                        }.disabled(viewModel.shift == nil || viewModel.isOnBreak)
                    }
                    
                }
                
                if !viewModel.tempBreaks.isEmpty{
                    WatchTempBreakView(viewModel: viewModel)
                }
                
            }
            .navigationBarBackButtonHidden(viewModel.shift != nil ? true : false)
            
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            
            // .navigationBarTitle(job.name ?? "Unnamed Job")
        }

        .sheet(item: $activeSheet){ item in
            
            switch item {
            case .startShiftSheet:
                ActionView(viewModel: viewModel, activeSheet: $activeSheet, navTitle: "Start Shift", pickerStartDate: Date(), actionType: .startShift, job: job)
                    .environment(\.managedObjectContext, viewContext)
                
            case .endShiftSheet:
                ActionView(viewModel: viewModel, activeSheet: $activeSheet, navTitle: "End Shift", pickerStartDate: viewModel.tempBreaks.isEmpty ? viewModel.shift?.startDate : viewModel.tempBreaks[viewModel.tempBreaks.count - 1].endDate, actionType: .endShift, job: job)
                    .environment(\.managedObjectContext, viewContext)
            case .startBreakSheet:
                ActionView(viewModel: viewModel, activeSheet: $activeSheet, navTitle: "Start Break", pickerStartDate: viewModel.tempBreaks.isEmpty ? viewModel.shift?.startDate : viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate, actionType: .startBreak, job: job)
                    .environment(\.managedObjectContext, viewContext)
            case .endBreakSheet:
                ActionView(viewModel: viewModel, activeSheet: $activeSheet, navTitle: "End Break", pickerStartDate: viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate, actionType: .endBreak, job: job)
                    .environment(\.managedObjectContext, viewContext)
                
            }
            
            
        }
        
        .onAppear {
            
            if let hourlyPayValue = UserDefaults.standard.object(forKey: shiftKeys.hourlyPayKey) as? Double {
                viewModel.hourlyPay = hourlyPayValue
            }
            
            viewModel.selectedJobUUID = job.uuid
            
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
        
    }
}

/*
 struct TimerView_Previews: PreviewProvider {
 static var previews: some View {
 TimerView(job: <#JobData#>)
 }
 } */


struct JobRow: View {
    var job: Job
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showPastShifts: Bool = false
    
    var body: some View {
        HStack{
            VStack(alignment: .leading, spacing: 5){
                Image(systemName: job.icon ?? "briefcase.circle")
                    .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                    .font(.largeTitle)
                Text(job.name ?? "Unnamed Job")
                    .font(.headline)
                    .bold()
                Text(job.title ?? "")
                    .font(.footnote)
                    .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                    .bold()
                
            }
            Spacer()
            
            VStack{
                Button(action: {
                    showPastShifts = true
                }) {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                }.buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 2)
        .sheet(isPresented: $showPastShifts) {
            PastShiftsView(job: job).environment(\.managedObjectContext, viewContext)
        }
    }
}

struct PastShiftsView: View {
    
    
    @Environment(\.managedObjectContext) private var viewContext
    var job: Job
    
    @FetchRequest(
        entity: OldShift.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
    ) private var shifts: FetchedResults<OldShift>
    
    var body: some View{
        
        if shifts.isEmpty{
            Text("No previous shifts")
                .bold()
        }
        else {
            List{
                Text(job.name ?? "Unnamed Job")
                    .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                    .font(.title3)
                    .bold()
                    .listRowBackground(Color.clear)
                ForEach(shifts, id: \.self){ shift in
                    if shift.job?.uuid == job.uuid {
                        ShiftRow(shift: shift)
                    }
                }
            }
        }
        
        
    }
}

struct ShiftRow: View {
    
    var shift: OldShift
    
    @State private var showDetailView = false
    
    var body: some View {
        Button(action: {
            showDetailView = true
        }) {
            
            let durationString = String(format: "%.1f", (shift.shiftEndDate!.timeIntervalSince(shift.shiftStartDate!) / 3600.0))
            let dateString = dateFormatter.string(from: shift.shiftStartDate!)
            let payString = String(format: "%.2f", shift.taxedPay)
            
            
            
            VStack(alignment: .leading, spacing: 2){
                Text("\(currencyFormatter.currencySymbol ?? "")\(payString)")
                    .font(.title2)
                    .bold()
                Text(" \(durationString) hours")
                    .foregroundColor(.orange)
                    .font(.subheadline)
                    .bold()
                Text(dateString)
                    .foregroundColor(.gray)
                    .font(.footnote)
                    .bold()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 2)
        }.buttonStyle(.plain)
        
        
        
            .sheet(isPresented: $showDetailView){
                DetailView(shift: shift)
            }
    }
    
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }
    
}

struct DetailView: View {
    
    var shift: OldShift
    
    var body: some View {
        Text("\(shift.totalPay)")
        Text("Hourly rate: \(shift.hourlyPay)")
    }
}


enum ActiveSheet: Identifiable {
    case startShiftSheet, endShiftSheet, startBreakSheet, endBreakSheet
    
    var id: Int {
        hashValue
    }
}

enum ActionType {
    case endShift, startShift, startBreak, endBreak
}


struct ActionView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var actionDate = Date()
    
    
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.managedObjectContext) private var context
    @Binding var activeSheet: ActiveSheet?
    
    @State private var isWatchTempBreakViewPresented = false
    
    let navTitle: String
    var pickerStartDate: Date?
    
    var actionType: ActionType
    
    var job: Job
    
    @State private var selectedHourlyPay: Double
    
    init(viewModel: ContentViewModel, activeSheet: Binding<ActiveSheet?>, navTitle: String, pickerStartDate: Date?, actionType: ActionType, job: Job) {
        self.viewModel = viewModel
        _activeSheet = activeSheet
        self.navTitle = navTitle
        self.pickerStartDate = pickerStartDate
        self.actionType = actionType
        self.job = job
        _selectedHourlyPay = State(initialValue: job.hourlyPay)
    }
    
    
    var body: some View {
        VStack {
            switch actionType {
            case .startShift:
                DatePicker(
                    "Start Time",
                    selection: $actionDate,
                    displayedComponents: .hourAndMinute
                )
                // .frame(maxWidth: .infinity, alignment: .center)
                Picker("Hourly Pay", selection: $selectedHourlyPay) {
                    ForEach(1..<1000) { value in
                        Text("\(Locale.current.currencySymbol ?? "$")\(value)")
                            .font(.title2)
                            .padding()
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .labelsHidden()
                .frame(width: 148,height: 50)
                .onChange(of: selectedHourlyPay) { newValue in
                                viewModel.hourlyPay = newValue
                                viewModel.saveHourlyPay() // Save the value of hourlyPay when the picker value changes
                            }
                Button(action: {
                    viewModel.startShiftButtonAction(startDate: actionDate)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "figure.walk.arrival")
                            .foregroundColor(.orange)
                        Text("Start Shift").bold()
                    }
                    
                }
            case .endShift:
                DatePicker(
                    "End Time",
                    selection: $actionDate,
                    displayedComponents: .hourAndMinute
                )
                
                Button(action: {
                  //  viewModel.endShift(using: context, endDate: actionDate)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "figure.walk.departure")
                            .foregroundColor(.orange)
                        Text("End Shift").bold()
                    }
                    
                }
            case .startBreak:
                DatePicker(
                    "Start Time",
                    selection: $actionDate,
                    displayedComponents: .hourAndMinute
                )
                
                HStack{
                    Button(action: {
                        viewModel.startBreak(startDate: actionDate, isUnpaid: true)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text("Unpaid").bold()
                        }
                        
                    }.buttonStyle(BorderedButtonStyle(tint: .indigo))
                    Button(action: {
                        viewModel.startBreak(startDate: actionDate, isUnpaid: false)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text("Paid").bold()
                        }
                        
                    }.buttonStyle(BorderedButtonStyle(tint: .indigo))
                }
            case .endBreak:
                DatePicker(
                    "End Time",
                    selection: $actionDate,
                    displayedComponents: .hourAndMinute
                )
                
                Button(action: {
                    viewModel.endBreak(endDate: actionDate)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "deskclock.fill")
                            .foregroundColor(.indigo)
                        Text("End Break").bold()
                    }
                    
                }
            }
            //.padding()
            
        }
        
    }
    
}

struct WatchTempBreakView: View{
    
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View{
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
        }.navigationTitle("Breaks")
    }
}
