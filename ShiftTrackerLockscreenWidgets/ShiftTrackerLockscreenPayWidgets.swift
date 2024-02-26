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
                .padding(5)
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
      
                ShiftTrackerLockscreenPayWidgetsView(entry: entry)
                .widgetBackgroundModifier()
                  
      
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
        
        
        if let _ = entry.shiftStartDate {
            
            VStack(alignment: .leading, spacing: 3) {
                
                // detecting if on break seems pointless, removed for now
            /*    if entry.isOnBreak{
                    Text("On break")
                        .font(.system(size: 20, weight: .bold))
                } else {
                    */
                    Text("\(currencyFormatter.currencySymbol ?? "")\(entry.taxedPay, specifier: "%.2f")")
                    .fontWeight(.heavy)
                Divider().frame(maxWidth: 60)
               
                    Text("As at: ")
                        + Text((Date().formatted(date: .omitted, time: .shortened))).bold()
                    
                
           
                 
                    
               // }
                
                
            }.roundedFontDesign()
            
        } else {
            
            Text("No current shift").bold()
            
        }
        
        

        
        
    }
    
    
}

// the widget inline above the time

struct InlinePayWidgetView: View {
    var entry: LockscreenWidgetProvider.Entry
    var body: some View {
        
          if let _ = entry.shiftStartDate {
            
         /*   if entry.isOnBreak{
                Text("On Break")
                    .bold()
            } else {*/
                
                Text("$\(entry.taxedPay, specifier: "%.2f") at: ")
                + Text((Date().formatted(date: .omitted, time: .shortened)))
                
         //   }
            
        } else {
            
            Text("No current shift")
            
        }
        
        
    }
    
    
}

// the circular widget

struct CircularPayWidgetView: View {
    var entry: LockscreenWidgetProvider.Entry
    var body: some View {
        ZStack {
         
        if let _ = entry.shiftStartDate {
            
            /* if entry.isOnBreak{
             Text("\(Image(systemName: "pause.circle.fill"))")
             } else {
             */
            VStack(alignment: .center, spacing: 1.5) {
                Text("$\(entry.taxedPay, specifier: "%.2f")")
                    .fontWeight(.heavy)
                    .scaledToFit()
                    .allowsTightening(true)
                    .minimumScaleFactor(0.6)
                Divider().frame(maxWidth: 30)
                Text((Date().formatted(date: .omitted, time: .shortened)))
                    .font(.caption)
                    .bold()
            }
            
            // }
            
            
            
            
        } else {
            
            Image(systemName: "briefcase.circle")
                .font(.largeTitle)
        }
        
        
    }
        
    }
    
    
}
