//
//  JobChartEarningsWidget.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import Foundation
import WidgetKit
import SwiftUI
import CoreData
import Charts

struct JobChartEarningsWidgetEntryView : View {
    
    @Environment(\.widgetFamily) var family
    
    var entry: ChartWidgetProvider.Entry
    
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

    var body: some View {
        
        VStack {
            
            let lastWeekShifts = entry.oldShifts.filter { shift in
                let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                return shift.shiftStartDate! > oneWeekAgo
            }
            
            let weekShifts = lastWeekShifts.map { shift in
                return ShiftToChart(shift: shift)
            }.reversed()
            
            let totalEarnings = weekShifts.reduce(0) { $0 + $1.earnings }
    
            
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
                    
                    
                    Text("\(currencyFormatter.string(from: NSNumber(value: totalEarnings)) ?? "0.00") this week")
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
                        BarMark(x: .value("Day", weekShift.dayOfWeek, unit: .weekday), y: .value("Earnings", weekShift.earnings))
                            .foregroundStyle(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 198 / 255, green: 253 / 255, blue: 80 / 255),
                                    Color(red: 112 / 255, green: 218 / 255, blue: 65 / 255)
                                ]),
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

struct JobChartEarningsWidget: Widget {
    let kind: String = "JobChartEarningsWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SelectJob.self, provider: ChartWidgetProvider()) { entry in
          /*  if #available(iOS 17.0, *) {
                JobChartWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else { */
                JobChartEarningsWidgetEntryView(entry: entry)
                .padding(.horizontal, 5)
                .padding(.bottom, 8)
                .padding(.top, 10)
            
                    .background()
          //  }
        }
        .configurationDisplayName("Weekly Earnings")
        .description("A summary of your earnings this week. Tap to select job.")
        .supportedFamilies([.systemMedium])
    }
}
