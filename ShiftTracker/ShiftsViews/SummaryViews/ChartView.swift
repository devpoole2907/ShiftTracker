//
//  StatsView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//

import SwiftUI
import Charts
import Haptics

@available(iOS 17.0, *)
struct ChartView: View {
    
    @EnvironmentObject var historyModel: HistoryViewModel
    @EnvironmentObject var shiftManager: ShiftDataManager
    
    var dateRange: ClosedRange<Date>
    var shifts: [OldShift]
    

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
    
    func formatAggregate(aggregateValue: Double) -> String {
        
        switch shiftManager.statsMode {
        case .earnings:
            return "$\(String(format: "%.2f", aggregateValue))"
        case .hours:
            return shiftManager.formatTime(timeInHours: aggregateValue / 3600.0)
        default:
            return shiftManager.formatTime(timeInHours: aggregateValue / 3600.0)
        }
        
        
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
                        
                            let annotationValue = formatAggregate(aggregateValue: aggregateValue)
                            
                            let annotationView = ChartAnnotationView(value: annotationValue, date: dateFormatter.string(from: shift.shiftStartDate ?? Date()))
                            
                            
                            
                            
                            ruleMark.opacity(0.5)
                                .annotation(alignment: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)){
                                    
                                    annotationView.background{
                                        RoundedRectangle(cornerRadius: 12).foregroundStyle(Color(.systemGray6)).padding(.top, 2)}
                                    
                                }
                            
                            
                            
                        }
                    }
                    
                    
                    
                
                
                
                
                
            }
            
        }
            
            
            

            // conditionally applies the scale
        .customChartXScale(useScale: historyModel.historyRange != .month, domain: dateRange)
            
            .customChartXSelectionModifier(selection: $historyModel.chartSelection.animation(.default))
            
            .chartXAxis {
                
                
                if historyModel.historyRange == .month {
                    
                
                    AxisMarks(values: .automatic(desiredCount: 5))
                                    
                    
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
            
            
        }
            
    
        
}

