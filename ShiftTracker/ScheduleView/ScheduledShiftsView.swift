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
    @EnvironmentObject var savedPublisher: ShiftSavedPublisher
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    let shiftManager = ShiftDataManager()
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var dateSelected: DateComponents?
    @Binding var navPath: NavigationPath
    @Binding var displayedOldShifts: [OldShift]
    

    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, YYYY"
        return formatter
    }
    
    
    var body: some View {
        Group {
            let foundShifts = shiftStore.shifts.filter { $0.startDate.startOfDay == dateSelected?.date?.startOfDay ?? Date().startOfDay}
            
            if !displayedOldShifts.isEmpty {
                Section{
                ForEach(displayedOldShifts.filter({ shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) }), id: \.objectID) { shift in
                    
                    NavigationLink(value: shift) {
                        
                        ShiftDetailRow(shift: shift, showTime: true)
                        
                        
                    }
                    
                    .navigationDestination(for: OldShift.self) { shift in
                       
                       
                       DetailView(shift: shift, navPath: $navPath).environmentObject(savedPublisher)
                       
                       
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
                
                Text(dateFormatter.string(from: dateSelected?.date ?? Date())).textCase(nil).foregroundStyle(colorScheme == .dark ? .white : .black).font(.title2).bold()
                        
                    
                    
                
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
            else if ((Calendar.current.isDateInToday(dateSelected?.date ?? Date()) || !isBeforeEndOfToday(dateSelected!.date ?? Date())) && displayedOldShifts.isEmpty) {
                    Section{
                        Text("You have no shifts scheduled on this date.")
                            .bold()
                            .roundedFontDesign()
                            .padding()
                    } .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                }
            
            else if isBeforeEndOfToday(dateSelected?.date ?? Date()) && displayedOldShifts.isEmpty {
                    
                    Text("No previous shifts found for this date.")
                    .bold()
                    .roundedFontDesign()
                        .padding()
                        .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                }
            
            
      
            
        }.sheet(item: $scheduleModel.selectedShiftToEdit, onDismiss: {
            
            scheduleModel.selectedShiftToEdit = nil
            
        }) { shift in
            
            CreateShiftForm(dateSelected: $dateSelected, scheduledShift: shift)
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


struct ScheduledShiftListRow: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var shiftStore: ShiftStore
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    let shift: SingleScheduledShift
    
    @AppStorage("lastSelectedJobUUID") private var lastSelectedJobUUID: String?
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    func formattedDuration() -> String {
        let interval = shift.endDate.timeIntervalSince(shift.startDate )
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    var body: some View {
        Section(header: Text("\(dateFormatter.string(from: shift.startDate )) - \(dateFormatter.string(from: shift.endDate ))")
            .bold()
            .roundedFontDesign()
            .textCase(nil)){
                
                ZStack{
                    VStack(alignment: .leading){
                        
                        HStack(spacing : 10){
                            
                            VStack(spacing: 3){
                                
                                JobIconView(icon: shift.job?.icon ?? "briefcase.fill", color: Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)), font: .title3, padding: 12)
                                
                             
                                
                                HStack(spacing: 5){
                                    
                                    ForEach(Array(shift.tags), id: \.self) { tag in
                                            Circle()
                                                .foregroundStyle(Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue))
                                                .frame(width: 8, height: 8)
                                        }
                                    
                                }
                                
                                
                            }
                                
                               
                                .frame(width: UIScreen.main.bounds.width / 7)
                            VStack(alignment: .leading, spacing: 5){
                                Text(shift.job?.name ?? "")
                                    .font(.title2)
                                    .bold()
                                Text(shift.job?.title ?? "")
                                    .foregroundColor(Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)))
                                    .font(.subheadline)
                                    .bold()
                                    .roundedFontDesign()
                                
                                
                                
                                
                            }
                            Spacer()
                
                        }//.padding()
                        
                    }
                    VStack(alignment: .trailing){
                        HStack{
                            Spacer()
                            Menu{
                                if shift.isRepeating {
                                    Button(action:{
                                        CustomConfirmationAlert(action: {
                                            scheduleModel.cancelRepeatingShiftSeries(shift: shift, with: shiftStore, using: viewContext)
                                        }, title: "End all future repeating shifts for this shift?").showAndStack()
                                    }){
                                        HStack{
                                            Image(systemName: "clock.arrow.2.circlepath")
                                            Spacer()
                                            Text("End Repeat")
                                        }
                                    }
                                }
                                Button(action:{
                                  
                                    scheduleModel.selectedShiftToEdit = scheduleModel.fetchScheduledShift(id: shift.id, in: viewContext)
                                    
                                }){
                                    HStack{
                                        Image(systemName: "pencil")
                                        Spacer()
                                        Text("Edit")
                                    }
                                }
                                
                            } label: {
                                Image(systemName: "ellipsis")
                                    .bold()
                                    .font(.title3)
                            }.contentShape(Rectangle())
                            
                        }.padding(.top)
                        Spacer()
                        Text(formattedDuration())
                            .foregroundStyle(.gray)
                            .bold()
                            .padding(.bottom)
                            .roundedFontDesign()
                    }
                    
                    
                    
                }
            }.opacity(!purchaseManager.hasUnlockedPro ? (shift.job?.uuid?.uuidString != lastSelectedJobUUID ? 0.5 : 1.0) : 1.0)
        
    }
}







