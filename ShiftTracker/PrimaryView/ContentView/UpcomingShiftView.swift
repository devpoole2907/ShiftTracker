//
//  UpcomingShiftView.swift
//  ShiftTracker
//
//  Created by James Poole on 18/05/23.
//

import SwiftUI
import CoreData

struct UpcomingShiftView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: ScheduledShift.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ScheduledShift.startDate, ascending: true)],
        predicate: NSPredicate(format: "startDate > %@", Date() as NSDate),
        animation: .default)
    private var scheduledShifts: FetchedResults<ScheduledShift>
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM 'at' h:mm a"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading) {
            
                Text("Upcoming Shift")
                    .font(.title3)
                    .bold()
            Divider().frame(maxWidth: 200)
            if let upcomingShift = scheduledShifts.first {
                HStack{
                    Image(systemName: upcomingShift.job?.icon ?? "briefcase.circle")
                        .foregroundColor(Color(red: Double(upcomingShift.job?.colorRed ?? 0), green: Double(upcomingShift.job?.colorGreen ?? 0), blue: Double(upcomingShift.job?.colorBlue ?? 0)))
                    VStack(alignment: .leading, spacing: 5){
                        Text("\(upcomingShift.job?.name ?? "Unknown")")
                            .bold()
                        Text("\(upcomingShift.startDate ?? Date(),formatter: Self.dateFormatter)")
                            .foregroundColor(.gray)
                            .bold()
                            .font(.footnote)
                    }
                }.padding(.vertical, 5)
            } else {
                HStack{
                    Image(systemName: "briefcase.circle")
                    Text("No Upcoming Shifts")
                        
                }.foregroundColor(.gray)
                    .font(.footnote)
                    .bold()
                    .padding(.vertical, 5)
            }
        }
    }
}

struct Previews_UpcomingShiftView_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingShiftView()
    }
}
