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
    
    @State private var selectedShiftToEdit: ScheduledShift?
    
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
                        
                        ShiftDetailRow(shift: shift)
                        
                        
                    }
                    
                    .navigationDestination(for: OldShift.self) { shift in
                       
                       
                       DetailView(shift: shift, navPath: $navPath).environmentObject(savedPublisher)
                       
                       
                   }
                    
                    
                   
                    
                    .listRowBackground(Color("SquaresColor"))
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
                if let dateSelected = dateSelected{
                    if let selectedDate = dateSelected.date {
                        Text(dateFormatter.string(from: selectedDate)).textCase(nil).foregroundStyle(colorScheme == .dark ? .white : .black).font(.title2).bold()
                        
                    }
                    
                }
            }.listRowInsets(.init(top: 0, leading: 20, bottom: 5, trailing: 0))
                
            }
            
            
                if !foundShifts.isEmpty {
                    ForEach(foundShifts) { shift in
                        if shift.endDate > Date() {
                            ListViewRow(shift: shift, selectedShiftToEdit: $selectedShiftToEdit)
                                .environmentObject(shiftStore)
                                .environmentObject(scheduleModel)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        
                                        scheduleModel.deleteShift(shift, with: shiftStore, using: viewContext)
                                        
                                        
                                        
                                        
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    
                                    Button(role: .none){
                                        
                                        // edit scheduled shift to go here
                                        
                                        
                                        if let id = foundShifts.first?.id {  // replace with the ID of the shift to be edited
                                            selectedShiftToEdit = scheduleModel.fetchScheduledShift(id: id, in: viewContext)
                                                }
                                        
                                       
                                        
                                        
                                    } label: {
                                        
                                        Image(systemName: "pencil")
                                        
                                        
                                    }.tint(Color(red: Double(shift.job?.colorRed ?? 0.0), green: Double(shift.job?.colorGreen ?? 0.0), blue: Double(shift.job?.colorBlue ?? 0.0)))
                                    
                                    Button(role: .cancel) {
                                        
                                        CustomConfirmationAlert(action: {
                                            scheduleModel.cancelRepeatingShiftSeries(shift: shift, with: shiftStore, using: viewContext)
                                        }, cancelAction: nil, title: "End all future repeating shifts for this shift?").showAndStack()
                                        
                                        
                                        
                                    } label: {
                                        Image(systemName: "clock.arrow.2.circlepath")
                                    }.disabled(!shift.isRepeating)
                                    
                                    
                                    
                                }
                                .listRowBackground(Color("SquaresColor"))
                                .listRowInsets(.init(top: 10, leading: 10, bottom: 10, trailing: 20))
                        }
                    }
                
                }
            else if ((Calendar.current.isDateInToday(dateSelected?.date ?? Date()) || !isBeforeEndOfToday(dateSelected!.date ?? Date())) && displayedOldShifts.isEmpty) {
                    Section{
                        Text("You have no shifts scheduled on this date.")
                            .bold()
                            .padding()
                    }.listRowBackground(Color("SquaresColor"))
                }
            
            else if isBeforeEndOfToday(dateSelected?.date ?? Date()) && displayedOldShifts.isEmpty {
                    
                    Text("No previous shifts found for this date.")
                        .bold()
                        .padding()
                        .listRowBackground(Color("SquaresColor"))
                }
            
            
      
            
        }.sheet(item: $selectedShiftToEdit, onDismiss: {
            
            selectedShiftToEdit = nil
            
        }) { shift in
            
            CreateShiftForm(dateSelected: $dateSelected, scheduledShift: shift)
                .presentationDetents([.large])
                .presentationCornerRadius(35)
                .presentationBackground(Color("allSheetBackground"))
            
        }

        
    }
}



extension View {
    func screenBounds() -> CGRect {
        return UIScreen.main.bounds
    }
}


struct ListViewRow: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var shiftStore: ShiftStore
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    let shift: SingleScheduledShift
    
    @Binding var selectedShiftToEdit: ScheduledShift?
    
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
            .textCase(nil)){
                
                ZStack{
                    VStack(alignment: .leading){
                        
                        HStack(spacing : 10){
                            
                            VStack(spacing: 3){
                                
                                HStack{
                                    Image(systemName: shift.job?.icon ?? "briefcase.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                    
                                }
                                .padding(12)
                                .background {
                                        
                                        Circle()
                                            .foregroundStyle(Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)).gradient)
                                            .frame(width: 40, height: 40)
                                        
                                    }
                                
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
                                        }, cancelAction: nil, title: "End all future repeating shifts for this shift?").showAndStack()
                                    }){
                                        HStack{
                                            Image(systemName: "clock.arrow.2.circlepath")
                                            Spacer()
                                            Text("End Repeat")
                                        }
                                    }
                                }
                                Button(action:{
                                  
                                    selectedShiftToEdit = scheduleModel.fetchScheduledShift(id: shift.id, in: viewContext)
                                    
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
                    }
                    
                    
                    
                }
            }.opacity(!purchaseManager.hasUnlockedPro ? (shift.job?.uuid?.uuidString != lastSelectedJobUUID ? 0.5 : 1.0) : 1.0)
        
    }
}
/*
struct ScheduledShiftView_Previews: PreviewProvider {
    static var dateComponents: DateComponents {
        var dateComponents = Calendar.current.dateComponents(
            [.month,
             .day,
             .year,
             .hour,
             .minute],
            from: Date())
        dateComponents.timeZone = TimeZone.current
        dateComponents.calendar = Calendar(identifier: .gregorian)
        return dateComponents
    }
    static var previews: some View {
        ScheduledShiftsView(dateSelected: .constant(dateComponents))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}*/

struct RepeatEndPicker: View {
    
    private let options = ["1 month", "2 months", "3 months"]
    private let calendar = Calendar.current
    
    @State private var selectedIndex = 1
    @Binding var selectedRepeatEnd: Date
    @Binding var dateSelected: DateComponents?
    @State private var startDate: Date
    
    init(dateSelected: Binding<DateComponents?>, selectedRepeatEnd: Binding<Date>) {
        
        _dateSelected = dateSelected

        
        let defaultDate: Date = Calendar.current.date(from: dateSelected.wrappedValue ?? DateComponents()) ?? Date()
        _startDate = State(initialValue: defaultDate)
        
        
        self._selectedRepeatEnd = selectedRepeatEnd
        let defaultRepeatEnd = calendar.date(byAdding: .month, value: 2, to: startDate)!
        self._selectedIndex = State(initialValue: self.options.firstIndex(of: "\(2) months")!)
        // set the selectedIndex to the index of the default repeat end option
    }
    
    var body: some View {
        Picker("End Repeat", selection: $selectedIndex) {
            ForEach(0..<options.count) { index in
                Text(options[index]).tag(index)
            }
        }
        .onChange(of: selectedIndex) { value in
            let months = [1, 2, 3][value]
            selectedRepeatEnd = calendar.date(byAdding: .month, value: months, to: startDate)! // Use startDate instead of selectedRepeatEnd
        }
    }
    
}

enum ReminderTime: String, CaseIterable, Identifiable {
    case oneMinute = "1m before"
    case fifteenMinutes = "15m before"
    case thirtyMinutes = "30m before"
    case oneHour = "1hr before"
    
    var id: String { self.rawValue }
    var timeInterval: TimeInterval {
        switch self {
        case .oneMinute:
            return 60
        case .fifteenMinutes:
            return 15 * 60
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        }
    }
}

