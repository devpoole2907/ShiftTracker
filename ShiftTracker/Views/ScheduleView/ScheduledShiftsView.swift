//
//  ScheduledShiftsView.swift
//  ShiftTracker
//
//  Created by James Poole on 22/04/23.
//

import SwiftUI
import CoreData
import Charts
import Haptics
import Foundation
import UserNotifications

struct ScheduledShiftsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var shiftStore: ShiftStore
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    let shiftManager = ShiftDataManager()
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var navPath: NavigationPath
    
    @ObservedObject var oldShiftsViewModel: OldShiftsViewModel

    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, YYYY"
        return formatter
    }
    
    init(navPath: Binding<NavigationPath>, allShifts: FetchedResults<OldShift>, selectedDate: Date?, selectedJobManager: JobSelectionManager) {
        _navPath = navPath
        self.oldShiftsViewModel = OldShiftsViewModel(shifts: allShifts, date: selectedDate ?? Date(), selectedJobManager: selectedJobManager)
    }
    
    
    var body: some View {
        
        
        Section {
            
            if !oldShiftsViewModel.displayedOldShifts.isEmpty {
                
                ForEach(oldShiftsViewModel.displayedOldShifts, id: \.objectID){ shift in
                    NavigationLink(value: shift) {
                        
                        ShiftDetailRow(shift: shift, showTime: true)
                        
                        
                    }
                    
                    .navigationDestination(for: OldShift.self) { shift in
                        
                        
                        DetailView(shift: shift, navPath: $navPath)
                         
                        
                    }
                    
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 10, leading: selectedJobManager.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
                    
                    .swipeActions {
                        
                        Button(action: {
                            withAnimation {
                                shiftStore.deleteOldShift(shift, in: viewContext)
                            }
                        }){
                            Image(systemName: "trash")
                        }.tint(Color.clear)
                        
                    }
                }
                
            }
            
            let foundShifts = shiftStore.shifts.filter { $0.startDate.startOfDay == scheduleModel.dateSelected?.date?.startOfDay ?? Date().startOfDay}
            
            
                if !foundShifts.isEmpty {
                    ForEach(foundShifts) { shift in
                        if shift.endDate > Date() && !shift.isComplete {
                            ScheduledShiftListRow(shift: shift)
                                .environmentObject(shiftStore)
                                .environmentObject(scheduleModel)
                                .swipeActions(allowsFullSwipe: false) {
                                    
                                    
                                    if let shift = scheduleModel.fetchScheduledShift(id: shift.id, in: viewContext) {
                                        ScheduledShiftRowSwipeButtons(shift: shift)
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(.init(top: 10, leading: 10, bottom: 10, trailing: 20))
                        }
                    }
                
                }
            
            else if ((Calendar.current.isDateInToday(scheduleModel.dateSelected?.date ?? Date()) || !isBeforeEndOfToday(scheduleModel.dateSelected!.date ?? Date())) && scheduleModel.displayedOldShifts.isEmpty) {
                    Section{
                        Text("You have no shifts scheduled on this date.")
                            .bold()
                            .roundedFontDesign()
                            .padding()
                    }  .listRowBackground(Color.clear)
                }
            
            else/* if isBeforeEndOfToday(dateSelected?.date ?? Date()) && displayedOldShifts.isEmpty */{
                    
                    Text("No previous shifts found for this date.")
                    .bold()
                    .roundedFontDesign()
                        .padding()
                        .listRowBackground(Color.clear)
                }
            
                
                
        } header: {
            
            Text(dateFormatter.string(from: scheduleModel.dateSelected?.date ?? Date())).textCase(nil).foregroundStyle(colorScheme == .dark ? .white : .black).font(.title2).bold()
                    
                
                
            
        }.listRowInsets(.init(top: 0, leading: 8, bottom: 5, trailing: 0))

        
        .sheet(item: $scheduleModel.selectedShiftToEdit, onDismiss: {
            
            scheduleModel.selectedShiftToEdit = nil
            
        }) { shift in
            
            CreateShiftForm(dateSelected: $scheduleModel.dateSelected, scheduledShift: shift)
                .presentationDetents([.large])
                .customSheetRadius(35)
                .customSheetBackground()
            
        }

        
    }
}



extension View {
    func screenBounds() -> CGRect {
        return UIScreen.main.bounds
    }
}

class OldShiftsViewModel: ObservableObject {
    @Published var displayedOldShifts: [OldShift] = []
    
    let shiftManager = ShiftDataManager()
    
    init(shifts: FetchedResults<OldShift>, date: Date, selectedJobManager: JobSelectionManager) {
        fetchShifts(shifts: shifts, for: date, with: selectedJobManager)
    }
    
    private func fetchShifts(shifts: FetchedResults<OldShift>, for date: Date, with selectedJobManager: JobSelectionManager) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        displayedOldShifts = shifts.filter { shift in
            let shiftDate = shift.shiftStartDate! as Date
            return shiftDate >= startOfDay && shiftDate < endOfDay
        }.filter { shiftManager.shouldIncludeShift($0, jobModel: selectedJobManager) }
    }
}

