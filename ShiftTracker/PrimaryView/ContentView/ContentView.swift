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
    
    // change me to be a binding and take from mainwithsidebar later
    @State var navPath = NavigationPath()
    
    @Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    
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
    
    
    @available(iOS 16.1, *)
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        NavigationStack{
            List{
                VStack(spacing: 20){
                    Group{
                        if viewModel.shift == nil{
                            UpcomingShiftView()
                                .padding(.horizontal)
                            
                        }
                        else {
                            CurrentShiftView(startDate: viewModel.shift!.startDate)
                                .padding(.horizontal)
                        }
                    }.frame(maxWidth: UIScreen.main.bounds.width - 40, alignment: .leading)
                    
                    
                    TimerView()
                    
                    TagButtonView()
                        .frame(maxWidth: .infinity)
                    
                    Group{
                        if viewModel.shift == nil{
                            Button(action: {
                                navigationState.showMenu.toggle()
                            }) {
                                SelectedJobView()
                                
                                    .padding(.horizontal)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.shift != nil)
                            .frame(maxWidth: UIScreen.main.bounds.width - 40, alignment: .leading)
                            .shake(times: jobShakeTimes)
                            
                        }
                        
                        ContentViewButtonsView(jobShakeTimes: $jobShakeTimes, payShakeTimes: $payShakeTimes).padding(.horizontal, 50)
                    }
                }.listRowBackground(Color.clear)
                if viewModel.shift != nil && !viewModel.tempBreaks.isEmpty {
                    CurrentBreaksListView()
                }
            }.scrollContentBackground(.hidden)
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
        }
        
        .sheet(item: $viewModel.activeSheet){ sheet in
            // CHANGE UISCREEN CONDITIONAL DETENTS TO GLOBAL VARIABLE
            switch sheet {
            case .detailSheet:
                if let thisShift = viewModel.lastEndedShift {
                    NavigationStack{
                        DetailView(shift: thisShift, presentedAsSheet: true, activeSheet: $viewModel.activeSheet, navPath: $navPath).navigationBarTitle("Shift Ended")
                            .toolbarBackground(colorScheme == .dark ? .black : .white, for: .navigationBar)
                            .environment(\.managedObjectContext, context)
                    }.presentationDetents([ .large])
                        .presentationCornerRadius(35)
                        .presentationBackground(colorScheme == .dark ? .black : .white)
                        .onDisappear{
                            navigationState.gestureEnabled = true
                        }
                }
            case .startBreakSheet:
                ActionView(navTitle: "Start Break", pickerStartDate: viewModel.tempBreaks.isEmpty ? viewModel.shift?.startDate : viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate, actionType: .startBreak)
                    .environment(\.managedObjectContext, context)
                    .presentationDetents([.fraction((UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 0.7 : 0.55)])
                    .presentationCornerRadius(35)
                    .presentationBackground(colorScheme == .dark ? .black : .white)
                
            case .endShiftSheet:
                ActionView(navTitle: "End Shift", pickerStartDate: viewModel.tempBreaks.isEmpty ? viewModel.shift?.startDate : viewModel.tempBreaks[viewModel.tempBreaks.count - 1].endDate, actionType: .endShift)
                    .environment(\.managedObjectContext, context)
                    .presentationDetents([.fraction((UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 0.7 : 0.55)])
                    .presentationCornerRadius(35)
                    .presentationBackground(colorScheme == .dark ? .black : .white)
            case .endBreakSheet:
                ActionView(navTitle: "End Break", pickerStartDate: viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate, actionType: .endBreak)
                    .environment(\.managedObjectContext, context)
                    .presentationDetents([.fraction((UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 0.7 : 0.55)])
                    .presentationCornerRadius(35)
                    .presentationBackground(colorScheme == .dark ? .black : .white)
            case .startShiftSheet:
                ActionView(navTitle: "Start Shift", actionType: .startShift)
                    .environment(\.managedObjectContext, context)
                    .presentationDetents([.fraction((UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 0.85 : 0.7)])
                    .presentationCornerRadius(35)
                    .presentationBackground(colorScheme == .dark ? .black : .white)
            }
            
            
            
        }
        .onAppear{
            print("Breaks in the breaks array: \(viewModel.tempBreaks.count)") //debugging
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
                    
                    
                    if let jobSelected = jobSelectionViewModel.fetchJob(in: context) {
                        viewModel.startShift(using: context, startDate: shiftStartDate, job: jobSelectionViewModel.fetchJob(in: context)!)
                        
                        viewModel.loadSelectedTags()
                        
                        print("Resuming app with saved shift start date")
                        
                       // viewModel.loadTempBreaksFromUserDefaults()
                        print("Loading breaks from user defaults")
                    }
                } else {
                    viewModel.stopTimer(timer: &viewModel.timer, timeElapsed: &viewModel.timeElapsed)
                    sharedUserDefaults.removeObject(forKey: shiftKeys.shiftStartDateKey)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                navigationState.gestureEnabled = true
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

