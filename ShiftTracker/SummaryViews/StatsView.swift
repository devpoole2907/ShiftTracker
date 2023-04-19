//
//  StatsView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//

import SwiftUI

struct StatsView: View {
    @Environment(\.colorScheme) var colorScheme
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var shifts: FetchedResults<OldShift>
    @State private var selection = 0
    let options = ["W", "M", "3M", "6M", "Y", "All"]
    let statsMode: StatsMode
    
    // ...
    
    
    func convertHoursToHourMinuteFormat(hours: Double) -> String {
            let hour = Int(hours)
            let minute = Int((hours - Double(hour)) * 60)
            return "\(hour) hr \(minute) min"
        }
    
    
        
        var body: some View{
            let textColor: Color = colorScheme == .dark ? .white : .black
            let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8)
            NavigationStack{
                List{
                    
                    
                    let today = Date()
                    let calendar = Calendar.current
                    let currentWeekday = calendar.component(.weekday, from: today)

                    // Calculate the number of days to subtract to get to the previous Monday
                    let daysToSubtract = currentWeekday == 1 ? 6 : (currentWeekday == 2 ? 0 : currentWeekday - 2)


                    // Calculate the date for the previous Monday
                    // Calculate the date for the previous Monday without time components
                    let previousMondayWithTime = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
                    let previousMondayComponents = calendar.dateComponents([.year, .month, .day], from: previousMondayWithTime)
                    let previousMonday = calendar.date(from: previousMondayComponents)!


                    let lastWeekShifts = shifts.filter { shift in
                        return shift.shiftStartDate! >= previousMonday
                    }

                    let weekShifts = lastWeekShifts.map { shift in
                        return singleShift(shift: shift)
                    }.reversed()
                    
                    let lastMonthShifts = shifts.filter { shift in
                        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
                        return shift.shiftStartDate! > oneMonthAgo
                    }
                    
                    let monthShifts = lastMonthShifts.map { shift in
                        return singleShift(shift: shift)
                    }.reversed()
                    
                    let lastThreeMonthShifts = shifts.filter { shift in
                        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
                        return shift.shiftStartDate! > threeMonthsAgo
                    }
                    
                    let threeMonthShifts = lastThreeMonthShifts.map { shift in
                        return singleShift(shift: shift)
                    }.reversed()
                    
                    
                    let groupedShifts = Dictionary(grouping: shifts) { shift -> Date in
                        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shift.shiftStartDate!))!
                        return startOfWeek
                    }.filter { weekStart, _ in
                        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
                        return weekStart > sixMonthsAgo
                    }
                    
                    let sixMonthShifts = groupedShifts.map { weekStart, shiftsInWeek -> fullWeekShifts in
                        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "d/M"
                        
                        let startDateString = dateFormatter.string(from: weekStart)
                        let endDateString = dateFormatter.string(from: endDate)
                        
                        let weekShifts = shiftsInWeek.map { shift in
                            return singleShift(shift: shift)
                        }
                        
                        let totalHoursCount = weekShifts.reduce(0.0) { $0 + $1.hoursCount }
                        let totalPay = weekShifts.reduce(0.0) { $0 + $1.totalPay }
                        let totalBreakDuration = weekShifts.reduce(0.0) { $0 + $1.breakDuration }
                        
                        return fullWeekShifts(hoursCount: totalHoursCount, totalPay: totalPay, breakDuration: totalBreakDuration, startDate: startDateString, endDate: endDateString)
                    }.reversed()
                    
                    
                    
                    
                    
                    let lastTwelveMonthShifts = shifts.filter { shift in
                        let twelveMonthsAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
                        return shift.shiftStartDate! > twelveMonthsAgo
                    }
                    
                    let twelveMonthShifts = lastTwelveMonthShifts.map { shift in
                        return singleShift(shift: shift)
                    }.reversed()
                    
                    
                    let allShifts = shifts.map { shift in
                        return singleShift(shift: shift)
                    }.reversed()
                    
                    let totalPayInWeek = weekShifts.reduce(0) { total, weekShift in
                        total + weekShift.totalPay
                    }
                    let totalHoursInWeek = weekShifts.reduce(0) { total, weekShift in
                        total + weekShift.hoursCount
                    }
                    let totalBreaksInWeek = weekShifts.reduce(0) { total, weekShift in
                        total + weekShift.breakDuration
                    }
                    
                    let totalPayInMonth = monthShifts.reduce(0) { total, weekShift in
                        total + weekShift.totalPay
                    }
                    let totalHoursInMonth = monthShifts.reduce(0) { total, weekShift in
                        total + weekShift.hoursCount
                    }
                    let totalBreaksInMonth = monthShifts.reduce(0) { total, weekShift in
                        total + weekShift.breakDuration
                    }
                    
                    let totalPayInThreeMonths = threeMonthShifts.reduce(0) { total, weekShift in
                        total + weekShift.totalPay
                    }
                    let totalHoursInThreeMonths = threeMonthShifts.reduce(0) { total, weekShift in
                        total + weekShift.hoursCount
                    }
                    let totalBreaksInThreeMonths = threeMonthShifts.reduce(0) { total, weekShift in
                        total + weekShift.breakDuration
                    }

                    
                    let totalPayInSixMonths = sixMonthShifts.reduce(0) { total, weekShift in
                        total + weekShift.totalPay
                    }
                    let totalHoursInSixMonths = sixMonthShifts.reduce(0) { total, weekShift in
                        total + weekShift.hoursCount
                    }
                    let totalBreaksInSixMonths = sixMonthShifts.reduce(0) { total, weekShift in
                        total + weekShift.breakDuration
                    }
                    
                    let totalPayInTwelveMonths = twelveMonthShifts.reduce(0) { total, weekShift in
                        total + weekShift.totalPay
                    }
                    let totalHoursInTwelveMonths = twelveMonthShifts.reduce(0) { total, weekShift in
                        total + weekShift.hoursCount
                    }
                    let totalBreaksInTwelveMonths = twelveMonthShifts.reduce(0) { total, weekShift in
                        total + weekShift.breakDuration
                    }
                    
                    let totalPayAllTime = allShifts.reduce(0) { total, weekShift in
                        total + weekShift.totalPay
                    }
                    let totalHoursAllTime = allShifts.reduce(0) { total, weekShift in
                        total + weekShift.hoursCount
                    }
                    let totalBreaksAllTime = allShifts.reduce(0) { total, weekShift in
                        total + weekShift.breakDuration
                    }
                    
                    let averagePayPerShift: Double = weekShifts.count > 0 ? totalPayInWeek / Double(weekShifts.count) : 0
                    let averageHoursPerShift: Double = weekShifts.count > 0 ? Double(totalHoursInWeek) / Double(weekShifts.count) : 0
                    let averageBreakPerShift: Double = weekShifts.count > 0 ? totalBreaksInWeek / Double(weekShifts.count) : 0
                    
                    let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
                    let todayNoTime = calendar.date(from: todayComponents)!

                    let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: todayNoTime)!
                    let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: todayNoTime)!

                    let previousWeekShifts = shifts.filter { shift in
                        return shift.shiftStartDate! <= eightDaysAgo && shift.shiftStartDate! > fourteenDaysAgo
                    }

                    
                    let previousWeekShiftsMapped = previousWeekShifts.map { shift in
                        return singleShift(shift: shift)
                    }.reversed()
                    
                    
                    let totalPayInPreviousWeek = previousWeekShiftsMapped.reduce(0) { total, weekShift in
                        total + Int(weekShift.totalPay)
                    }
                    let totalHoursInPreviousWeek = previousWeekShiftsMapped.reduce(0) { total, weekShift in
                        total + Int(weekShift.hoursCount)
                    }
                    let totalBreaksInPreviousWeek = previousWeekShiftsMapped.reduce(0) { total, weekShift in
                        total + Int(weekShift.breakDuration)
                    }
                    
                    let averageHoursPerShiftPreviousWeek: Double = previousWeekShiftsMapped.count > 0 ? Double(totalHoursInPreviousWeek) / Double(previousWeekShiftsMapped.count) : 0
                    let averagePayPerShiftPreviousWeek: Double = previousWeekShiftsMapped.count > 0 ? Double(totalPayInPreviousWeek) / Double(previousWeekShiftsMapped.count) : 0
                    let averageBreakPerShiftPreviousWeek: Double = previousWeekShiftsMapped.count > 0 ? Double(totalBreaksInPreviousWeek) / Double(previousWeekShiftsMapped.count) : 0
                    
                    let earningsDifference = averagePayPerShift - averagePayPerShiftPreviousWeek
                    let hoursDifference = averageHoursPerShift - averageHoursPerShiftPreviousWeek
                    let breaksDifference = averageBreakPerShift - averageBreakPerShiftPreviousWeek
                    
                    
                    
                if statsMode == .earnings {
                    VStack(alignment: .leading){
                        if selection == 0{
                            
                            ChartView(graphedShifts: weekShifts, chartDataType: .totalPay, chartDateType: .day, barColor: .green, yDomain: 1000, chartTitle: "$\(String(format: "%.2f", totalPayInWeek))")
                                
                        }
                        else if selection == 1{
                            ChartView(graphedShifts: monthShifts, chartDataType: .totalPay, chartDateType: .date, barColor: .green, yDomain: 1000, chartTitle: "$\(String(format: "%.2f", totalPayInMonth))")
                               
                        }
                        else if selection == 2{
                            ChartView(graphedShifts: threeMonthShifts, chartDataType: .totalPay, chartDateType: .date, barColor: .green, yDomain: 1000, chartTitle: "$\(String(format: "%.2f", totalPayInThreeMonths))")
                             
                        }
                        else if selection == 3 {
                            ChartView(graphedWeeks: sixMonthShifts, chartDataType: .totalPay, chartDateType: .date, barColor: .green, yDomain: 6000, chartTitle: "$\(String(format: "%.2f", totalPayInSixMonths))")
                        }
                        else if selection == 4 {
                            ChartView(graphedShifts: twelveMonthShifts, chartDataType: .totalPay, chartDateType: .date, barColor: .green, yDomain: 1000, chartTitle: "$\(String(format: "%.2f", totalPayInTwelveMonths))")
                        }
                        else {
                            ChartView(graphedShifts: allShifts, chartDataType: .totalPay, chartDateType: .date, barColor: .green, yDomain: 1000, chartTitle: "$\(String(format: "%.2f", totalPayAllTime))")
                        }
                        Picker(selection: $selection, label: Text("Duration")) {
                            ForEach(0..<6) { index in
                                Text(options[index]).bold()
                            }
                        }
                        .listRowSeparator(.hidden)
                        .pickerStyle(.segmented)
                        //.padding(.horizontal, 10)
                    }
                   // .listRowBackground(Color.clear)
                    Section{
                        HighlightView(title: "Earnings", subtitle: "You're earning an average of $\(String(format: "%.2f", averagePayPerShift)) per shift this week", titleColor: .green, subtitleColor: textColor, average: averagePayPerShift, statsMode: .earnings)
                      
                    } header : {
                        Text("Highlights")
                            .font(.title)
                            .bold()
                            .textCase(nil)
                            .foregroundColor(textColor)
                            .padding(.leading, -12)
                    }
                 /*   Section{
                        HighlightView(title: "Earnings", subtitle: "You're averaging $\(String(format: "%.1f", abs(earningsDifference))) \(earningsDifference >= 0 ? "more" : "less") per shift this week compared to last week", titleColor: .green, subtitleColor: textColor, average: earningsDifference, lastWeekAverage: averagePayPerShiftPreviousWeek, thisWeekAverage: averagePayPerShift, statsMode: .earnings)
                    } */
                    Section{
                        Spacer()
                    }.listRowBackground(Color.clear)
                }
                else if statsMode == .hours {
                    VStack(alignment: .leading){
                        if selection == 0{
                            ChartView(graphedShifts: weekShifts, chartDataType: .hoursCount, chartDateType: .day, barColor: .orange, yDomain: 16, chartTitle: convertHoursToHourMinuteFormat(hours: totalHoursInWeek - totalBreaksInWeek))
                        }
                        else if selection == 1{
                            ChartView(graphedShifts: monthShifts, chartDataType: .hoursCount, chartDateType: .date, barColor: .orange, yDomain: 16, chartTitle: convertHoursToHourMinuteFormat(hours: totalHoursInMonth - totalBreaksInMonth))
                        }
                        else if selection == 2{
                            ChartView(graphedShifts: threeMonthShifts, chartDataType: .hoursCount, chartDateType: .date, barColor: .orange, yDomain: 16, chartTitle: convertHoursToHourMinuteFormat(hours: totalHoursInThreeMonths - totalBreaksInThreeMonths))
                        }
                        else if selection == 3 {
                            ChartView(graphedWeeks: sixMonthShifts, chartDataType: .hoursCount, chartDateType: .date, barColor: .orange, yDomain: 110, chartTitle: convertHoursToHourMinuteFormat(hours: totalHoursInSixMonths - totalBreaksInSixMonths))
                        }
                        else if selection == 4 {
                            ChartView(graphedShifts: twelveMonthShifts, chartDataType: .hoursCount, chartDateType: .date, barColor: .orange, yDomain: 16, chartTitle: convertHoursToHourMinuteFormat(hours: totalHoursInTwelveMonths - totalBreaksInTwelveMonths))
                        }
                        else {
                            ChartView(graphedShifts: allShifts, chartDataType: .hoursCount, chartDateType: .date, barColor: .orange, yDomain: 16, chartTitle: convertHoursToHourMinuteFormat(hours: totalHoursAllTime - totalBreaksAllTime))
                        }
                        Picker(selection: $selection, label: Text("Duration")) {
                            ForEach(0..<6) { index in
                                Text(options[index]).bold()
                            }
                        }
                        .listRowSeparator(.hidden)
                        .pickerStyle(.segmented)
                        //.padding(.horizontal, 10)
                    }
                    //.listRowBackground(Color.clear)
                    Section{
                        HighlightView(title: "Hours", subtitle: "You're working \(String(format: "%.1f", averageHoursPerShift)) hours on average per shift this week", titleColor: .orange, subtitleColor: textColor, average: averageHoursPerShift, statsMode: .hours)
                    } header : {
                        Text("Highlights")
                            .font(.title)
                            .bold()
                            .textCase(nil)
                            .foregroundColor(textColor)
                            .padding(.leading, -12)
                    }
                 /*   Section{
                        HighlightView(title: "Hours", subtitle: "You're averaging \(String(format: "%.1f", abs(hoursDifference))) hours \(hoursDifference >= 0 ? "more" : "less") per shift this week compared to last week", titleColor: .orange, subtitleColor: textColor, average: hoursDifference, lastWeekAverage: averageHoursPerShiftPreviousWeek, thisWeekAverage: averageHoursPerShift, statsMode: .hours)
                    } */
                    Section{
                        Spacer()
                    }.listRowBackground(Color.clear)
                }
                else {
                    VStack(alignment: .leading){
                        if selection == 0{
                            ChartView(graphedShifts: weekShifts, chartDataType: .breakDuration, chartDateType: .day, barColor: .indigo, yDomain: 4, chartTitle: convertHoursToHourMinuteFormat(hours: totalBreaksInWeek))
                        }
                        else if selection == 1{
                            ChartView(graphedShifts: monthShifts, chartDataType: .breakDuration, chartDateType: .date, barColor: .indigo, yDomain: 4, chartTitle: convertHoursToHourMinuteFormat(hours: totalBreaksInMonth))
                            
                        }
                        else if selection == 2 {
                            ChartView(graphedShifts: threeMonthShifts, chartDataType: .breakDuration, chartDateType: .date, barColor: .indigo, yDomain: 4, chartTitle: convertHoursToHourMinuteFormat(hours: totalBreaksInThreeMonths))
                        }
                        else if selection == 3 {
                            ChartView(graphedWeeks: sixMonthShifts, chartDataType: .breakDuration, chartDateType: .date, barColor: .indigo, yDomain: 35, chartTitle: convertHoursToHourMinuteFormat(hours: totalBreaksInSixMonths))
                        }
                        else if selection == 4 {
                            ChartView(graphedShifts: twelveMonthShifts, chartDataType: .breakDuration, chartDateType: .date, barColor: .indigo, yDomain: 4, chartTitle: convertHoursToHourMinuteFormat(hours: totalBreaksInTwelveMonths))
                        }
                        else {
                            ChartView(graphedShifts: allShifts, chartDataType: .breakDuration, chartDateType: .date, barColor: .indigo, yDomain: 4, chartTitle: convertHoursToHourMinuteFormat(hours: totalBreaksAllTime))
                        }
                        Picker(selection: $selection, label: Text("Duration")) {
                            ForEach(0..<6) { index in
                                Text(options[index]).bold()
                            }
                        }
                        .listRowSeparator(.hidden)
                        .pickerStyle(.segmented)
                        //.padding(.horizontal, 10)
                    }
                    //.listRowBackground(Color.clear)
                    Section{
                        HighlightView(title: "Breaks", subtitle: "You're on break for \(String(format: "%.1f", averageBreakPerShift)) hours on average per shift this week", titleColor: .indigo, subtitleColor: textColor, average: averageBreakPerShift, statsMode: .breaks)
                    } header : {
                        Text("Highlights")
                            .font(.title)
                            .bold()
                            .textCase(nil)
                            .foregroundColor(textColor)
                            .padding(.leading, -12)
                    }
                    Section{
                        Spacer()
                    }.listRowBackground(Color.clear)
                }
            }
        }
    }
}
