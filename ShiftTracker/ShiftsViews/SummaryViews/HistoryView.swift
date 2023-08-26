//
//  HistoryView.swift
//  ShiftTracker
//
//  Created by James Poole on 26/08/23.
//

import SwiftUI
import Charts

@available(iOS 17.0, *)
struct HistoryView: View {
    
    @StateObject var shiftManager: ShiftDataManager = ShiftDataManager()
    @State private var scrollPosition = 0
    @State private var historyRange: HistoryRange = .week
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var shifts: FetchedResults<OldShift>
    
    func generateSampleShifts() -> [OldShift] {
        var shifts: [OldShift] = []
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
        
        for i in 0..<64 {
            let shift = OldShift(context: PersistenceController.preview.container.viewContext) // Assuming you have a PersistenceController.preview for preview purposes
            shift.shiftStartDate = Calendar.current.date(byAdding: .day, value: i, to: oneMonthAgo)
            shift.totalPay = Double(100 + (i * 5))
            shifts.append(shift)
        }
        return shifts
    }

    
    func getDateRange() -> ClosedRange<Date> {
        var now = Date()
        var components = DateComponents()
        var extraComponent = DateComponents()

        switch historyRange {
        case .week:
            components.day = -7
        case .month:
            components.month = -1
        case .year:
            extraComponent.month = 1
            now = Calendar.current.date(byAdding: extraComponent, to: now) ?? Date()
            components.month = -13
        }

        let startDate = Calendar.current.date(byAdding: components, to: now)!
        return startDate...now
    }
    
    var weekDomain: ClosedRange<Date> {
        let earliestShift = shifts.min(by: { $0.shiftStartDate ?? Date() < $1.shiftStartDate ?? Date() })?.shiftStartDate ?? Date()
        let latestShift = shifts.max(by: { $0.shiftStartDate ?? Date() < $1.shiftStartDate ?? Date() })?.shiftStartDate ?? Date()
        return earliestShift...latestShift
    }

    
    var body: some View {

        List {
            Section {
                Chart {
                    
                    ForEach(generateSampleShifts(), id: \.self) { shift in
                        
                        BarMark(x: .value("Day", shift.shiftStartDate ?? Date(), unit: .weekday),
                                y: .value("Earnings", shift.totalPay)
                                        )
                        .foregroundStyle(Color.green)
                        .cornerRadius(5)
                        
                    }
                    
                    
                }
                  //  .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(day: 0)))
                   // .chartScrollPosition(x: $scrollPosition)
                
                 //   .chartXScale(domain: getDateRange(), type: .linear)
                    .chartScrollableAxes(.horizontal)
                    .frame(height: 300)
                
                    .padding()
                    
                 
            }

        }
        .navigationTitle("Week") // display the currently visible date range in the chart
        
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker(selection: $historyRange, label: Text("Range")) {
                    
                    ForEach(HistoryRange.allCases, id: \.self) { range in
                        
                        Text(range.shortDescription)
                        
                    }
                    
                }.pickerStyle(.segmented)
            }
            
            ToolbarItem(placement: .topBarTrailing){
                
                Button("Cheese"){
                    
                }
                
            }
            
        }
    }
}

@available(iOS 17.0, *)
struct HistoryView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationStack {
            HistoryView()
            
        }
        
    }
    
    
}
