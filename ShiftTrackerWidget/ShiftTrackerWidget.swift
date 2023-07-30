//
//  ShiftTrackerWidget.swift
//  ShiftTrackerWidget
//
//  Created by James Poole on 18/03/23.
//

import SwiftUI
import WidgetKit
import CoreData
import Charts

struct ShiftTrackerWidget: Widget {
    let kind: String = "ShiftTrackerWidget"
    
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShiftTrackerProvider()) { entry in
            ShiftTrackerWidgetView(entry: entry)
        }
        .configurationDisplayName("ShiftTracker Widget")
        .description("Track your current shift earnings.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ShiftTrackerProvider: TimelineProvider {
    private let shiftKeys = ShiftKeys()
    func placeholder(in context: Context) -> ShiftTrackerEntry {
        
        let allOldShifts = (try? getData())
        
        return ShiftTrackerEntry(date: Date(), lastPay: 0.0, totalPay: 0.0, taxedPay: 0.0, taxPercentage: 0.0, oldShifts: allOldShifts!, shiftEnded: true, isOnBreak: false, breakElapsed: 0.0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ShiftTrackerEntry) -> ()) {
        
        do {
            let allOldShifts = try getData()
            let entry = ShiftTrackerEntry(date: Date(), lastPay: 0.0, totalPay: 0.0, taxedPay: 0.0, taxPercentage: 0.0, oldShifts: allOldShifts, shiftEnded: false, isOnBreak: false, breakElapsed: 0.0)
            completion(entry)
        } catch{
            print(error)
        }
        
        
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        do{
            let allOldShifts = try getData()
            let currentDate = Date()
            let refreshDate = Calendar.current.date(byAdding: .second, value: 60, to: currentDate)!
            
            let sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
            let lastPay = sharedUserDefaults.double(forKey: shiftKeys.lastPayKey)
            let hourlyPay = sharedUserDefaults.double(forKey: shiftKeys.hourlyPayKey)
            let taxPercentage = sharedUserDefaults.double(forKey: shiftKeys.taxPercentageKey)
            let isShiftEnded = sharedUserDefaults.bool(forKey: shiftKeys.shiftEndedKey)
            let isShiftOnBreak = sharedUserDefaults.bool(forKey: shiftKeys.isOnBreakKey)
            let lastBreakElapsed = sharedUserDefaults.double(forKey: shiftKeys.lastBreakElapsedKey)
            
            let entry = ShiftTrackerEntry(date: currentDate, lastPay: lastPay, totalPay: calculateTotalPay(sharedUserDefaults: sharedUserDefaults, hourlyPay: hourlyPay), taxedPay: calculateTaxedPay(sharedUserDefaults: sharedUserDefaults, totalPay: calculateTotalPay(sharedUserDefaults: sharedUserDefaults, hourlyPay: hourlyPay)), taxPercentage: taxPercentage, oldShifts: allOldShifts, shiftEnded: isShiftEnded, isOnBreak: isShiftOnBreak, breakElapsed: lastBreakElapsed)
            
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
        catch{
            print(error)
        }
    }
    
    func calculateTotalPay(sharedUserDefaults: UserDefaults, hourlyPay: Double) -> Double {
        guard let shiftStartDate = sharedUserDefaults.object(forKey: shiftKeys.shiftStartDateKey) as? Date else { return 0 }
        let totalBreakTime = sharedUserDefaults.double(forKey: shiftKeys.lastBreakElapsedKey)
        
        let totalTimeWorked = Date().timeIntervalSince(shiftStartDate) - totalBreakTime
        let pay = (totalTimeWorked / 3600.0) * hourlyPay
        return pay
    }
    
    func calculateTaxedPay(sharedUserDefaults: UserDefaults, totalPay: Double) -> Double {
        guard let taxPercentage = sharedUserDefaults.object(forKey: shiftKeys.taxPercentageKey) as? Double else { return 0 }
        let afterTax = totalPay - (totalPay * Double(taxPercentage) / 100.0)
        return afterTax
    }
    
    private func getData() throws -> [OldShift] {
        let context = PersistenceController.shared.container.viewContext
        let request = OldShift.fetchRequest ()
        let result = try context.fetch(request)
        return result
    }
    
}

struct ShiftTrackerEntry: TimelineEntry {
    let date: Date
    let lastPay: Double
    let totalPay: Double
    let taxedPay: Double
    let taxPercentage: Double
    let oldShifts: [OldShift]
    let shiftEnded: Bool
    let isOnBreak: Bool
    let breakElapsed: TimeInterval
}

struct ShiftTrackerWidgetView: View {
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    var entry: ShiftTrackerProvider.Entry
    @Environment(\.widgetFamily)
    var family
    
    var body: some View {
        switch family {


        case.systemMedium:
            MediumWidgetView(entry: entry)
                .privacySensitive(false)
        default:
            ZStack{
                Color(red: 25/255, green: 25/255, blue: 25/255)
                    .ignoresSafeArea()
                    .scaledToFill()
                if entry.isOnBreak{
                    Text("On break")
                        .fontWeight(.heavy)
                        .font(.subheadline)
                }
                else if !entry.shiftEnded{
                    VStack(spacing: 10) { // Add spacing between the text views
                        Text("Taxed Pay")
                            .fontWeight(.heavy)
                            .font(.title3)
                        Text("\(currencyFormatter.currencySymbol ?? "")\(entry.taxedPay, specifier: "%.2f")")
                            .padding(.horizontal, 10)
                            .font(.system(size: 25))
                            .fontWeight(.black)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.green.opacity(0.3))
                        
                            .fixedSize()
                            .cornerRadius(20)
                        Text("Total Pay")
                            .fontWeight(.heavy)
                            .font(.subheadline)
                        Text("\(currencyFormatter.currencySymbol ?? "")\(entry.totalPay, specifier: "%.2f")")
                            .padding(.horizontal, 10)
                            .font(.system(size: 15))
                            .fontWeight(.black)
                            .frame(maxWidth: .infinity, minHeight: 30)
                            .background(Color.red.gradient.opacity(0.3))
                        
                            .fixedSize()
                            .cornerRadius(20)
                        
                    }
                }
                else {
                    Text("No active shift")
                        .fontWeight(.heavy)
                        .font(.subheadline)
                }
            }
            .foregroundColor(.white) // Set the text color to white
            .background(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)).ignoresSafeArea().scaledToFill() // Add a gradient background
            //.background(Color.red.ignoresSafeArea())
            .widgetURL(URL(string: "shifttracker://widget"))
        }
        
    }
}


struct MediumWidgetView: View {
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    var entry: ShiftTrackerProvider.Entry
    var body: some View {
        ZStack{
            Color(red: 25/255, green: 25/255, blue: 25/255)
                .ignoresSafeArea()
                .scaledToFill()
            
            HStack {
                Section{
                    VStack(alignment: .center, spacing: 5) { // Add spacing between the text views
                        if entry.isOnBreak{
                            Text("On break")
                                .fontWeight(.heavy)
                                .font(.subheadline)
                        }
                        else if !entry.shiftEnded{
                            Text("Taxed Pay")
                                .fontWeight(.heavy)
                                .font(.title3)
                            Text("\(currencyFormatter.currencySymbol ?? "")\(entry.taxedPay, specifier: "%.2f")")
                                .padding(.horizontal, 10)
                                .font(.system(size: 25))
                                .fontWeight(.black)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.green.opacity(0.3))
                            
                                .fixedSize()
                                .cornerRadius(20)
                            Text("Total Pay")
                                .fontWeight(.heavy)
                                .font(.subheadline)
                            Text("\(currencyFormatter.currencySymbol ?? "")\(entry.totalPay, specifier: "%.2f")")
                                .padding(.horizontal, 10)
                                .font(.system(size: 15))
                                .fontWeight(.black)
                                .frame(maxWidth: .infinity, minHeight: 30)
                                .background(Color.red.opacity(0.3))
                            
                                .fixedSize()
                                .cornerRadius(20)
                            
                            
                        }
                        else {
                            Text("No active shift")
                                .fontWeight(.heavy)
                                .font(.subheadline)
                        }
                        
                        //Spacer()
                    }
                }
                .padding(.leading, 10)
                Section{
                    VStack(spacing: 5){
                        
                        let lastWeekShifts = entry.oldShifts.filter { shift in
                            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                            return shift.shiftStartDate! > oneWeekAgo
                        }
                        
                        let weekShifts = lastWeekShifts.map { shift in
                            return weekShift(shift: shift)
                        }.reversed()
                        
                        Chart{
                            ForEach(weekShifts) { weekShift in
                                BarMark(x: .value("Day", weekShift.dayOfWeek), y: .value("Hours", weekShift.hoursCount))
                                    .foregroundStyle(Color.orange.gradient.opacity(0.9))
                                
                            }
                        }
                        .padding(20)
                        .frame(height: 180)
                        //Spacer()
                        .background(.black)
                    }
                }
            }
            
            
        }
        .foregroundColor(.white) // Set the text color to white
        // Add a gradient background
        //.background(Color.red.ignoresSafeArea())
        .widgetURL(URL(string: "shifttracker://widget"))
    }
}






struct ShiftTrackerWidget_Previews: PreviewProvider {
    static var previews: some View {
        let entry = ShiftTrackerEntry(date: Date(), lastPay: 25.0, totalPay: 100.0, taxedPay: 80.0, taxPercentage: 12.5, oldShifts: [], shiftEnded: false, isOnBreak: false, breakElapsed: 10.0)
        ShiftTrackerWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

struct weekShift: Identifiable {
    let id = UUID()
    let hoursCount: Double
    let dayOfWeek: String
    
    init(shift: OldShift) {
        let start = shift.shiftStartDate!
        let end = shift.shiftEndDate!
        self.hoursCount = end.timeIntervalSince(start) / 3600.0
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // set format to display abbreviated day of the week (e.g. "Mon")
        self.dayOfWeek = formatter.string(from: start)
    }
}

