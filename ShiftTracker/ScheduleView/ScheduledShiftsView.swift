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
    
    @EnvironmentObject var shiftStore: ScheduledShiftStore
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var dateSelected: DateComponents?
    
    
    var body: some View {
        Group {
            let foundShifts = shiftStore.shifts.filter { $0.startDate.startOfDay == dateSelected?.date?.startOfDay ?? Date().startOfDay}
                if !foundShifts.isEmpty {
                    ForEach(foundShifts) { shift in
                        ListViewRow(shift: shift)
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
                    }
                
                } else {
                    Section{
                        Text("You have no shifts scheduled on this date.")
                            .bold()
                            .padding()
                    }.listRowBackground(Color("SquaresColor"))
                }
            
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
    @EnvironmentObject var shiftStore: ScheduledShiftStore
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    
    let shift: SingleScheduledShift
    
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
                            Image(systemName: shift.job?.icon ?? "briefcase.fill")
                                .padding(12)
                                .foregroundStyle(.white)
                                .font(.title2)
                                .background {
                                    
                                    Circle()
                                        .foregroundStyle(Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)).gradient)
                                    
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
                                }.disabled(!shift.isRepeating)
                                
                                Button(action:{
                                  
                                    
                                }){
                                    HStack{
                                        Image(systemName: "pencil")
                                        Spacer()
                                        Text("Edit")
                                    }
                                }.disabled(true)
                                
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
            }
        
    }
}

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
}

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

