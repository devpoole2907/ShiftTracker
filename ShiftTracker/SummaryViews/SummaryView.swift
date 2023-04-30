//
//  SummaryView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/03/23.
//

import SwiftUI
import SwiftUICharts
import Charts
import Haptics

struct SummaryView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selection = 0
    
    @State private var weeklyTotal = 0.0
    @State private var weeklyTaxedTotal = 0.0
    
    @Environment(\.managedObjectContext) private var viewContext
    
    
    @State private var refreshingID = UUID()
    
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var shifts: FetchedResults<OldShift>
    
    let options = ["Week", "Month"]
    
    var body: some View {
  
        let textColor: Color = colorScheme == .dark ? .white : .black
        let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8)
        let cardBackground: Color = colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color(red: 99/255, green: 99/255, blue: 102/255)
        
        NavigationStack{
            VStack{
                
                List {
                    Section(header: Text("")){
                        let today = Date()
                        let calendar = Calendar.current
                        let currentWeekday = calendar.component(.weekday, from: today)

                        // Calculate the number of days to subtract to get to the previous Monday
                        let daysToSubtract = currentWeekday == 1 ? 6 : (currentWeekday == 2 ? 0 : currentWeekday - 2)



                        // Calculate the date for the previous Monday
                        let previousMonday = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!

                        let lastWeekShifts = shifts.filter { shift in
                            return shift.shiftStartDate! >= previousMonday
                        }
                        
                        let totalPayLastWeek = lastWeekShifts.reduce(0) { $0 + $1.totalPay }
                        let taxedPayLastWeek = lastWeekShifts.reduce(0) { $0 + $1.taxedPay }
                        
                        /*Text("You earned \(totalPayLastWeek, specifier: "$%.2f") in the last 7 days, with \(totalPayLastWeek-taxedPayLastWeek, specifier: "$%.2f") going to tax.")*/
                        NavigationLink(destination: StatsView(statsMode: .earnings).navigationTitle("Earnings")){
                            VStack(alignment: .leading, spacing: 5){
                                Text("Earnings")
                                    .foregroundColor(.green)
                                    .font(.subheadline)
                                    .bold()
                                Text("\(totalPayLastWeek, specifier: "$%.2f")")
                                    .foregroundColor(textColor)
                                    .font(.title)
                                    .bold()
                                Text("Earned this week")
                                    .foregroundColor(subTextColor)
                                    .bold()
                                    .padding(.bottom, 5)
                            }
                        }
                    }
                    
                    .listRowBackground(Color.primary.opacity(0.03))
                    .listRowSeparator(.hidden)
                    Section{
                        let (totalHoursLastWeek, totalBreakDurationLastWeek) = calculateTotalHoursAndBreaks()
                        
                        NavigationLink(destination: StatsView(statsMode: .hours).navigationTitle("Hours")){
                            VStack(alignment: .leading, spacing: 5){
                                Text("Hours Worked")
                                    .foregroundColor(.orange)
                                    .font(.subheadline)
                                    .bold()
                                Text(convertHoursToHourMinuteFormat(hours: totalHoursLastWeek))
                                    .foregroundColor(textColor)
                                    .font(.title)
                                    .bold()
                                Text("Worked this week")
                                    .foregroundColor(subTextColor)
                                    .bold()
                                    .padding(.bottom, 5)
                            }
                        }
                    }
                    .listRowBackground(Color.primary.opacity(0.03))
                    .listRowSeparator(.hidden)
                    Section{
                        let (totalHoursLastWeek, totalBreakDurationLastWeek) = calculateTotalHoursAndBreaks()
                        
                        
                        NavigationLink(destination: StatsView(statsMode: .breaks).navigationTitle("Breaks")){
                            VStack(alignment: .leading, spacing: 5){
                                Text("Breaks")
                                    .foregroundColor(.indigo)
                                    .font(.subheadline)
                                    .bold()
                                Text(convertHoursToHourMinuteFormat(hours: totalBreakDurationLastWeek))
                                    .foregroundColor(textColor)
                                    .font(.title)
                                    .bold()
                                Text("On break this week")
                                    .foregroundColor(subTextColor)
                                    .bold()
                                    .padding(.bottom, 5)
                            }
                        }
                    }
                    .listRowBackground(Color.primary.opacity(0.03))
                    .listRowSeparator(.hidden)
                }.id(refreshingID)
                
                    .onAppear{
                        viewContext.reset()
                        self.refreshingID = UUID()
                    }
                
                //.padding(.top, 10)
                .listStyle(InsetGroupedListStyle())
                
            }.scrollContentBackground(.hidden)
            .navigationTitle("Summary")
        }
    }
    func dayNames(from shifts: [OldShift]) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        
        return shifts.map { shift in
            let dayName = formatter.string(from: shift.shiftStartDate!)
            let taxedPay = String(format: "%.2f", shift.taxedPay)
            return "\(dayName)\n$\(taxedPay)"
        }
    }
    
    func convertHoursToHourMinuteFormat(hours: Double) -> String {
            let hour = Int(hours)
            let minute = Int((hours - Double(hour)) * 60)
            return "\(hour) hr \(minute) min"
        }
    
    func calculateTotalHoursAndBreaks() -> (totalHours: Double, totalBreaks: Double) {
        
        let today = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: today)

        // Calculate the number of days to subtract to get to the previous Monday
        let daysToSubtract = currentWeekday == 1 ? 6 : (currentWeekday == 2 ? 0 : currentWeekday - 2)



        // Calculate the date for the previous Monday
        let previousMondayWithTime = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
        let previousMondayComponents = calendar.dateComponents([.year, .month, .day], from: previousMondayWithTime)
        let previousMonday = calendar.date(from: previousMondayComponents)!

        let lastWeekShifts = shifts.filter { shift in
            return shift.shiftStartDate! >= previousMonday
        }
        
        var totalHoursLastWeek = 0.0
        var totalBreakDurationLastWeek = 0.0
        
        lastWeekShifts.forEach { shift in
            if let shiftStartDate = shift.shiftStartDate,
               let shiftEndDate = shift.shiftEndDate {
                let shiftDuration = shiftEndDate.timeIntervalSince(shiftStartDate)

                var totalShiftBreakDuration = 0.0
                            if let breaks = shift.breaks as? Set<Break> {
                                breaks.forEach { breakInstance in
                                    if let breakStartDate = breakInstance.startDate,
                                       let breakEndDate = breakInstance.endDate {
                                        let breakDuration = breakEndDate.timeIntervalSince(breakStartDate)
                                        totalShiftBreakDuration += breakDuration
                                    }
                                }
                            }
                
                let adjustedShiftDuration = shiftDuration - totalShiftBreakDuration
                            
                            totalHoursLastWeek += adjustedShiftDuration / 3600
                            totalBreakDurationLastWeek += totalShiftBreakDuration / 3600
            }
        }
        
        return (totalHoursLastWeek, totalBreakDurationLastWeek)
        
    }
    
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView()
    }
}

extension Date {
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
    
    var weekOfYear: Int {
        let calendar = Calendar.current
        return calendar.component(.weekOfYear, from: self)
    }
}


extension DateFormatter {
    static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}










