//
//  UpcomingShiftWidget.swift
//  UpcomingShiftWidget
//
//  Created by James Poole on 14/08/23.
//

import WidgetKit
import SwiftUI
import CoreData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: Date(), upcomingShift: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> ()) {
        
        let shift = try? fetchUpcoming()
        let entry = ScheduleEntry(date: Date(), upcomingShift: shift)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [ScheduleEntry] = []
        
        

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let shift = try? fetchUpcoming()
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = ScheduleEntry(date: entryDate, upcomingShift: shift)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    
    func fetchUpcoming() throws -> ScheduledShift? {
        let context = PersistenceController.shared.container.viewContext

        let request: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
        request.predicate = NSPredicate(format: "startDate > %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]

        let result = try context.fetch(request)

        return result.first
    }

    
    
}

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let upcomingShift: ScheduledShift?
}

struct UpcomingShiftWidgetEntryView : View {
    var entry: Provider.Entry

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }()
    
    var body: some View {
     /*   VStack {
            Text("Time:")
            
            
                Text(shift.startDate ?? Date(), style: .timer)
                Text(shift.startDate ?? Date(), style: .date)
            } */
        
        
        
    if let upcomingShift = entry.upcomingShift{
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
            Text("Upcoming Shift")
                .font(.title3)
                .bold()
                .padding(.bottom, -1)
            
            Text(upcomingShift.startDate ?? Date(), style: .timer)
                .bold()
                .foregroundStyle(.orange)
                .fontDesign(.rounded)
                .font(.footnote)
        }
            
            Divider().frame(maxWidth: 220)
            HStack{
                Image(systemName: upcomingShift.job?.icon ?? "")
                    .foregroundStyle(.white)
                    .font(.callout)
                    .padding(10)
                    .background {
                        
                        Circle()
                      
                        
                            .foregroundStyle(Color(red: Double(upcomingShift.job?.colorRed ?? 0), green: Double(upcomingShift.job?.colorGreen ?? 0), blue: Double(upcomingShift.job?.colorBlue ?? 0)).gradient)
                        
                        
                  
                        
                    }
                
                
                VStack(alignment: .leading, spacing: 5){
           
                        Text("\(upcomingShift.job?.name ?? "")")
                            .bold()
                       
                    
                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        Text(
                            Calendar.current.isDateInToday(upcomingShift.startDate ?? Date()) ?
                            "Today at " :
                                "\(upcomingShift.startDate ?? Date(), formatter: Self.dateFormatter) at "
                        )
                        .fontDesign(.rounded)
                        .foregroundColor(.gray)
                        .bold()
                        .font(.footnote)
                        
                        Text(upcomingShift.startDate ?? Date(), style: .time)
                            .foregroundColor(
                                Date() > upcomingShift.startDate ?? Date() ? .red :
                                    Calendar.current.date(byAdding: .hour, value: 1, to: Date())! > upcomingShift.startDate ?? Date() ? .orange :
                                        .gray
                            )
                            .fontDesign(.rounded)
                            .bold()
                            .font(.footnote)
                    }
                }
            }.padding(.vertical, 3)
            
        }
    } else {
        VStack(alignment: .leading) {
            
            Text("Upcoming Shift")
                .font(.title3)
                .bold()
                .padding(.bottom, -1)
            Divider().frame(maxWidth: 200)
            HStack{
                Image(systemName: "briefcase.fill")
                Text("No Upcoming Shifts")
                
            }.foregroundColor(.gray)
                .font(.footnote)
                .bold()
                .padding(.vertical, 2)
                .fontDesign(.rounded)
            
        }
    }
        
        
        
        
        
        
        
    }
}

struct UpcomingShiftWidget: Widget {
    let kind: String = "UpcomingShiftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
         /*   if #available(iOS 17.0, *) {
                UpcomingShiftWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else { */
                UpcomingShiftWidgetEntryView(entry: entry)
                    .padding()
                    .background()
           // }
        }
        .configurationDisplayName("Upcoming Shift")
        .description("Displays the next scheduled shift.")
        .supportedFamilies([.systemMedium])
    }
}

