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
    @EnvironmentObject var themeManager: ThemeDataManager
    
    let shiftManager = ShiftDataManager()
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var navPath: NavigationPath
    
    @ObservedObject var oldShiftsViewModel: OldShiftsViewModel
    
    @State private var showExportView: Bool = false
    @State private var shiftForExport: OldShift? = nil
    
    
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
            
            Text(dateFormatter.string(from: scheduleModel.dateSelected?.date ?? Date())).textCase(nil).foregroundStyle(colorScheme == .dark ? .white : .black).font(.title2).bold()
                .padding(.top, 25)
                .padding(.bottom, 2)
                .padding(.leading, 15)
                .listRowBackground(Color.clear)
            if !oldShiftsViewModel.displayedOldShifts.isEmpty {
                
                ForEach(oldShiftsViewModel.displayedOldShifts, id: \.objectID){ shift in
                    NavigationLink(value: shift) {
                        
                        ShiftDetailRow(shift: shift, showTime: true)
                        
                        
                    }
                    
                    .background {
                        
                        let deleteUIAction = UIAction(title: "Delete", image: UIImage(systemName: "trash.fill"), attributes: .destructive) { action in
                   
                          
                            
                            deleteShift(shift)
                            
                        }
                        
                        let duplicateUIAction = UIAction(title: "Duplicate", image: UIImage(systemName: "plus.square.fill.on.square.fill")) { action in
                                duplicateShift(shift)
                        }
                        
                        let shareUIAction = UIAction(title: "Export", image: UIImage(systemName: "square.and.arrow.up.fill")) { _ in
                            
                            exportShift(shift)
                            
                        }
                        
                        
                        
                        ContextMenuPreview(shift: shift, themeManager: themeManager, navigationState: NavigationState.shared, viewContext: viewContext, actionsArray: [deleteUIAction, duplicateUIAction, shareUIAction], action: {
                            navPath.append(shift)
                        })
                        
                        
                    }
                    
                    .navigationDestination(for: OldShift.self) { shift in
                        
                        
                        DetailView(shift: shift, navPath: $navPath)
                        
                        
                    }
                    
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 10, leading: selectedJobManager.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
                    
                    
                    .swipeActions {
                        
                        OldShiftSwipeActions(deleteAction: {
                            deleteShift(shift)
                        }, duplicateAction: {
                            duplicateShift(shift)
                        })
                    
                        
                        
                    }
                    
                    .swipeActions(edge: .leading) {
                        Button(action: {
                            exportShift(shift)
                        }){
                            Image(systemName: "square.and.arrow.up.fill")
                        }.tint(.gray)
                        
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
                        
                            .contextMenu {
                                if let shift = scheduleModel.fetchScheduledShift(id: shift.id, in: viewContext) {
                                    ScheduledShiftRowSwipeButtons(shift: shift, showText: true)
                                }
                            }
                        
                            .swipeActions {
                                
                                
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
            
            
            
        }
        
        
        .listRowInsets(.init(top: 0, leading: 8, bottom: 5, trailing: 0))
        
        
        .sheet(item: $scheduleModel.selectedShiftToEdit, onDismiss: {
            
            scheduleModel.selectedShiftToEdit = nil
            
        }) { shift in
            
            CreateShiftForm(dateSelected: $scheduleModel.dateSelected, scheduledShift: shift)
                .presentationDetents([.large])
                .customSheetRadius(35)
                .customSheetBackground()
            
        }
        
            
             
        
        
    }
    
    func duplicateShift(_ shift: OldShift) {
        scheduleModel.selectedShiftToDupe = shift
        
        
        scheduleModel.activeSheet = .pastShiftSheet
    }
    
    func deleteShift(_ shift: OldShift) {
        withAnimation {
            shiftStore.deleteOldShift(shift, in: viewContext)
        }
    }
    
    func exportShift(_ shift: OldShift) {
        shiftForExport = shift
        scheduleModel.activeSheet = .configureExportSheet
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

