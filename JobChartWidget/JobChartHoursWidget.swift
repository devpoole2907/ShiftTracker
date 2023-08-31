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
    
  
    
    @Environment(\.widgetFamily) var family
    
    var entry: ChartWidgetProvider.Entry
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
                formatter.dateFormat = "EEE"
        return formatter
    }

    var body: some View {
        
        VStack {
            
            WidgetStatsView(job: entry.job, oldShifts: entry.oldShifts, statsMode: .hours)

        }.padding(.horizontal)
        
    }
}

struct JobChartHoursWidget: Widget {
    let kind: String = "JobChartHoursWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SelectJobIntent.self, provider: ChartWidgetProvider()) { entry in
           
                JobChartHoursWidgetEntryView(entry: entry)
                .widgetBackgroundModifier()
               
        }
        .configurationDisplayName("Weekly Hours")
        .description("A summary of your hours this week. Tap to select job.")
        .supportedFamilies([.systemMedium])
    }
}


