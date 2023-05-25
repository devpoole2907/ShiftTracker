//
//  StatsView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//

import SwiftUI
import Charts
import Haptics

struct ChartView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    
    var graphedShifts: ReversedCollection<[singleShift]>?
    var graphedWeeks: ReversedCollection<[fullWeekShifts]>?
    var chartDataType: ChartDataType
    var chartDateType: ChartDateType
    var barColor: Color
    var yDomain: Int
    var chartTitle: String
    var statsMode: StatsMode
    
    @State private var selectedDay = ""
    @State private var selectedValue: Double = 0

    
    @State private var viewOpacity: Double = 0.0
    
    @State private var offsetX = 0.0
    @State private var offsetY = 150.0
    
    @State private var showSelectionBar = false
    
    var body: some View{
        let yAxisTitle = chartDataType.yAxisTitle
        
        let lineColor: Color = colorScheme == .dark ? Color(.systemGray6) : .black.opacity(0.1)
        
        
        VStack{
            HStack{
                VStack(alignment: .leading){
                if !showSelectionBar {
                    Text("Total")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.gray)
                    Text(chartTitle)
                        .font(.title2)
                        .bold()
                        }
                        else {
                        Text("\(selectedDay)")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.gray)
                            if statsMode == .earnings {
                                Text("$\(String(format: "%.2f", selectedValue))")
                                    .font(.title2)
                                    .bold()
                            } else {
                                Text("\(String(format: "%.2f", selectedValue))h")
                                    .font(.title2)
                                    .bold()
                            }
                        }
                }
                Spacer()
                
            }
            
            Chart{
                if let graphedShifts = graphedShifts {
                    ForEach(graphedShifts) { weekShift in
                        
                        let yValue: Double = {
                            switch chartDataType {
                            case .hoursCount:
                                return weekShift.hoursCount
                            case .totalPay:
                                return weekShift.totalPay
                            case .breakDuration:
                                return weekShift.breakDuration
                            }
                        }()
                        
                        let xValue: String = {
                            switch chartDateType {
                            case .day:
                                return weekShift.dayOfWeek
                            case .date:
                                return weekShift.date
                            }
                        }()
                        
                        if statsMode == .hours || statsMode == .breaks {
                            BarMark(x: .value("Day", xValue), y: .value(yAxisTitle, yValue))
                                .foregroundStyle(barColor.gradient)
                        }
                        else {
                            LineMark(x: .value("Day", xValue), y: .value(yAxisTitle, yValue))
                                .foregroundStyle(barColor.gradient)
                        }
                        /*  .annotation {
                         Text(String(format: "%.2f", yValue))
                         .font(.caption)
                         .bold()
                         } */
                        
                    }
                    
                }
                else if let graphedWeeks = graphedWeeks {
                    
                    ForEach(graphedWeeks) { weekShift in
                        
                        let yValue: Double = {
                            switch chartDataType {
                            case .hoursCount:
                                return weekShift.hoursCount
                            case .totalPay:
                                return weekShift.totalPay
                            case .breakDuration:
                                return weekShift.breakDuration
                            }
                        }()
                        
                        let xValue: String = {
                            switch chartDateType {
                            case .day:
                                return "\(weekShift.startDate)-\(weekShift.endDate)"
                            case .date:
                                return "\(weekShift.startDate)-\(weekShift.endDate)"
                            }
                        }()
                        
                        if statsMode == .hours || statsMode == .breaks {
                            BarMark(x: .value("Day", xValue), y: .value(yAxisTitle, yValue))
                                .foregroundStyle(barColor.gradient)
                        }
                        else {
                            LineMark(x: .value("Day", xValue), y: .value(yAxisTitle, yValue))
                                .foregroundStyle(barColor.gradient)
                        }
                        /*  .annotation {
                         Text(String(format: "%.2f", yValue))
                         .font(.caption)
                         .bold()
                         } */
                        
                    }
                    
                }
            }
        }
        
        .chartYScale(domain: 0...yDomain)
        .frame(height: 200)
        .padding(.bottom)
        .opacity(viewOpacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewOpacity = 1.0
            }
        }
        .onDisappear {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewOpacity = 0.0
            }
        }
        .chartOverlay { pr in
            GeometryReader { geoProxy in
                Rectangle().foregroundStyle(lineColor)
                    .frame(width: 2, height: geoProxy.size.height * 0.95)
                    .opacity(showSelectionBar ? 1.0 : 0.0)
                    .offset(x: offsetX)
                /*Rectangle()
                    .foregroundStyle(Color(.systemGray6))
                    .frame(width: 100, height: 50)
                    .cornerRadius(12)
                    .overlay {
                        VStack(spacing: 5) {
                                    Text("\(selectedDay)")
                               
                                .bold()
                                .font(.caption)
                            Divider()
                            Text("\(String(format: "%.2f", selectedValue))")
                                       
                                        .bold()
                                        .font(.caption)
                        }.padding()
                        
                        
                    }.shadow(radius: 3, x: 0, y: 1)
                    .opacity(showSelectionBar ? 1.0 : 0.0)
                    .offset(x: offsetX - 50, y: offsetY - 50) */
                Rectangle().fill(.clear).contentShape(Rectangle()).gesture(DragGesture().onChanged{ value in
                    if !showSelectionBar {
                        showSelectionBar = true
                    }
                    let origin = geoProxy[pr.plotAreaFrame].origin
                    let location = CGPoint(
                        x: value.location.x - origin.x,
                        y: value.location.y - origin.y
                    )
                    let plotAreaWidth = geoProxy[pr.plotAreaFrame].size.width
                        offsetX = max(min(location.x, plotAreaWidth), 0)
                    let plotAreaHeight = geoProxy[pr.plotAreaFrame].size.height
                        offsetY = max(min(location.y, plotAreaHeight), 50)
                    
                    let (day, _) = pr.value(at: location, as: (String, Int).self) ?? ("-", 0)
                    if let weekShift = graphedShifts?.first(where: { ws in
                            switch chartDateType {
                            case .day:
                                return ws.dayOfWeek.lowercased() == day.lowercased()
                            case .date:
                                return ws.date.lowercased() == day.lowercased()
                            }
                        }) {
                            let valueToDisplay: Double = {
                                switch chartDataType {
                                case .hoursCount:
                                    return weekShift.hoursCount
                                case .totalPay:
                                    return weekShift.totalPay
                                case .breakDuration:
                                    return weekShift.breakDuration
                                }
                            }()
                            selectedDay = day
                            selectedValue = valueToDisplay
                        } else {
                            selectedDay = "-"
                            selectedValue = 0
                        }
                    
                }
                .onEnded({ _ in
                    showSelectionBar = false
                }))
            }
            
                            
                        }.haptics(onChangeOf: selectedValue, type: .light)
        
        
      //  .padding(.horizontal, 10)
       // .padding(.top, 5)
        
        
        
    }
        
}

/*
struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView(chartDataType: <#ChartDataType#>, chartDateType: <#ChartDateType#>, barColor: <#Color#>, yDomain: <#Int#>, chartTitle: <#String#>)
    }
} */
