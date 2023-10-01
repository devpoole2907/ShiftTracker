//
//  iosSixteenChartView.swift
//  ShiftTracker
//
//  Created by James Poole on 30/09/23.
//

import SwiftUI
import Charts
import Haptics

struct iosSixteenChartView: View {
    
    @EnvironmentObject var historyModel: HistoryViewModel
    @EnvironmentObject var shiftManager: ShiftDataManager
    
    var dateRange: ClosedRange<Date>
    var shifts: [OldShift]
    
    @State private var isOverlayEnabled = true
    

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
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()

        switch historyModel.historyRange {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "dd/M"
        case .year:
            formatter.dateFormat = "MMMM"
        }

        return formatter
    }
    
 

    
    var body: some View{
        
        Chart {
            
            ForEach(shifts, id: \.self) { shift in
                
                let yValue = shiftManager.statsMode == .earnings ? shift.totalPay : shiftManager.statsMode == .hours ? (shift.duration / 3600) : (shift.breakDuration / 3600.0)

                    BarMark(x: .value("Day", shift.shiftStartDate ?? Date(), unit: chartUnit),
                            y: .value(shiftManager.statsMode.description, yValue), width: barWidth
                    )
                    .foregroundStyle(shiftManager.statsMode.gradient)
                    .cornerRadius(shiftManager.statsMode.cornerRadius)
                    
                if let chartSelection = historyModel.chartSelection {
                    
                    let aggregateValue = historyModel.computeAggregateValue(for: chartSelection, in: shifts, statsMode: shiftManager.statsMode)
                    let chartSelectionDateComponents = historyModel.chartSelectionComponent(date: chartSelection)
                    let shiftStartDateComponents = historyModel.chartSelectionComponent(date: shift.shiftStartDate)
                    
                    
                    
                    if chartSelectionDateComponents == shiftStartDateComponents {
                        
                        let ruleMark = RuleMark(x: .value("Day", shift.shiftStartDate ?? Date(), unit: chartUnit))
                    
                        let annotationValue = historyModel.formatAggregate(aggregateValue: aggregateValue, shiftManager: shiftManager)
                        
                        let annotationView = ChartAnnotationView(value: annotationValue, date: dateFormatter.string(from: shift.shiftStartDate ?? Date()))
                        
                        
                        
                        
                        ruleMark.opacity(0.5)
                            .annotation(alignment: .top){
                                
                                annotationView.background{
                                    RoundedRectangle(cornerRadius: 12).foregroundStyle(Color(.systemGray6)).padding(.top, 2)}
                                .onAppear {
                                    print("annotationValue is \(annotationValue)")
                                }
                            
                                
                            }
                           
                        
                        
                    }
                }
                    
                
                
                
                
                
            }
            
        }
            
            // ios 16 has to show the scale and be slightly broken because of the overlay
            
            .chartXScale(domain: dateRange, type: .linear)
            
            
            .customChartXSelectionModifier(selection: $historyModel.chartSelection.animation(.default))
            
            .chartXAxis {
                
                
                if historyModel.historyRange == .month {
                    
                
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        if let date = value.as(Date.self) {
                            let components = Calendar.current.dateComponents([.day], from: date)
                            if let day = components.day, (day - 1) % 7 == 0 {
                                AxisValueLabel(dateFormatter.string(from: date), centered: true, collisionResolution: .disabled)
                            }
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
            
            
            .padding(.vertical)
            
            .frame(minHeight: 200)
        
        // will leave this custom modifier here for if in future the issue is fixed.
        
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
            
            
        }
    
    
            
    
        
}

