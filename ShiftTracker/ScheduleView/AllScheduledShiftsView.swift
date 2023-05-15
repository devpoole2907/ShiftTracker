//
//  AllScheduledShiftsView.swift
//  ShiftTracker
//
//  Created by James Poole on 16/05/23.
//

import SwiftUI
import CoreData

struct AllScheduledShiftsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ScheduledShift.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ScheduledShift.startDate, ascending: false)]
    ) private var allShifts: FetchedResults<ScheduledShift>

    var groupedShifts: [Date: [ScheduledShift]] {
        Dictionary(grouping: allShifts, by: { $0.startDate?.midnight() ?? Date() })
    }

    @Environment(\.colorScheme) var colorScheme
    
    private var timeFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter
        }
    
    func formattedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d MMM"
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        
        if !groupedShifts.isEmpty {
        List {
            ForEach(groupedShifts.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(formattedDate(date)).textCase(.uppercase).bold().foregroundColor(textColor)) {
                    ForEach(groupedShifts[date] ?? [], id: \.self) { shift in
                        HStack {
                            // Vertical line
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)))
                                .frame(width: 4)
                            
                            VStack(alignment: .leading) {
                                Text(shift.job?.name ?? "")
                                    .bold()
                                Text(shift.job?.title ?? "")
                                    .foregroundColor(.gray)
                                    .bold()
                            }
                            Spacer()
                            
                            VStack(alignment: .trailing){
                                if let startDate = shift.startDate {
                                    Text(timeFormatter.string(from: startDate))
                                        .font(.subheadline)
                                        .bold()
                                }
                                if let endDate = shift.endDate {
                                    Text(timeFormatter.string(from: endDate))
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                viewContext.delete(shift)
                                try? viewContext.save()
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }.listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        } else {
            Text("You don't have any shifts scheduled.")
                .bold()
        }
    }
}

extension Date {
    func midnight() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: components) ?? self
    }
}
