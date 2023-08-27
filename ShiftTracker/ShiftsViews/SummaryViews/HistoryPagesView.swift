//
//  HistoryPagesView.swift
//  ShiftTracker
//
//  Created by James Poole on 26/08/23.
//

import SwiftUI
import Charts
import CoreData
import Haptics


struct HistoryPagesView: View {
    
    @Binding var navPath: NavigationPath
    
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var shiftStore: ShiftStore
    
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    
    
    @State private var historyRange: HistoryRange = .week
    @State private var selectedTab: Int = 0 // To keep track of the selected tab
    let calendar = Calendar.current
    
    @State private var selection = Set<NSManagedObjectID>()
    
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
    
    func getCurrentDateRangeString(historyRange: HistoryRange, for index: Int, groupedShifts: [(key: Date, value: [OldShift])]) -> String {
        
        let dateFormatter = DateFormatter()
        
        switch historyRange {
        case .week:
            guard groupedShifts.count > 0 else { return "" }
            guard index < groupedShifts.count else { return "" }
            let startDate = groupedShifts[index].key
            let endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!
            dateFormatter.dateFormat = "MMM d"
            let startDateString = dateFormatter.string(from: startDate)
            dateFormatter.dateFormat = "d"
            let endDateString = dateFormatter.string(from: endDate)
            return "\(startDateString) - \(endDateString)"
            
        case .month:
            guard index < groupedShifts.count else { return "" }
            let startDate = groupedShifts[index].key
            dateFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
            return dateFormatter.string(from: startDate)
            
        case .year:
            guard index < groupedShifts.count else { return "" }
            let startDate = groupedShifts[index].key
            dateFormatter.setLocalizedDateFormatFromTemplate("yyyy")
            return dateFormatter.string(from: startDate)
        }
    }

    
    func getDateRange(startDate: Date) -> ClosedRange<Date> {
        
        var endDate = Date()
        
        switch historyRange {
            
        case .week:
            endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        case .month:
            endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
        case .year:
            endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
        }
        
        
        
        return startDate...endDate
    }
    
    var chartUnit: Calendar.Component {
        
        switch historyRange {
        case .week:
            return .weekday
        case .month:
            return .weekOfMonth
        case .year:
            return .month
        }
        
    }
    
    func getGroupingKey(for shift: OldShift) -> Date {
        let components: Set<Calendar.Component>
        switch historyRange {
        case .week:
            components = [.yearForWeekOfYear, .weekOfYear]
        case .month:
            components = [.year, .month]
        case .year:
            components = [.year]
        }
        return calendar.startOfDay(for: calendar.date(from: calendar.dateComponents(components, from: shift.shiftStartDate!))!)
    }



    
    
    var body: some View {

        
        
        let groupedShifts = Dictionary(grouping: shifts.filter({ shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) })) { shift in
            getGroupingKey(for: shift)
        }.sorted { $0.key < $1.key }

        
        ZStack(alignment: .bottomLeading){
        ScrollView {
            
            VStack {
                
                
                
                
                ZStack(alignment: .bottomTrailing){
                TabView(selection: $selectedTab) {
                    
                    ForEach(groupedShifts.indices, id: \.self) { index in
                        VStack{
                            
                            List(selection: $selection) {
                                let startDate = groupedShifts[index].key
                                let dateRange = getDateRange(startDate: startDate)
                                
                                VStack {
                                    HStack{
                                        VStack(alignment: .leading){
                                            Text("Total")
                                                .font(.headline)
                                                .bold()
                                                .fontDesign(.rounded)
                                                .foregroundColor(.gray)
                                            
                                            Text(
                                                shiftManager.statsMode == .earnings ? "\(shiftManager.currencyFormatter.string(from: NSNumber(value: 22)) ?? "0")" :
                                                    shiftManager.statsMode == .hours ? shiftManager.formatTime(timeInHours: 12) :
                                                    shiftManager.formatTime(timeInHours: 1)
                                            )
                                            .font(.title2)
                                            .bold()
                                            
                                            
                                        }
                                        Spacer()
                                    }.padding(.top, 5)
                                    // .padding(.leading)
                                    
                                    Chart {
                                        
                                        ForEach(groupedShifts[index].value, id: \.self) { shift in
                                            
                                            BarMark(x: .value("Day", shift.shiftStartDate ?? Date(), unit: chartUnit),
                                                    y: .value(shiftManager.statsMode.description, shiftManager.statsMode == .earnings ? shift.totalPay : shiftManager.statsMode == .hours ? (shift.duration / 3600) : (shift.breakDuration / 3600.0)
                                                              
                                                             )
                                            )
                                            .foregroundStyle(shiftManager.statsMode.gradient)
                                            .cornerRadius(shiftManager.statsMode.cornerRadius)
                                            
                                        }
                                        
                                        
                                    } .chartXScale(domain: dateRange, type: .linear)
                                    
                                        .chartXAxis {
                                            
                                            
                                            if historyRange == .month {
                                                
                                                AxisMarks { value in
                                                    
                                                    
                                                    
                                                    
                                                    if value.as(Date.self) != nil {
                                                        AxisValueLabel(format: .dateTime.day(), centered: true, collisionResolution: .disabled)
                                                    }
                                                    
                                                    
                                                }
                                                
                                            } else {
                                                AxisMarks(values: .stride(by: historyRange == .week ? .day : .month, count: 1)) { value in
                                                    if let date = value.as(Date.self) {
                                                        
                                                        if historyRange == .week {
                                                            AxisValueLabel(shiftManager.dateFormatter.string(from: date), centered: true, collisionResolution: .disabled)
                                                            
                                                        } else {
                                                            AxisValueLabel(format: .dateTime.month(), centered: true, collisionResolution: .disabled)
                                                        }
                                                        
                                                        
                                                    } else {
                                                        AxisValueLabel()
                                                    }
                                                    
                                                }
                                            }
                                        }
                                    
                                        .padding(.vertical)
                                    
                                        .frame(minHeight: 200)
                                    
                           
                                } .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                                
                                
                                Section {
                                    ForEach(groupedShifts[index].value, id: \.objectID) { shift in
                                        NavigationLink(value: shift) {
                                            ShiftDetailRow(shift: shift)
                                            
                                        }
                                    }
                                    
                                    
                                    
                                } .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                                
                                Spacer(minLength: 225).listRowBackground(Color.clear)
                                
                            }.tag(index)
                            
                                .scrollContentBackground(.hidden)
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                            
                            
                        }
                    }
                    
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .haptics(onChangeOf: selectedTab, type: .light)
                
                 //   if #available(iOS 17.0, *){
                        
                        VStack{
                        
                        HStack(spacing: 10){
                            
                            EditButton()
                            
                            Divider().frame(height: 10)
                            
                            Button(action: {
                                CustomConfirmationAlert(action: deleteItems, cancelAction: nil, title: "Are you sure?").showAndStack()
                            }) {
                                Image(systemName: "trash")
                                    .bold()
                                    .foregroundStyle(selection.isEmpty ? .gray.opacity(0.5) : .red.opacity(1.0))
                            }.disabled(selection.isEmpty)
                            
                            
                            
                            
                            
                            
                        }.padding()
                                .glassModifier(cornerRadius: 20)
                        
                            .padding()
                           // .shadow(radius: 1)
                        
                            Spacer().frame(height: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 200 : 270)
                    }
                        
                        
                    //}
                
            }
                
            }.frame(height: UIScreen.main.bounds.height)
            
        }//.background(Color(.secondarySystemGroupedBackground))
        
            PageControlView(currentPage: $selectedTab, numberOfPages: groupedShifts.count)
                .frame(maxWidth: 175)
            
                .padding()
              
                           // .frame(maxWidth: 0, maxHeight: 0)
                           // .padding(22)
            
           
    }
        
        .onAppear {
            
        
            if shiftManager.showModePicker == true {
                selectedTab = groupedShifts.count - 1
            }
            
            withAnimation {
                shiftManager.showModePicker = true
            }
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                if groupedShifts.count < 1 {
                    dismiss()
                }
            }
        
            
        }
      //  .padding(.top, -10)
        
        
        
        
        .navigationTitle(getCurrentDateRangeString(historyRange: historyRange, for: selectedTab, groupedShifts: groupedShifts))

        
        .toolbar {
            
            ToolbarItem(placement: .principal) {
                Picker(selection: $historyRange, label: Text("Range")) {
                    
                    ForEach(HistoryRange.allCases, id: \.self) { range in
                        
                        Text(range.shortDescription)
                        
                    }
                    
                }.pickerStyle(.segmented)
                    .frame(maxWidth: 170)
                
                
                    .onChange(of: historyRange) { _ in
                        withAnimation{
                            selectedTab = groupedShifts.count - 1
                        }
                    }
                
            }
            
        
            
        }
        
        
    }
    
    
    private func deleteItems() {
        withAnimation {
            selection.forEach { objectID in
                let itemToDelete = viewContext.object(with: objectID)
                viewContext.delete(itemToDelete)
            }
            
            do {
                try viewContext.save()
                selection.removeAll()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    
}


struct HistoryPagesView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        HistoryPagesView(navPath: .constant(NavigationPath()))
        
        
        
    }
    
    
}
