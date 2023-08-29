//
//  ChartSquare.swift
//  ShiftTracker
//
//  Created by James Poole on 2/07/23.
//

import SwiftUI
import Charts
import CoreData

struct ChartSquare: View {
    
    @EnvironmentObject var shiftManager: ShiftDataManager
    
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    
    @State private var selectedDateRange: DateRange = .week
    
    @Binding var isChartViewPrimary: Bool
    
    @State private var selectedDay = ""
    @State private var selectedValue: Double = 0
    
    @State private var viewOpacity: Double = 0.0
    
    @State private var offsetX = 0.0
    @State private var offsetY = 150.0
    
    @State private var isPickerEnabled: Bool = false
    
    @State private var showSelectionBar: Bool = false
    
    @State private var currentActiveShift: singleShift?
    @State private var plotWidth: CGFloat = 0
    
    @State private var timesSeen = 0

    
    @Environment(\.colorScheme) var colorScheme
    
    func getTotalPayBasedOnDateRange() -> Double {
        switch shiftManager.dateRange {
        case .week:
            return shiftManager.weeklyTotalPay
        case .month:
            return shiftManager.getTotalPay(from: shiftManager.monthlyShifts)
        case .year:
            return shiftManager.getTotalPay(from: shiftManager.yearlyShifts)
        }
    }

    func getTotalHoursBasedOnDateRange() -> Double {
        switch shiftManager.dateRange {
        case .week:
            return shiftManager.weeklyTotalHours
        case .month:
            return shiftManager.getTotalHours(from: shiftManager.monthlyShifts)
        case .year:
            return shiftManager.getTotalHours(from: shiftManager.yearlyShifts)
        }
    }

    func getTotalBreaksHoursBasedOnDateRange() -> Double {
        switch shiftManager.dateRange {
        case .week:
            return shiftManager.weeklyTotalBreaksHours
        case .month:
            return shiftManager.getTotalBreaksHours(from: shiftManager.monthlyShifts)
        case .year:
            return shiftManager.getTotalBreaksHours(from: shiftManager.yearlyShifts)
        }
    }

    
    var body: some View {
                        
        
        let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)
        let headerColor: Color = colorScheme == .dark ? .white : .black
        
        
        let barColor: LinearGradient = {
                    switch shiftManager.statsMode {
                    case .earnings:
                        return LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 198 / 255, green: 253 / 255, blue: 80 / 255),
                                Color(red: 112 / 255, green: 218 / 255, blue: 65 / 255)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom)
                    case .hours:
                        return LinearGradient(
                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                            startPoint: .top,
                            endPoint: .bottom)
                    case .breaks:
                        return LinearGradient(
                            gradient: Gradient(colors: [Color.indigo, Color.purple]),
                            startPoint: .top,
                            endPoint: .bottom)
                    }
                }()
        
        
        HStack{
            VStack(alignment: .leading) {
                HStack(spacing: 5){
                    
                    HStack(spacing: 0){
                        NavigationLink(value: 2) {
                            Group {
                                Text("Activity")
                                    .font(.callout)
                                    .bold()
                                    .foregroundStyle(headerColor)
                                    .padding(.leading)
                                   
                                
                            }
                        }
                       // Spacer(minLength: 55)
                    }
                 /*   .onTapGesture {
                        withAnimation{
                            isChartViewPrimary.toggle()
                        }
                    }
                    */
                    Spacer()
                
                                   
                }

                if isChartViewPrimary {
                    HStack{
                        VStack(alignment: .leading){
                            Text("Total")
                                .font(.headline)
                                .bold()
                                .fontDesign(.rounded)
                                .foregroundColor(.gray)
                            
                            Text(
                                shiftManager.statsMode == .earnings ? "\(shiftManager.currencyFormatter.string(from: NSNumber(value: getTotalPayBasedOnDateRange())) ?? "0")" :
                                shiftManager.statsMode == .hours ? shiftManager.formatTime(timeInHours: getTotalHoursBasedOnDateRange()) :
                                shiftManager.formatTime(timeInHours: getTotalBreaksHoursBasedOnDateRange())
                            )
                            .font(.title2)
                            .bold()

                            .font(.title2)
                            .bold()
                        }
                        Spacer()
                    }.padding(.top, 5)
                     .padding(.leading)
                     .opacity(showSelectionBar ? 0.0 : 1.0)
                }
                
                
                Chart {
                    
                            
                            
                            
                    switch shiftManager.dateRange {
                        
                    case .week:
                        
                        ForEach(shiftManager.recentShifts) { shift in
                            
                            if let currentActiveShift, currentActiveShift.id == shift.id{
                       
                                RuleMark(x: .value("Day", currentActiveShift.shiftStartDate, unit: .weekday))
                                    .foregroundStyle(Color(.systemGray6))
                                    .annotation(position: .top){
                                        if shiftManager.statsMode == .earnings {
                                            
                                            ChartAnnotation(value: "$\(String(format: "%.2f", currentActiveShift.totalPay))", date: currentActiveShift.date)
                                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                        } else if shiftManager.statsMode == .hours {
                                            ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.hoursCount))h", date: currentActiveShift.date)
                                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                        } else {
                                            ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.breakDuration))h", date: currentActiveShift.date)
                                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                        }
                                        
                                    }
                                
                            }
                            
                            
                            
                            BarMark(x: .value("Day", shift.shiftStartDate, unit: .weekday),
                                                    y: .value(shiftManager.statsMode == .earnings ? "Earnings" :
                                                              shiftManager.statsMode == .hours ? "Hours" : "Breaks",
                                                              shift.animate
                                                              ? (shiftManager.statsMode == .earnings
                                                                 ? shift.totalPay
                                                                 : shiftManager.statsMode == .hours
                                                                 ? shift.hoursCount
                                                                 : shift.breakDuration)
                                                              : 0
                                                            )
                                            )
                            .foregroundStyle(barColor)
                            .cornerRadius(shiftManager.statsMode == .earnings ? 10 : 5, style: .continuous)
                            
                            
                            
                        }
                    case .month:
                        
                        ForEach(shiftManager.monthlyShifts) { shift in
                            
                            if let currentActiveShift, currentActiveShift.id == shift.id{
                       
                                RuleMark(x: .value("Day", currentActiveShift.shiftStartDate, unit: .day))
                                    .foregroundStyle(Color(.systemGray6))
                                    .annotation(position: .top){
                                        if shiftManager.statsMode == .earnings {
                                            
                                            ChartAnnotation(value: "$\(String(format: "%.2f", currentActiveShift.totalPay))", date: currentActiveShift.date)
                                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                        } else if shiftManager.statsMode == .hours {
                                            ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.hoursCount))h", date: currentActiveShift.date)
                                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                        } else {
                                            ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.breakDuration))h", date: currentActiveShift.date)
                                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                        }
                                        
                                    }
                                
                            }
                            
                            
                            
                            BarMark(x: .value("Day", shift.shiftStartDate, unit: .day),
                                    y: .value(shiftManager.statsMode == .earnings ? "Earnings" :
                                              shiftManager.statsMode == .hours ? "Hours" : "Breaks",
                                              shift.animate
                                              ? (shiftManager.statsMode == .earnings
                                                 ? shift.totalPay
                                                 : shiftManager.statsMode == .hours
                                                 ? shift.hoursCount
                                                 : shift.breakDuration)
                                              : 0
                                            )
                            )
                            .foregroundStyle(barColor)
                            .cornerRadius(shiftManager.statsMode == .earnings ? 10 : 5, style: .continuous)
                            
                            
                        }
                        
                
                        
                    case .year:
                        
                        ForEach(shiftManager.yearlyShifts) { shift in
                        if let currentActiveShift, currentActiveShift.id == shift.id{
                 
                            RuleMark(x: .value("Day", currentActiveShift.shiftStartDate, unit: .month))
                                .foregroundStyle(Color(.systemGray6))
                                .annotation(position: .top){
                                    if shiftManager.statsMode == .earnings {
                                        
                                        ChartAnnotation(value: "$\(String(format: "%.2f", currentActiveShift.totalPay))", date: currentActiveShift.date)
                                            .opacity(showSelectionBar ? 1.0 : 0.0)
                                    } else if shiftManager.statsMode == .hours {
                                        ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.hoursCount))h", date: currentActiveShift.date)
                                            .opacity(showSelectionBar ? 1.0 : 0.0)
                                    } else {
                                        ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.breakDuration))h", date: currentActiveShift.date)
                                            .opacity(showSelectionBar ? 1.0 : 0.0)
                                    }
                                    
                                }
                            
                        }
                        
                        
                        
                        BarMark(x: .value("Day", shift.shiftStartDate, unit: .month),
                                y: .value(shiftManager.statsMode == .earnings ? "Earnings" :
                                          shiftManager.statsMode == .hours ? "Hours" : "Breaks",
                                          shift.animate
                                          ? (shiftManager.statsMode == .earnings
                                             ? shift.totalPay
                                             : shiftManager.statsMode == .hours
                                             ? shift.hoursCount
                                             : shift.breakDuration)
                                          : 0
                                        )
                        )
                        .foregroundStyle(barColor)
                        .cornerRadius(shiftManager.statsMode == .earnings ? 10 : 5, style: .continuous)
                        
                    }
                            }
                        
                        
                        
                    
                    
                    
                }
                .onAppear {
                    
                
                        
                        //  animateGraph()
                        
                    
                }
                
                .onReceive(shiftManager.$shiftAdded) { _ in
                    animateGraph()
                    print("on recieve in chart called")
                        }
                
                .onReceive(shiftManager.$statsMode) { _ in
                    
                   // animateGraph()
                        }
                .onReceive(shiftManager.shiftDataLoaded) { _ in
                    animateGraph()
                    print("shift data loaded called")
                }



                .chartXScale(domain: shiftManager.getDateRange(), type: .linear)
                .chartXAxis(isChartViewPrimary ? .visible : .hidden)
                    .chartYAxis(isChartViewPrimary ? .visible : .hidden)
                    .chartXAxis{
                        if shiftManager.dateRange == .year {
                            AxisMarks(values: .stride(by: .month, count: 1)) { value in
                                    if let date = value.as(Date.self) {
                                        AxisValueLabel(format: .dateTime.month(), centered: true, collisionResolution: .disabled)
                                    }
                                }
                        } else if shiftManager.dateRange == .month {
                            
                           AxisMarks { value in
                                
                               
                                   
                                   
                                   if let date = value.as(Date.self) {
                                       AxisValueLabel(format: .dateTime.day(), centered: true, collisionResolution: .disabled)
                                   }
 
                                
                            }
      
                        } else {
                            
                            AxisMarks(values: .stride(by: .day, count: 1)) { value in
                            if let date = value.as(Date.self) {
                                
                                AxisValueLabel(shiftManager.dateFormatter.string(from: date), centered: true, collisionResolution: .disabled)
                                
                             
                            } else {
                                AxisValueLabel()
                            }
                            
                        }
                    }
                    }
                    .padding(.top, 5)
                    .padding(.horizontal)
                
                    .chartOverlay(content: { proxy in
                        GeometryReader { innerProxy in
                            if isChartViewPrimary {
                            Rectangle()
                                .fill(.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged{ value in
                                            
                                            if !showSelectionBar {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    showSelectionBar = true
                                                }
                                            }
                                            
                                            let location = value.location
                                            
                                            if let date: Date = proxy.value(atX: location.x){
                                                let calendar = Calendar.current
                                                print("date is \(date)")
                                                
                                                
                                                switch shiftManager.dateRange {
                                                case .week:
                                                    if let currentMark = shiftManager.recentShifts.first(where: { mark in
                                                        
                                                        print("check check")
                                                        
                                                        return compareDates(mark.shiftStartDate, date)
                                                        
                                                        
                                                        
                                                    }) {
                                                        print("check check check")
                                                        self.currentActiveShift = currentMark
                                                        self.plotWidth = proxy.plotAreaSize.width
                                                    }
                                                case .month:
                                                    if let currentMark = shiftManager.monthlyShifts.first(where: { mark in
                                                        
                                                        print("check check")
                                                        
                                                        return compareDates(mark.shiftStartDate, date)
                                                        
                                                        
                                                        
                                                    }) {
                                                        print("check check check")
                                                        self.currentActiveShift = currentMark
                                                        self.plotWidth = proxy.plotAreaSize.width
                                                    }
                                            
                                                case .year:
                                                    if let currentMark = shiftManager.yearlyShifts.first(where: { mark in
                                                        
                                                        print("check check")
                                                        
                                                        return compareDates(mark.shiftStartDate, date)
                                                        
                                                        
                                                        
                                                    }) {
                                                        print("check check check")
                                                        self.currentActiveShift = currentMark
                                                        self.plotWidth = proxy.plotAreaSize.width
                                                    }
                                                }
                                                
                                                
                                                
                                                
                                                
                                                
                                                
                                                
                                                
                                            }
                                            
                                            
                                        } .onEnded{ value in
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    showSelectionBar = false
                                                    
                                                    self.currentActiveShift = nil
                                                    
                                                }
                                            }
                                        }
                                )
                        }
                        }
                    })
                
              
            }
        }
            .padding(.vertical, 8)
            .glassModifier(cornerRadius: 12, applyPadding: false)
          
    }
    
    func animateGraph(){
        
      
    
            for(index,_) in shiftManager.recentShifts.enumerated(){
                
               // DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05){
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)){
                        shiftManager.recentShifts[index].animate = true
                        
                    }
                    
               // }

            }
            
    
            

            
   
            
            
            
        
        

    }
    
    func compareDates(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.year, .month, .day], from: date1)
        let components2 = calendar.dateComponents([.year, .month, .day], from: date2)
        return components1 == components2
    }

    
}


struct ChartAnnotation: View {
    
     var value: String
     var date: String
    
    var body: some View{
        HStack{
        VStack(alignment: .leading){
            
            Text("TOTAL")
                .font(.footnote)
                .bold()
                .foregroundStyle(.gray)
                .fontDesign(.rounded)
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(date)
                .font(.headline)
                .bold()
                .foregroundColor(.gray)
                .fontDesign(.rounded)
        
                
           
        }.padding(.leading, 8)
                .padding(.trailing)
        Spacer()
        }
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        
        
    }
}
