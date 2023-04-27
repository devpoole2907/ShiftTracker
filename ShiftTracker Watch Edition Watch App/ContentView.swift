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
import WatchDatePicker

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
                            JobRow(job: job)
                        }
                    }//.onDelete(perform: deleteJob)
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
    /*    .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Confirm Delete"),
                message: Text("Are you sure you want to delete this job?"),
                primaryButton: .destructive(Text("Delete"), action: confirmDelete),
                secondaryButton: .cancel()
            )
        } */
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
            .navigationBarBackButtonHidden(viewModel.shift != nil ? true : false)
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
                        
                    }) {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                    }
                    Spacer()
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 2)
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
                        ForEach(1..<100) { value in
                            Text("\(Locale.current.currencySymbol ?? "$")\(value)")
                                .font(.title2)
                                .padding()
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .labelsHidden()
                    .frame(width: 148,height: 50)
                    .onChange(of: viewModel.hourlyPay) { _ in
                        viewModel.saveHourlyPay() // Save the value of hourlyPay whenever it changes
                    }
                    Button(action: {
                        viewModel.hourlyPay = selectedHourlyPay
                        viewModel.startShiftButtonAction(startDate: actionDate)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "figure.walk.arrival")
                                .foregroundColor(.orange)
                            Text("Start Shift").bold()
                        }
                        
                    }.background(.orange)
                case .endShift:
                    DatePicker(
                        "End Time",
                        selection: $actionDate,
                        displayedComponents: .hourAndMinute
                    )
                    Spacer()
                    Button(action: {
                        viewModel.endShift(using: context, endDate: actionDate)
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
                    Spacer()
                    HStack{
                        Button(action: {
                            viewModel.startBreak(startDate: actionDate, isUnpaid: true)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "bed.double.fill")
                                    .foregroundColor(.indigo)
                                Text("Unpaid").bold()
                            }
                            
                        }
                        Button(action: {
                            viewModel.startBreak(startDate: actionDate, isUnpaid: false)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "cup.and.saucer.fill")
                                    .foregroundColor(.indigo)
                                Text("Paid").bold()
                            }
                            
                        }
                    }
                case .endBreak:
                    DatePicker(
                        "End Time",
                        selection: $actionDate,
                        displayedComponents: .hourAndMinute
                    )
                    Spacer()
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

