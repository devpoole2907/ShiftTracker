//
//  ShiftTrackerLockscreenPayWidgets.swift
//  ShiftTrackerLockscreenWidgetsExtension
//
//  Created by James Poole on 30/07/23.
//

import WidgetKit
import SwiftUI

struct ShiftTrackerLockscreenPayWidgetsView : View {
    var entry: LockscreenWidgetProvider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        
        switch family { // switches through each type of widget
        case .accessoryCircular:
            
            CircularPayWidgetView(entry: entry)
                
            
        case .accessoryInline:
            
            InlinePayWidgetView(entry: entry)
            
            
        case .accessoryRectangular:
            
            RectangularPayWidgetView(entry: entry)
                .padding(10)
                .background()
                .cornerRadius(6)
            
        @unknown default:
            Text("Unknown")
        }
        

    }
}

struct ShiftTrackerLockscreenPayWidgets: Widget {
    let kind: String = "ShiftTrackerLockscreenPayWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockscreenWidgetProvider()) { entry in
          /*  if #available(iOS 17.0, *) {
                ShiftTrackerLockscreenPayWidgetsView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {*/
                ShiftTrackerLockscreenPayWidgetsView(entry: entry)
                  
          // }
        }
        .configurationDisplayName("Current Pay")
        .description("Track your current shifts total pay.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}


struct ShiftTrackerLockscreenPayWidgets_Previews: PreviewProvider {
    static var previews: some View {
       /* if #available(iOS 17.0, *){
            ShiftTrackerLockscreenPayWidgetsView(entry: ShiftEntry(date: Date(), shiftStartDate: Date(), totalPay: 0, taxedPay: 0, isOnBreak: false))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .containerBackground(.fill.tertiary, for: .widget)
            ShiftTrackerLockscreenPayWidgetsView(entry: ShiftEntry(date: Date(), shiftStartDate: Date(), totalPay: 0, taxedPay: 0, isOnBreak: false))
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .containerBackground(.fill.tertiary, for: .widget)
            ShiftTrackerLockscreenPayWidgetsView(entry: ShiftEntry(date: Date(), shiftStartDate: Date(), totalPay: 0, taxedPay: 0, isOnBreak: false))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .containerBackground(.fill.tertiary, for: .widget)

            
        } else { */
            ShiftTrackerLockscreenPayWidgetsView(entry: ShiftEntry(date: Date(), shiftStartDate: Date(), totalPay: 0, taxedPay: 0, isOnBreak: false))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .padding()
                .background()
        //}
    }
}

// the wide rectangle widget

struct RectangularPayWidgetView: View {
    
    var entry: LockscreenWidgetProvider.Entry
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    var body: some View {
        
        
        if let shiftStartDate = entry.shiftStartDate {
            
            
            
            
            VStack(alignment: .leading) {
                
                
                if entry.isOnBreak{
                    Text("On break")
                        .font(.system(size: 20, weight: .bold))
                } else {
                    
                    Text("Current pay: \(currencyFormatter.currencySymbol ?? "")\(entry.taxedPay, specifier: "%.2f")")
                        .font(.system(size: 20, weight: .bold))
                    
                }
                
                
            }
            
        } else {
            
            Text("No current shift").bold()
            
        }
        
        

        
        
    }
    
    
}

// the widget inline above the time

struct InlinePayWidgetView: View {
    var entry: LockscreenWidgetProvider.Entry
    var body: some View {
        
        if let shiftStartDate = entry.shiftStartDate {
            
            if entry.isOnBreak{
                Text("On Break")
                    .bold()
            } else {
                
                Text("$\(entry.taxedPay, specifier: "%.2f")")
                    .bold()
                
            }
            
        } else {
            
            Text("No current shift")
            
        }
        
        
    }
    
    
}

// the circular widget

struct CircularPayWidgetView: View {
    var entry: LockscreenWidgetProvider.Entry
    var body: some View {
        
        if let shiftStartDate = entry.shiftStartDate {
            
            if entry.isOnBreak{
                Text("\(Image(systemName: "pause.circle.fill"))")
            } else {
                
                Text("$\(entry.taxedPay, specifier: "%.0f")")
                    .font(.system(size: 20, weight: .bold))
                
            }
      

            
            
        } else {
            
            Image(systemName: "briefcase.circle")
            
        }
        
        
    }
    
    
}
