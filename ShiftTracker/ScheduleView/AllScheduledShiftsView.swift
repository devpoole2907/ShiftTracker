//
//  AllScheduledShiftsView.swift
//  ShiftTracker
//
//  Created by James Poole on 16/05/23.
//

import SwiftUI
import CoreData

struct AllScheduledShiftsView: View {
    
    @EnvironmentObject var shiftStore: ScheduledShiftStore
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var groupedShifts: [Date: [SingleScheduledShift]] {
        Dictionary(grouping: shiftStore.shifts, by: { $0.startDate.startOfTheDay() })
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    func formattedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d MMM"
        return dateFormatter.string(from: date)
    }
    
    var nextShiftDate: Date? {
        let currentDate = Date()
        return shiftStore.shifts
            .compactMap { $0.startDate.startOfTheDay() }
            .filter { $0 >= currentDate.startOfTheDay() }
            .min()
    }

    
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        
        if !groupedShifts.isEmpty {
            ScrollViewReader { scrollProxy in
                List {
                    ForEach(groupedShifts.keys.sorted(by: <), id: \.self) { date in
                        Section(header: Text(formattedDate(date)).textCase(.uppercase).bold().foregroundColor(textColor)) {
                            ForEach(groupedShifts[date] ?? [], id: \.self) { shift in
                                ScheduledShiftRow(shift: shift)
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
                                            
                                           // scheduleModel.deleteShift(shift, in: scheduledShifts, with: shiftStore, using: viewContext)
                                            
                                            
                                                //dismiss()
                                                CustomConfirmationAlert(action: {
                                                    scheduleModel.cancelRepeatingShiftSeries(shift: shift, with: shiftStore, using: viewContext)
                                                }, cancelAction: nil, title: "End all future repeating shifts for this shift?").showAndStack()
                                            
                                            
                                            
                                        } label: {
                                            Image(systemName: "clock.arrow.2.circlepath")
                                        }.disabled(!shift.isRepeating)
                                        
                                        
                                        
                                    }
                                
                            }
                        }//.id(date.startOfTheDay())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .foregroundColor(date < Date() ? .gray : textColor)
                    }//.id(UUID())
                }
                .onAppear {
                    if let nextShiftDate = nextShiftDate {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollProxy.scrollTo(nextShiftDate, anchor: .top)
                        }
                    }
                }
                
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
        } else {
            Text("You don't have any shifts scheduled.")
                .bold()
                .padding()
        }
    }
}

extension Date {
    func midnight() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: components) ?? self
    }
}

extension Date {
    func startOfTheDay() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: components) ?? self
    }
}


struct ScheduledShiftRow: View {
    
    @EnvironmentObject var shiftStore: ScheduledShiftStore
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    
    @Environment(\.managedObjectContext) private var viewContext
    
    let shift: SingleScheduledShift
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View{
        HStack {
            // Vertical line
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)).gradient)
                .frame(width: 4)
            
            VStack(alignment: .leading) {
                Text(shift.job?.name ?? "")
                    .bold()
                Text(shift.job?.title ?? "")
                    .foregroundStyle(.gray)
                    .bold()
            }
            Spacer()
            
            VStack(alignment: .trailing){
            
                    Text(timeFormatter.string(from: shift.startDate))
                        .font(.subheadline)
                        .bold()
                
              
                Text(timeFormatter.string(from: shift.endDate))
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.gray)
                
            }
        }
    }
}
