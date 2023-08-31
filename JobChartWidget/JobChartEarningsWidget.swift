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
    
   
    


    var body: some View {
        

            
        WidgetStatsView(job: entry.job, oldShifts: entry.oldShifts, statsMode: .earnings)
            
         
        .padding(.horizontal)
      
    }
}

struct JobChartEarningsWidget: Widget {
    let kind: String = "JobChartEarningsWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SelectJobIntent.self, provider: ChartWidgetProvider()) { entry in
       
                JobChartEarningsWidgetEntryView(entry: entry)
                .widgetBackgroundModifier()
             
        }
        .configurationDisplayName("Weekly Earnings")
        .description("A summary of your earnings this week. Tap to select job.")
        .supportedFamilies([.systemMedium])
    }
}
