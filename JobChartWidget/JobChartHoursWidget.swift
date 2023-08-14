//
//  JobChartHoursWidget.swift
//  JobChartHoursWidget
//
//  Created by James Poole on 13/08/23.
//

import WidgetKit
import SwiftUI
import CoreData
import Charts

struct JobChartHoursWidgetEntryView : View {
    
    func formatTime(timeInHours: Double) -> String {
       let hours = Int(timeInHours)
       let minutes = Int((timeInHours - Double(hours)) * 60)
       return "\(hours)h \(minutes)m"
   }
    
    @Environment(\.widgetFamily) var family
    
    var entry: ChartWidgetProvider.Entry
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
                formatter.dateFormat = "EEE"
        return formatter
    }

    var body: some View {
        
        VStack {
            
            let lastWeekShifts = entry.oldShifts.filter { shift in
                let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                return shift.shiftStartDate! > oneWeekAgo
            }
            
            let weekShifts = lastWeekShifts.map { shift in
                return ShiftToChart(shift: shift)
            }.reversed()
            
            let totalDurationInHours = weekShifts.reduce(0) { $0 + $1.hoursCount }
               // let total = totalDurationInSeconds / 3600.0
            
            HStack {
                
                let jobColor = Color(red: Double(entry.job?.colorRed ?? 0.5), green: Double(entry.job?.colorGreen ?? 0.5), blue: Double(entry.job?.colorBlue ?? 0.5)).gradient
                
                Image(systemName: entry.job?.icon ?? "briefcase.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background {
                        
                        Circle()
                            .foregroundStyle(jobColor)
                        
                        
                    }
                
                VStack(alignment: .leading, spacing: 3){
                    Text("\(entry.job?.name ?? "Summary")")
                        .fontDesign(.rounded)
                        .bold()
                    
                    
                    Divider().frame(maxWidth: 180)
                    
                    
                    Text("\(formatTime(timeInHours: totalDurationInHours)) this week")
                        .foregroundStyle(.gray)
                        .fontDesign(.rounded)
                        .bold()
                        .font(.subheadline)
                        .padding(.leading, 1.4)
                }
                
                
                
                Spacer()
                
            }
            
            VStack(spacing: 5){
                
               
                
                Chart{
                    ForEach(weekShifts) { weekShift in
                        BarMark(x: .value("Day", weekShift.dayOfWeek, unit: .weekday), y: .value("Hours", weekShift.hoursCount))
                            .foregroundStyle(LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                startPoint: .top,
                                endPoint: .bottom))
                            .cornerRadius(5)
                        
                    }
                    
                    
                }
                
       
        
                
                .chartXScale(domain: Calendar.current.date(byAdding: .day, value: -7, to: Date())!...Date(), type: .linear)
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
            
           // Text(entry.emoji)
        }.padding(.horizontal)
        
        .widgetURL(URL(string: "shifttrackerapp://summary"))
    }
}

struct JobChartHoursWidget: Widget {
    let kind: String = "JobChartHoursWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SelectJob.self, provider: ChartWidgetProvider()) { entry in
          /*  if #available(iOS 17.0, *) {
                JobChartHoursWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else { */
                JobChartHoursWidgetEntryView(entry: entry)
                .padding(.horizontal, 5)
                .padding(.bottom, 8)
                .padding(.top, 10)
            
                    .background()
           // }
        }
        .configurationDisplayName("Weekly Hours")
        .description("A summary of your hours this week. Tap to select job.")
        .supportedFamilies([.systemMedium])
    }
}


