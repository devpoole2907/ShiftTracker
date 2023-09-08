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
    
    @StateObject var historyModel = HistoryViewModel()
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var shifts: FetchedResults<OldShift>
    
    
    var chartUnit: Calendar.Component {
        
        switch historyModel.historyRange {
        case .week:
            return .weekday
        case .month:
            return .weekOfMonth
        case .year:
            return .month
        }
        
    }
    

    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()

        switch historyModel.historyRange {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "dd/M"
        case .year:
            formatter.dateFormat = "MM/yy" 
        }

        return formatter
    }

    
    
    var barWidth: MarkDimension {
        switch historyModel.historyRange {
        case .week:
            return 25
        case .month:
            return 15
        case .year:
            return 15
        }
    }
    

    
    @State private var isLongPressDetected: Bool = false


    @State private var isOverlayEnabled: Bool = true
    
    
    
    var body: some View {
        
        
        
        let groupedShifts = Dictionary(grouping: shifts.filter({ shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) })) { shift in
            historyModel.getGroupingKey(for: shift)
        }.sorted { $0.key < $1.key }
        
        
       ZStack(alignment: .bottomTrailing){
        ZStack(alignment: .bottomLeading){
            
            
            List(selection: $historyModel.selection) {
                
                Section {
                    
                    TabView(selection: $historyModel.selectedTab.animation(.default)) {
                        
                        ForEach(groupedShifts.indices, id: \.self) { index in
                            let startDate = groupedShifts[index].key
                            let dateRange = historyModel.getDateRange(startDate: startDate)
                            let totalEarnings = groupedShifts[index].value.reduce(0) { $0 + $1.totalPay }
                            let totalHours = groupedShifts[index].value.reduce(0) { $0 + ($1.duration / 3600.0) }
                            let totalBreaks = groupedShifts[index].value.reduce(0) { $0 + ($1.breakDuration / 3600.0) }
                            
                            VStack {
                                HStack{
                                    VStack(alignment: .leading){
                                        Text("Total")
                                            .font(.headline)
                                            .bold()
                                            .fontDesign(.rounded)
                                            .foregroundColor(.gray)
                                        
                                        Text(
                                            shiftManager.statsMode == .earnings ? "\(shiftManager.currencyFormatter.string(from: NSNumber(value: totalEarnings)) ?? "0")" :
                                                shiftManager.statsMode == .hours ? shiftManager.formatTime(timeInHours: totalHours) :
                                                shiftManager.formatTime(timeInHours: totalBreaks)
                                        )
                                        .font(.title2)
                                        .bold()
                                        
                                        
                                    }
                                    Spacer()
                                    
                                    HStack(spacing: 20) {
                                        
                                        Button(action: {
                                            historyModel.backButtonAction()
                                        }){
                                            Image(systemName: "chevron.left").bold()
                                          
                                                .font(.title2)
                                        }
                                        
                                        Button(action: {
                                            historyModel.forwardButtonAction(groupedShifts: groupedShifts)
                                        }){
                                            Image(systemName: "chevron.right").bold()
                                      
                                                .font(.title2)
                                        }
                                        
                                        
                                        
                                    }.padding(.horizontal)
                                    
                                }.padding(.top, 5)
                                    .opacity(historyModel.chartSelection == nil ? 1.0 : 0.0)
                                Chart {
                                    
                                    
                                    
                                    
                                    ForEach(groupedShifts[index].value, id: \.self) { shift in
                                        
                                        
                                        
                                        if let chartSelection = historyModel.chartSelection {
                                            
                                            let chartSelectionDateComponents = historyModel.chartSelectionComponent(date: chartSelection)
                                            let shiftStartDateComponents = historyModel.chartSelectionComponent(date: shift.shiftStartDate)
                                            
                                            
                                            
                                            if chartSelectionDateComponents == shiftStartDateComponents {
                                                
                                          
                                                
                                                if #available(iOS 17.0, *){
                                                    RuleMark(x: .value("Day", shift.shiftStartDate ?? Date(), unit: chartUnit))
                                                        .foregroundStyle(Color(.black))
                                                    
                                           
                                                        .annotation(alignment: .top, overflowResolution: .init(x: .fit, y: .disabled)){
                                                            
                                                            
                                                            ChartAnnotationView(value: shiftManager.statsMode == .earnings ? "$\(String(format: "%.2f", shift.totalPay))" : shiftManager.statsMode == .hours ? shiftManager.formatTime(timeInHours: (shift.duration / 3600.0)) : shiftManager.formatTime(timeInHours: (shift.breakDuration / 3600.0)), date: dateFormatter.string(from: shift.shiftStartDate ?? Date()))
                                                            
                                                            
                                                            
                                                            
                                                        }
                                                    
                                                } else {
                                                    RuleMark(x: .value("Day", shift.shiftStartDate ?? Date(), unit: chartUnit))
                                                        .foregroundStyle(Color(.black))
                                                        .annotation(alignment: .top){
                                                            
                                                            
                                                            ChartAnnotationView(value: shiftManager.statsMode == .earnings ? "$\(String(format: "%.2f", shift.totalPay))" : shiftManager.statsMode == .hours ? shiftManager.formatTime(timeInHours: (shift.duration / 3600.0)) : shiftManager.formatTime(timeInHours: (shift.breakDuration / 3600.0)), date: dateFormatter.string(from: shift.shiftStartDate ?? Date()))
                                                            
                                                            
                                                            
                                                            
                                                       }
                                                }
                                                
                                            }
                                        }
                                        
                                        
                                        BarMark(x: .value("Day", shift.shiftStartDate ?? Date(), unit: chartUnit),
                                                y: .value(shiftManager.statsMode.description, shiftManager.statsMode == .earnings ? shift.totalPay : shiftManager.statsMode == .hours ? (shift.duration / 3600) : (shift.breakDuration / 3600.0)
                                                          
                                                         ), width: barWidth
                                        )
                                        .foregroundStyle(shiftManager.statsMode.gradient)
                                        .cornerRadius(shiftManager.statsMode.cornerRadius)
                                        
                                        
                                    }
                                    
                                    
                                }
                                
                                
                                
                                .chartXScale(domain: dateRange, type: .linear)
                                
                                    .customChartXSelectionModifier(selection: $historyModel.chartSelection.animation(.default))
                                
                                    .chartXAxis {
                                        
                                        
                                        if historyModel.historyRange == .month {
                                            
                                            AxisMarks(values: .stride(by: .day, count: 6)) { value in
                                                if let date = value.as(Date.self) {
                                                    
                                                    AxisValueLabel(format: .dateTime.day(), centered: true, collisionResolution: .disabled)
                                                    
                                                    
                                                } else {
                                                    AxisValueLabel()
                                                }
                                                
                                            }
                                            
                                        } else {
                                            AxisMarks(values: .stride(by: historyModel.historyRange == .week ? .day : .month, count: 1)) { value in
                                                if let date = value.as(Date.self) {
                                                    
                                                    if historyModel.historyRange == .week {
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
                                
                                   
                                
                                    .conditionalChartOverlay(overlayEnabled: $isOverlayEnabled)  { proxy in
                                            GeometryReader { innerProxy in
                                                
                                                Rectangle()
                                                    .fill(.clear).contentShape(Rectangle())
                                                    .gesture(
                                                        DragGesture()
                                                            .onChanged{ value in
                                                                
                                                                
                                                                
                                                                let location = value.location
                                                                
                                                                if let date: Date = proxy.value(atX: location.x){
                                                                    let calendar = Calendar.current
                                                                    print("date is \(date)")
                                                                    
                                                                    historyModel.chartSelection = date
                                                                }
                                                                
                                                                
                                                            } .onEnded{ value in
                                                                
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                                        
                                                                        
                                                                        historyModel.chartSelection = nil
                                                                        
                                                                    }
                                                                }
                                                            }
                                                    )
                                                
                                            }
                                        
                                    }
                                
                                    .padding(.vertical)
                                
                                    .frame(minHeight: 200)
                                
                                
                            } .padding(.horizontal)
                                .tag(index)
                            
                     
                            
                        }
                        
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .haptics(onChangeOf: historyModel.selectedTab, type: .light)
                    
                    
                    
                }.frame(minHeight: 300)
                    .listRowInsets(.init(top: 20, leading: 0, bottom: 20, trailing: 0))
                    .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                       
                
                Section {
                    if historyModel.selectedTab >= 0 && historyModel.selectedTab < groupedShifts.count {
                        ForEach(groupedShifts[historyModel.selectedTab].value, id: \.objectID) { shift in
                            NavigationLink(value: shift) {
                                ShiftDetailRow(shift: shift)
                            }
                            
                            .swipeActions {
                                Button(role: .destructive) {
                                    shiftStore.deleteOldShift(shift, in: viewContext)
                                 
                                    
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            
                        }.transition(.slide)
                            .animation(.easeInOut, value: historyModel.selectedTab)
                    }
                }
                .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                
                
                
                
            }.scrollContentBackground(.hidden)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
            
            
     
            
            
            
            
            
            
            
            
            
            
                
            PageControlView(currentPage: $historyModel.selectedTab, numberOfPages: groupedShifts.count)
                    .frame(maxWidth: 175)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                
                    .padding()
                
            }
                
              
                
                
            VStack(alignment: .trailing){
                    
                    HStack(spacing: 10){
                        
                        EditButton()
                        
                        Divider().frame(height: 10)
                        
                        Button(action: {
                            CustomConfirmationAlert(action: deleteItems, cancelAction: nil, title: "Are you sure?").showAndStack()
                        }) {
                            Image(systemName: "trash")
                                .bold()
                                .foregroundStyle(historyModel.selection.isEmpty ? .gray.opacity(0.5) : .red.opacity(1.0))
                        }.disabled(historyModel.selection.isEmpty)
                        
                        
                        
                        
                        
                        
                    }.padding()
                        .glassModifier(cornerRadius: 20)
                    
                      //  .padding()
                    
                CustomSegmentedPicker(selection: $historyModel.historyRange, items: HistoryRange.allCases)

                       
                    
                        .glassModifier(cornerRadius: 20)
                    
                        .frame(width: 165)
                        .frame(maxHeight: 30)
                    
                      
                  
                    
                        .onChange(of: historyModel.historyRange) { _ in
                            withAnimation{
                                historyModel.selectedTab = groupedShifts.count - 1
                            }
                        }
                    
                    
                    Spacer().frame(height: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 75 : 55)
                }  .padding(.horizontal)
                
                
            
            
            
            
            
        }
        
        .onAppear {
            
            
            if shiftManager.showModePicker == true {
                historyModel.selectedTab = groupedShifts.count - 1
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
         
        
        
        
        .navigationTitle(historyModel.getCurrentDateRangeString(groupedShifts: groupedShifts))
        

        
        
    }
    
    
    private func deleteItems() {
        withAnimation {
            historyModel.selection.forEach { objectID in
                let itemToDelete = viewContext.object(with: objectID)
                viewContext.delete(itemToDelete)
            }
            
            do {
                try viewContext.save()
                historyModel.selection.removeAll()
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
