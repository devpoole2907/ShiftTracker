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
    var shifts: [DayOrMonthAggregate]
    
  //  var index: Int
    

    var chartUnit: Calendar.Component {
        
        switch historyModel.historyRange {
        case .week, .month:
            return .weekday
        case .year:
            return .month
        }
        
    }
    
    var barWidth: MarkDimension {
        switch historyModel.historyRange {
        case .week:
            return 25
        case .month:
            return 8
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
        
        Chart(shifts) { bar in
                
                let yValue = shiftManager.statsMode == .earnings ? bar.totalEarnings : shiftManager.statsMode == .hours ? bar.totalHours : bar.totalBreaks
                
                
                
                BarMark(x: .value("Day", bar.date, unit: chartUnit),
                            y: .value(shiftManager.statsMode.description, yValue), width: barWidth
                    )
                
                    
                
                    .foregroundStyle(shiftManager.statsMode.gradient)
                    .cornerRadius(shiftManager.statsMode.cornerRadius)
                
                if let chartSelection = historyModel.chartSelection {
                    
                    
                    let chartSelectionDateComponents = historyModel.chartSelectionComponent(date: chartSelection)
                    let shiftStartDateComponents = historyModel.chartSelectionComponent(date: bar.date)
                    
                    
                    
                    if chartSelectionDateComponents == shiftStartDateComponents {
                        
                        let ruleMark = RuleMark(x: .value("Day", bar.date, unit: chartUnit))
                        
                       
                        
                        let annotationValue = shiftManager.statsMode == .earnings ? bar.formattedEarnings : shiftManager.statsMode == .hours ? bar.formattedHours : bar.formattedBreaks
                        
                        let annotationView = ChartAnnotationView(value: annotationValue, date: bar.formattedDate)
                        
                        
                        
                        ruleMark.opacity(0.5)
                            .annotation(alignment: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)){
                                
                                annotationView.background{
                                    RoundedRectangle(cornerRadius: 12).foregroundStyle(Color(.systemGray6)).padding(.top, 2)}
                                
                                
                                
                            }
                    }
                }
                
            
            
        }
            
            
            

            // conditionally applies the scale
      //  .customChartXScale(useScale: true, domain: dateRange)
        
        .chartXScale(domain: dateRange, type: .linear)
        
        
            
            .customChartXSelectionModifier(selection: $historyModel.chartSelection.animation(.default))
            
           .chartXAxis {
                
                
                if historyModel.historyRange == .month {
                    
                    AxisMarks(preset: .automatic)

                                    
                    
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

