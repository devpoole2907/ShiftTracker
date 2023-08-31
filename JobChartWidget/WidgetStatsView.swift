//
//  WidgetStatsView.swift
//  ShiftTracker
//
//  Created by James Poole on 31/08/23.
//

import SwiftUI
import Charts

struct WidgetStatsView: View {
    
    var job: Job?
    
    let oldShifts: [OldShift]
    
    let statsMode: StatsMode
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
    
    var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    func formatTime(timeInHours: Double) -> String {
        let hours = Int(timeInHours)
        let minutes = Int((timeInHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }
    
    var body: some View {
        
        let lastWeekShifts = oldShifts.filter { shift in
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            return shift.shiftStartDate! > oneWeekAgo
        }
        
        let weekShifts = lastWeekShifts.map { shift in
            return ShiftToChart(shift: shift)
        }
        
        let totalDurationInHours = weekShifts.reduce(0) { $0 + $1.hoursCount }
        let totalEarnings = weekShifts.reduce(0) { $0 + $1.earnings }
        
        let gradient = statsMode.gradient
        
        let yValue = statsMode == .earnings ? "Earnings" : "Hours"
        
        
        VStack{
            HStack {
                
                let jobColor = Color(red: Double(job?.colorRed ?? 0.5), green: Double(job?.colorGreen ?? 0.5), blue: Double(job?.colorBlue ?? 0.5)).gradient
                
                Image(systemName: job?.icon ?? "briefcase.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background {
                        
                        Circle()
                            .foregroundStyle(jobColor)
                        
                        
                    }
                
                VStack(alignment: .leading, spacing: 3){
                    Text("\(job?.name ?? "Summary")")
                        .fontDesign(.rounded)
                        .bold()
                    
                    
                    Divider().frame(maxWidth: 180)
                    
                    
                    Text(statsMode == .earnings ? "\(currencyFormatter.string(from: NSNumber(value: totalEarnings)) ?? "0.00") this week" : "\(formatTime(timeInHours: totalDurationInHours)) this week")
                        .foregroundStyle(.gray)
                        .fontDesign(.rounded)
                        .bold()
                        .font(.subheadline)
                        .padding(.leading, 1.4)
                }
                
                
                
                Spacer()
                
            }
            
            
            Chart{
                ForEach(weekShifts.reversed()) { weekShift in
                    
                    BarMark(x: .value("Day", weekShift.dayOfWeek, unit: .weekday), y: .value(yValue, yValue == "Earnings" ? weekShift.earnings : weekShift.hoursCount))
                        .foregroundStyle(gradient)
                        .cornerRadius(statsMode.cornerRadius)
                        
                    
                }
                
                
            }
            
            
            
            
            .chartXScale(domain: Calendar.current.date(byAdding: .day, value: -7, to: Date())!...Date().addingTimeInterval(36400), type: .linear)
          
            .chartXAxis{
                
                
                
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    if let date = value.as(Date.self) {
                        
                        AxisValueLabel(dateFormatter.string(from: date), centered: true, collisionResolution: .disabled)
                        
                        
                    } else {
                        AxisValueLabel()
                    }
                    
                }
            }
            
            
        }
    }
    
    
}
