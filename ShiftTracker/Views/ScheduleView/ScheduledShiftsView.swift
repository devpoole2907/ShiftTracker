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
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    let shiftManager = ShiftDataManager()
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var navPath: NavigationPath

    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, YYYY"
        return formatter
    }
    
    
    var body: some View {
        Group {
            
            
            let foundShifts = shiftStore.shifts.filter { $0.startDate.startOfDay == scheduleModel.dateSelected?.date?.startOfDay ?? Date().startOfDay}
            
            let foundOldShifts = scheduleModel.displayedOldShifts.filter({ shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) })
            
            if !foundOldShifts.isEmpty {
                Section{
                ForEach(foundOldShifts, id: \.objectID) { shift in
                    
                    NavigationLink(value: shift) {
                        
                        ShiftDetailRow(shift: shift, showTime: true)
                        
                        
                    }
                    
                    .navigationDestination(for: OldShift.self) { shift in
                       
                       
                       DetailView(shift: shift, navPath: $navPath)
                       
                       
                   }
                    
                    
                   
                    
                    .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                    .listRowInsets(.init(top: 10, leading: jobSelectionViewModel.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
                    
                    .swipeActions {
                        Button(role: .destructive) {
                            shiftStore.deleteOldShift(shift, in: viewContext)
                            
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                    
                    
                    
                }
            } header: {
                
                Text(dateFormatter.string(from: scheduleModel.dateSelected?.date ?? Date())).textCase(nil).foregroundStyle(colorScheme == .dark ? .white : .black).font(.title2).bold()
                        
                    
                    
                
            }.listRowInsets(.init(top: 0, leading: 8, bottom: 5, trailing: 0))
                   
                    
            }
            
            
                if !foundShifts.isEmpty {
                    ForEach(foundShifts) { shift in
                        if shift.endDate > Date() && !shift.isComplete {
                            ScheduledShiftListRow(shift: shift)
                                .environmentObject(shiftStore)
                                .environmentObject(scheduleModel)
                                .swipeActions {
                                    
                                    
                                    if let shift = scheduleModel.fetchScheduledShift(id: shift.id, in: viewContext) {
                                        ScheduledShiftRowSwipeButtons(shift: shift)
                                    }
                                }
                                .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
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
                    } .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                }
            
            else/* if isBeforeEndOfToday(dateSelected?.date ?? Date()) && displayedOldShifts.isEmpty */{
                    
                    Text("No previous shifts found for this date.")
                    .bold()
                    .roundedFontDesign()
                        .padding()
                        .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                }
           
            
            
      
            
        }
        
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










