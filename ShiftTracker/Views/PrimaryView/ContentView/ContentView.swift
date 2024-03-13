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
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(entity: Job.entity(), sortDescriptors: [])
    private var jobs: FetchedResults<Job>
    
    @EnvironmentObject var navigationState: NavigationState
    
    @Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    @State private var payShakeTimes: CGFloat = 0
    @State private var jobShakeTimes: CGFloat = 0
    
    private let shiftKeys = ShiftKeys()
    
    
    @FocusState private var payIsFocused: Bool
    
    @AppStorage("autoClockIn") private var autoClockIn: Bool = false
    @AppStorage("autoClockOut") private var autoClockOut: Bool = false
    @AppStorage("clockInReminder") private var clockInReminder: Bool = false
    @AppStorage("clockOutReminder") private var clockOutReminder: Bool = false
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    
    @State var isAnimating = false
    
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
    
            List{
                VStack(spacing: 20){
                    Group{
                        if viewModel.currentShift == nil{
                            UpcomingShiftView()
                                .padding(.horizontal)
                                .shake(times: viewModel.upcomingShiftShakeTimes)
                            
                        }
                        else {
                            CurrentShiftView()
                                .padding(.horizontal)
                        }
                    }.frame(maxWidth: UIScreen.main.bounds.width - 40, alignment: .leading)
                    
                    
                    TimerView()
                    
                        .onReceive(viewModel.$overtimeEnabled) { value in
                            
                            if value {
                                print("overtime is enabled in the receive ")
                                let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
                                   fetchRequest.predicate = NSPredicate(format: "name == %@", "Overtime")
                                
                                var overtimeTag: Tag?
                                
                                do {
                                        let matchingTags = try context.fetch(fetchRequest)
                                    overtimeTag = matchingTags.first
                                    } catch {
                                        print("Failed to fetch overtime tag: \(error)")
                                        
                                    }
                                
                                if let overtimeTag = overtimeTag,
                                           let overtimeTagID = overtimeTag.tagID {
                                         
                                                viewModel.selectedTags.insert(overtimeTagID)
                                            
                                        }
                            }
                            
                        }
                    
                        .onReceive(viewModel.$timeElapsed) { value in
                            if viewModel.autoClockOutTime > 0 {
                            if value >= viewModel.autoClockOutTime && viewModel.autoClockOut {
                                print("clocking out")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    if viewModel.currentShift != nil && !viewModel.isOnBreak{
                                        
                                        viewModel.newEndShift(using: context, endDate: viewModel.shiftStartDate.addingTimeInterval(viewModel.autoClockOutTime)) { result in
                                            DispatchQueue.main.async {
                                                switch result {
                                                case .success(let endedShift):
                                                    
                                                    print("Shift ended successfully. Details: \(endedShift)")
                                                    
                                                    try? viewModel.lastEndedShift = result.get()
                                                    
                                                case .failure(let error):
                                                    
                                                    print("Failed to end shift: \(error.localizedDescription)")
                                                    
                                                }
                                            }
                                        }
                                     
                                        
                                        navigationState.activeSheet = .detailSheet
                                    }
                                    
                                }
                                
                            }
                            
                        }
                            
                            if value >= 86400 {
                               
                                //    self.viewModel.lastEndedShift = viewModel.endShift(using: context, endDate: , job: selectedJobManager.fetchJob(in: context)!)
                                    
                                   viewModel.newEndShift(using: context, endDate: viewModel.shiftStartDate.addingTimeInterval(86400)) { result in
                                        DispatchQueue.main.async {
                                            switch result {
                                            case .success(let endedShift):
                                                
                                                print("Shift ended successfully. Details: \(endedShift)")
                                                
                                                try? viewModel.lastEndedShift = result.get()
                                                
                                            case .failure(let error):
                                                
                                                print("Failed to end shift: \(error.localizedDescription)")
                                                
                                            }
                                            navigationState.activeSheet = .detailSheet
                                        }
                                    }
                                    
               
                                    
                                    
                                
                                
                            }
                            
                        }
                    
                       
                    
                    TagButtonView()
                        .frame(maxWidth: .infinity)
                    
                    Group{
                        if viewModel.currentShift == nil{
                            Button(action: {
                                navigationState.showMenu.toggle()
                            }) {
                                SelectedJobView()
                                
                                    .padding(.horizontal)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.currentShift != nil)
                            .frame(maxWidth: UIScreen.main.bounds.width - 40, alignment: .leading)
                            .shake(times: jobShakeTimes)
                            
                        }
                        
                        ContentViewButtonsView(jobShakeTimes: $jobShakeTimes, payShakeTimes: $payShakeTimes).padding(.horizontal, 50) 
                          
                    }
                }.listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                if viewModel.currentShift != nil && !viewModel.tempBreaks.isEmpty {
                    CurrentBreaksListView().listRowBackground(Color.clear)
                }
            }
            
            
            
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
                    .background {
                        
                        Color.clear
                       
                       
                    }
            
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
                                navigationState.showMenu.toggle()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .bold()
                            
                        }
                        .foregroundColor(textColor)
                    }
                }
        
        
  
   
        
                .sheet(item: $navigationState.activeSheet, onDismiss: {
                    // if we loaded a scheduled shift, set it to nil upon dismissing action view
                    viewModel.scheduledShift = nil
                }){ sheet in
            // CHANGE UISCREEN CONDITIONAL DETENTS TO GLOBAL VARIABLE
            switch sheet {
            case .detailSheet:
                if let thisShift = viewModel.lastEndedShift {
                    NavigationStack{
                        DetailView(shift: thisShift, presentedAsSheet: true, activeSheet: $navigationState.activeSheet)
                            .environment(\.managedObjectContext, context)
                    }.presentationDetents([ .large])
                        .customSheetRadius(35)
                        .customSheetBackground()
                        .onDisappear{
                            navigationState.gestureEnabled = true
                        }
                }
            case .startBreakSheet:
                ActionView(navTitle: "Start Break", pickerStartDate: viewModel.tempBreaks.isEmpty ? viewModel.currentShift?.shiftStartDate : viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate, actionType: .startBreak)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(viewModel)
                    .presentationDetents([.fraction((UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 0.7 : 0.55)])
                    .customSheetRadius(35)
                    .customSheetBackground()
                
            case .endShiftSheet:
                ActionView(navTitle: "End Shift", pickerStartDate: viewModel.tempBreaks.isEmpty ? viewModel.currentShift?.shiftStartDate : viewModel.tempBreaks[viewModel.tempBreaks.count - 1].endDate, actionType: .endShift)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(viewModel)
                    .presentationDetents([.fraction((UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 0.7 : 0.55)])
                    .customSheetRadius(35)
                    .customSheetBackground()
            case .endBreakSheet:
                ActionView(navTitle: "End Break", pickerStartDate: viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate, actionType: .endBreak)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(viewModel)
                    .presentationDetents([.fraction((UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 0.7 : 0.55)])
                    .customSheetRadius(35)
                    .customSheetBackground()
            case .startShiftSheet:
                ActionView(navTitle: viewModel.scheduledShift == nil ? "Start Shift" : "Load Shift", actionType: .startShift, job: selectedJobManager.fetchJob(in: context), scheduledShift: viewModel.scheduledShift)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(viewModel)
                    .presentationDetents([.fraction((UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 0.96 : 0.8)])
                    .customSheetRadius(35)
                    .customSheetBackground()
                
            }
            
            
            
        }
        .onAppear{
            print("Breaks in the breaks array: \(viewModel.tempBreaks.count)") //debugging
         /*   if let hourlyPayValue = UserDefaults.standard.object(forKey: shiftKeys.hourlyPayKey) as? Double {
                viewModel.hourlyPay = hourlyPayValue
            }*/
            
            let randomValue = Int.random(in: 1...100) // Generate a random number between 1 and 100
            viewModel.shouldShowPopup = randomValue <= 20
            viewModel.isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            print("I have appeared")
            
            
            
            // check for any active shift
            
            viewModel.checkForActiveShiftAndManageTimer(using: context) { success, error in
                if success {
                    viewModel.newStartShift(using: context)
                }
            }
            
            // still need to load tags!
       
            // this is done in the above function anyway
            viewModel.loadSelectedTags()
            
            
          /*  if let shiftStartDate = sharedUserDefaults.object(forKey: shiftKeys.shiftStartDateKey) as? Date {
                if viewModel.hourlyPay != 0 {
                    
                    
                    if let jobSelected = selectedJobManager.fetchJob(in: context) {
                        viewModel.startShift(using: context, startDate: shiftStartDate, job: jobSelected)
                        
                        viewModel.loadSelectedTags()
                        
                        print("Resuming app with saved shift start date")
                        
                       // viewModel.loadTempBreaksFromUserDefaults()
                        print("Loading breaks from user defaults")
                    }
                } else {
                    viewModel.stopTimer(timer: &viewModel.timer, timeElapsed: &viewModel.timeElapsed)
                    sharedUserDefaults.removeObject(forKey: shiftKeys.shiftStartDateKey)
                }
            }*/
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                navigationState.gestureEnabled = true
            }
        }

        
        .onReceive(NotificationCenter.default.publisher(for: .didEnterRegion), perform: { notification in
            
            if let jobID = notification.userInfo?["jobID"] as? UUID, let job = selectedJobManager.fetchJob(with: jobID, in: context), viewModel.currentShift == nil && !viewModel.isOnBreak{
                selectedJobManager.selectJob(job, with: jobs, shiftViewModel: viewModel)
                
                viewModel.newStartShift(using: context, startDate: Date(), job: job)
          
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: .didExitRegion), perform: { _ in
            // might cause clock outs if theyre clocked in for one job but exit the location of another?
            if viewModel.currentShift != nil && !viewModel.isOnBreak {

                viewModel.newEndShift(using: context, endDate: Date()) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let endedShift):
                            
                            print("Shift ended successfully. Details: \(endedShift)")
                            
                            try? viewModel.lastEndedShift = result.get()
                            
                        case .failure(let error):
                            
                            print("Failed to end shift: \(error.localizedDescription)")
                            
                        }
                    }
                }
            }
        })
    }
}

