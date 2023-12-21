//
//  ActionView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/05/23.
//

import SwiftUI
import Haptics
import CoreData

struct ActionView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var navigationState: NavigationState
    
    
    @Environment(\.dismiss) var dismiss
    @State private var actionDate = Date()
    @State private var payMultiplier: Double
    @State private var isRounded = false
    @State private var showProSheet = false
    @State private var showBreaksSheet = false
    @State private var enableReminder = false
    @State private var breakReminderTime: TimeInterval = 0
    @State private var breakReminderDate = Date()
    
    @AppStorage("shiftsTracked") var shiftsTracked = 0

    let navTitle: String
    var pickerStartDate: Date?
    
    var actionType: ActionType
    
    let job: Job?
    
    var upcomingShift: ScheduledShift?
    
    //(navTitle: "End Break", pickerStartDate: viewModel.tempBreaks[viewModel.tempBreaks.count - 1].startDate, actionType: .endBreak)
    
    
    init(navTitle: String, pickerStartDate: Date? = nil, actionType: ActionType, job: Job? = nil, scheduledShift: ScheduledShift? = nil) {
        self.navTitle = navTitle
        self.pickerStartDate = pickerStartDate
        self.actionType = actionType
        
        self._payMultiplier = State(initialValue: 1.0)
        
        self.job = job
        
        if let selectedJob = job {
            
            _breakReminderTime = State(initialValue: selectedJob.breakReminderTime)
            _enableReminder = State(initialValue: selectedJob.breakReminder)
            _breakReminderDate = State(initialValue: actionDate.addingTimeInterval(selectedJob.breakReminderTime))
            
        }
        
        if let shiftToLoad = scheduledShift {
            self._actionDate = State(initialValue: shiftToLoad.startDate ?? Date())
            self._payMultiplier = State(initialValue: shiftToLoad.payMultiplier)
            _breakReminderTime = State(initialValue: shiftToLoad.breakReminderTime)
            _enableReminder = State(initialValue: shiftToLoad.breakReminder)
            _breakReminderDate = State(initialValue: actionDate.addingTimeInterval(shiftToLoad.breakReminderTime))
            
        }
        
        self.upcomingShift = scheduledShift
        
      
        
     
        
        
    }
    
    var body: some View {
        
        let buttonColor: Color = colorScheme == .dark ? .white : .black
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        NavigationStack {
            VStack {
                
                VStack {
                    switch actionType {
                        
                    case .startBreak:
                        
                        if let limitStartDate = pickerStartDate {
                            DatePicker("", selection: $actionDate, in: limitStartDate...Date(), displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .disabled(isRounded)
                        }
                        
                    case .startShift:
                        
                        
                        
                        DatePicker("", selection: $actionDate, in: Date().addingTimeInterval(-(24*60*60))...Date().addingTimeInterval(24*60*60),  displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .disabled(isRounded)
                        
                    case .endShift:
                        if let limitStartDate = pickerStartDate {
                            DatePicker("", selection: $actionDate, in: limitStartDate... , displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .disabled(isRounded)
                        }
                    case .endBreak:
                        
                        if let limitStartDate = pickerStartDate {
                            DatePicker("", selection: $actionDate, in: limitStartDate... , displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .disabled(isRounded)
                        }
                    }
                    
                }
                
                
                
                
                Toggle(isOn: $isRounded){
                    Text("Auto Round")
                        .bold()
                }.toggleStyle(CustomToggleStyle())
                
                    .onChange(of: isRounded) { value in
                        
                        if isRounded == true {
                            actionDate = viewModel.roundDate(actionDate)
                        } 
                        // idk if it needs to set back to current date, what if you were fine tuning?
                        
                        /*else {
                            actionDate = Date()
                        }*/
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: UIScreen.main.bounds.width - 80)
                    .padding(.vertical, 10)
                    .glassModifier(cornerRadius: 20)
                    .padding(.bottom, actionType != .startShift ? 10 : 0)
                
                
                
                switch actionType {
                    
                case .startBreak:
                    
                    HStack {
                        ActionButtonView(title: "Unpaid Break", backgroundColor: themeManager.breaksColor, textColor: themeManager.breaksColor, icon: "bed.double.fill", buttonWidth: UIScreen.main.bounds.width / 2 - 30) {
                            viewModel.startBreak(startDate: actionDate, isUnpaid: true)
                            dismiss()
                        }
                        ActionButtonView(title: "Paid Break", backgroundColor: themeManager.breaksColor, textColor: themeManager.breaksColor, icon: "cup.and.saucer.fill", buttonWidth: UIScreen.main.bounds.width / 2 - 30) {
                            viewModel.startBreak(startDate: actionDate, isUnpaid: false)
                            dismiss()
                        }
                    }
                    
                    
                case .startShift:
                    
                    
                    Toggle(isOn: $viewModel.activityEnabled){
                        Text("Live Activity")
                            .bold()
                    }.toggleStyle(CustomToggleStyle())
                    
                    
                    
                        .onChange(of: viewModel.activityEnabled) { value in
                            
                            if #available(iOS 16.2, *) {
                                
                                
                                if value {
                                    
                                    if !(shiftsTracked >= 1) {
                                        
                                        
                                        //viewModel.activityEnabled = true
                                        
                                    }
                                    
                                    else if !purchaseManager.hasUnlockedPro {
                                        
                                        showProSheet.toggle()
                                        viewModel.activityEnabled = false
                                        
                                    }
                                }
                            } else {
                                dismiss()
                                OkButtonPopup(title: "Update to iOS 16.2 to use Live Activities.", action: {
                                    viewModel.activityEnabled = false
                                    navigationState.activeSheet = .startShiftSheet
                                }).showAndStack()
                                
                            }
                            
                            
                            
                        }
                    
                        .padding(.horizontal)
                        .frame(maxWidth: UIScreen.main.bounds.width - 80)
                        .padding(.vertical, 10)
                        .glassModifier(cornerRadius: 20)
                    
              
                    
                    Button(action: {
                        
                        showBreaksSheet.toggle()
                        
                        
                    }){
                        HStack {
                            Text("Break Reminder").bold()
                            Spacer()
                            HStack(spacing: 3) {
                                if breakReminderTime > 0 && enableReminder == true {
                                    HStack {
                                        Text(actionDate.addingTimeInterval(breakReminderTime), style: .time)
                                        Divider().frame(maxHeight: 8)
                                        Text("\(formattedTimeInterval(breakReminderTime))")
                                    }
                                } else {
                                    Text("Disabled")
                                }
                                Image(systemName: "chevron.right").font(.caption)
                            }.foregroundStyle(.gray)
                        }
                    } .padding(.horizontal)
                        .frame(maxWidth: UIScreen.main.bounds.width - 80)
                        .padding(.vertical, 12)
                        .glassModifier(cornerRadius: 20)
        
                    
                    
                    
                    Stepper(value: $payMultiplier, in: 1.0...3.0, step: 0.05) {
                        Text("Pay Multiplier: x\(payMultiplier, specifier: "%.2f")").bold()
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: UIScreen.main.bounds.width - 80)
                    .padding(.vertical, 10)
                    .glassModifier(cornerRadius: 20)
                    
                    
                    
                    .onAppear {
                        
                        
                        if purchaseManager.hasUnlockedPro || shiftsTracked < 1 {
                            if #available(iOS 16.2, *) {
                                viewModel.activityEnabled = true
                            }
                            
                        } else {
                            
                            viewModel.activityEnabled = false
                            
                        }
                        
                    }
                    
                    .padding(.bottom, 10)
                    
                    
                    ActionButtonView(title: upcomingShift == nil ? "Start Shift" : "Load Shift", backgroundColor: buttonColor, textColor: textColor, icon: "figure.walk.arrival", buttonWidth: UIScreen.main.bounds.width - 60) {
                        viewModel.breakReminder = self.enableReminder
                        viewModel.breakReminderTime = self.breakReminderTime
                        viewModel.payMultiplier = self.payMultiplier
                        viewModel.isMultiplierEnabled = self.payMultiplier > 1.0
                        viewModel.savePayMultiplier() //saves to user defaults
                        
                        if let shiftToLoad = self.upcomingShift {
                            applyUpcomingShiftTags(upcomingShift: shiftToLoad)
                            
                            // mark the shift as complete, will be scheduled for deletion when ending shift - also prevents editing after starting
                            shiftToLoad.isComplete = true
                            
                            try? viewContext.save()
                            
                        }
                        
                        
                        
                        viewModel.startShiftButtonAction(using: viewContext, startDate: actionDate, job: self.job!)
                        dismiss()
                    }
                case .endShift:
                    ActionButtonView(title: "End Shift", backgroundColor: buttonColor, textColor: textColor, icon: "figure.walk.departure", buttonWidth: UIScreen.main.bounds.width - 60) {
                        
                        // delete any scheduled shifts marked complete
                        
                        viewModel.deleteCompletedScheduledShifts(viewContext: viewContext)
                        
                        viewModel.lastEndedShift = viewModel.endShift(using: viewContext, endDate: actionDate, job: self.job!)
                        dismiss()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            navigationState.activeSheet = .detailSheet
                        }
                        
                    }.contextMenu {
                        Button(action: {
                            viewModel.uncompleteCancelledScheduledShift(viewContext: viewContext)
                            viewModel.cancelShift()
                            
                            dismiss()
                        }){
                            HStack {
                                Image(systemName: "clock.badge.xmark")
                                Text("Cancel Shift")
                            }
                        }
                        
                    }
                case .endBreak:
                    ActionButtonView(title: "End Break", backgroundColor: buttonColor, textColor: textColor, icon: "deskclock.fill", buttonWidth: UIScreen.main.bounds.width - 60) {
                        viewModel.endBreak(endDate: actionDate, viewContext: viewContext)
                        dismiss()
                    }
                    
                }
                
                
                
            }
            .fullScreenCover(isPresented: $showProSheet){
                
                
                ProView()
                
                    .customSheetBackground()
                
                
            }
            
            .sheet(isPresented: $showBreaksSheet) {
                BreakReminderSheet(breakReminderDate: $breakReminderDate, breakReminderTime: $breakReminderTime, actionDate: actionDate, enableReminder: $enableReminder)
                    .customSheetBackground()
                    .customSheetRadius()
                    .presentationDetents([.fraction(0.48)])
            }
            
            
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .trailingCloseButton()
        }
        
    }
    
    private func applyUpcomingShiftTags(upcomingShift: ScheduledShift) {
        let associatedTags = upcomingShift.tags as? Set<Tag> ?? []
        let associatedTagIds = associatedTags.compactMap { $0.tagID }
                            viewModel.selectedTags = Set(associatedTagIds)
        
        
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
           fetchRequest.predicate = NSPredicate(format: "name == %@", "Late")
        
        var lateTag: Tag?
        
        do {
                let matchingTags = try viewContext.fetch(fetchRequest)
            lateTag = matchingTags.first
            } catch {
                print("Failed to fetch late tag: \(error)")
                
            }
        
        if let lateTag = lateTag,
                   let lateTagId = lateTag.tagID {
                    // if the shift is late, select the late tag
                    if Date() > upcomingShift.startDate ?? Date() {
                        viewModel.selectedTags.insert(lateTagId)
                    }
                }
    }
    



    
}

