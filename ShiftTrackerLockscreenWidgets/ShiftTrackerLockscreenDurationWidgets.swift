//
//  ShiftTrackerLockscreenWidgets.swift
//  ShiftTrackerLockscreenWidgets
//
//  Created by James Poole on 30/07/23.
//

import WidgetKit
import SwiftUI

struct ShiftTrackerLockscreenDurationWidgetsView : View {
    var entry: LockscreenWidgetProvider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        
        switch family { // switches through each type of widget
        case .accessoryCircular:
            
            CircularWidgetView(entry: entry)
                
            
        case .accessoryInline:
            
            InlineWidgetView(entry: entry)
            
            
        case .accessoryRectangular:
            
            RectangularWidgetView(entry: entry)
                .padding(10)
                .background()
                .cornerRadius(6)
            
        @unknown default:
            Text("Unknown")
        }
        

    }
}

struct ShiftTrackerLockscreenDurationWidgets: Widget {
    let kind: String = "ShiftTrackerLockscreenWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockscreenWidgetProvider()) { entry in
      
                ShiftTrackerLockscreenDurationWidgetsView(entry: entry)
                .widgetBackgroundModifier()
     
        }
        .configurationDisplayName("Shift Duration")
        .description("Track your current shift progress.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}


struct ShiftTrackerLockscreenDurationWidgets_Previews: PreviewProvider {
    static var previews: some View {
       /* if #available(iOS 17.0, *){
            ShiftTrackerLockscreenDurationWidgetsView(entry: ShiftEntry(date: Date(), shiftStartDate: Date(), totalPay: 0, taxedPay: 0, isOnBreak: false))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .containerBackground(.fill.tertiary, for: .widget)
            ShiftTrackerLockscreenDurationWidgetsView(entry: ShiftEntry(date: Date(), shiftStartDate: Date(), totalPay: 0, taxedPay: 0, isOnBreak: false))
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .containerBackground(.fill.tertiary, for: .widget)
            ShiftTrackerLockscreenDurationWidgetsView(entry: ShiftEntry(date: Date(), shiftStartDate: Date(), totalPay: 0, taxedPay: 0, isOnBreak: false))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .containerBackground(.fill.tertiary, for: .widget)

            
        } else { */
            ShiftTrackerLockscreenDurationWidgetsView(entry: ShiftEntry(date: Date(), shiftStartDate: Date(), totalPay: 0, taxedPay: 0, isOnBreak: false))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
           
                .padding()
                .background()
       // }
    }
}

// the wide rectangle widget

struct RectangularWidgetView: View {
    
    var entry: LockscreenWidgetProvider.Entry
    
    var body: some View {
        
        
        if let shiftStartDate = entry.shiftStartDate {
            
            VStack(alignment: .leading) {
                Text("Shift Duration:")
                Text(shiftStartDate, style: .timer)
                
                
                
                
            }.bold()
            
        } else {
            
            Text("No current shift").bold()
            
        }
        

        
        
    }
    
    
}

// the widget inline above the time

struct InlineWidgetView: View {
    var entry: LockscreenWidgetProvider.Entry
    var body: some View {
        
        if let shiftStartDate = entry.shiftStartDate {
            
            HStack {
                Image(systemName: "clock")
                Text(shiftStartDate, style: .timer)

            }
            
        } else {
            
            Text("No current shift")
            
        }
        
        
    }
    
    
}

// the circular widget

struct CircularWidgetView: View {
    var entry: LockscreenWidgetProvider.Entry
    var body: some View {
        
        if let shiftStartDate = entry.shiftStartDate {
            

                Text(shiftStartDate, style: .timer)

            
            
        } else {
            
            Text("No shift")
            
        }
        
        
    }
    
    
}
