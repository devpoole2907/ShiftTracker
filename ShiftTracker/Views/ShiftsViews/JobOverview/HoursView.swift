//
//  HoursView.swift
//  ShiftTracker
//
//  Created by James Poole on 8/04/23.
//

import SwiftUI
import CoreData
import CloudKit
import Charts

struct HoursView: View {
    @Environment(\.colorScheme) var colorScheme
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var shifts: FetchedResults<OldShift>
    @State private var selection = 0
    let options = ["W", "M", "6M"]
    var body: some View {
        
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8)
        NavigationStack{
            List{
                Picker(selection: $selection, label: Text("Duration")) {
                    ForEach(0..<2) { index in
                        Text(options[index])
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .pickerStyle(.segmented)
                .padding(.horizontal, 10)
                
                let lastWeekShifts = shifts.filter { shift in
                    let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                    return shift.shiftStartDate! > oneWeekAgo
                }
                
                let weekShifts = lastWeekShifts.map { shift in
                    return weekShift(shift: shift)
                }.reversed()
                
                VStack(alignment: .leading){
                    Chart{
                        ForEach(weekShifts) { weekShift in
                            BarMark(x: .value("Day", weekShift.dayOfWeek), y: .value("Hours", weekShift.hoursCount))
                                .foregroundStyle(Color.orange.gradient.opacity(0.8))
                            
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 5)
                    .frame(height: 300)
                    
                    
                }
                .listRowBackground(Color.clear)
                //.padding()
                Section(header: Text("Highlights").font(.title2).bold()){
                    VStack(alignment: .leading, spacing: 5){
                        Text("Hours")
                            .foregroundColor(.orange)
                            .font(.subheadline)
                            .bold()
                        Text("You're averaging 2 hours more per shift this week than last week.")
                            .foregroundColor(textColor)
                            .font(.subheadline)
                            .bold()
                    }
                    Section{
                        VStack{
                            HStack{
                                Text("8.5")
                                    .foregroundColor(textColor)
                                    .font(.title)
                                    .bold()
                                Text("hours / shift")
                                    .foregroundColor(subTextColor)
                                    .font(.subheadline)
                                    .bold()
                            }
                            Spacer()
                        }
                        .padding(.bottom, 50)
                        .padding(.top, 10)
                    }
                }
                
                
                
                
                
            }  .navigationTitle("Hours")
        }
    }
}

struct HoursView_Previews: PreviewProvider {
    static var previews: some View {
        HoursView()
    }
}
