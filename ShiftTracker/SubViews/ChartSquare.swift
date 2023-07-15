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

    
    @Environment(\.colorScheme) var colorScheme
    
    var data: [ChartTest] = [
        .init(type: "M", count: 5),
        .init(type: "T", count: 4),
        .init(type: "W", count: 4),
        .init(type: "Th", count: 0),
        .init(type: "F", count: 6),
        .init(type: "S", count: 5),
        .init(type: "Su", count: 2)
    ]
    
    var body: some View {
                        
        
        let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)
        let headerColor: Color = colorScheme == .dark ? .white : .black
        HStack{
            VStack(alignment: .leading) {
                HStack(spacing: isChartViewPrimary ? 10 : 5){
                    
                    
                    Group {
                        Text(isChartViewPrimary ? "\(shiftManager.dateRange.description) \(shiftManager.statsMode.description)" : "\(shiftManager.dateRange.description) Activity")
                            .font(.callout)
                            .bold()
                            .foregroundStyle(headerColor)
                            .padding(.leading)
                            .padding(.vertical, isChartViewPrimary ? 10 : 0)
                            .animation(.easeInOut, value: isChartViewPrimary)
                        Image(systemName: "chevron.right")
                            .font(isChartViewPrimary ? .callout : .footnote)
                            .bold()
                            .foregroundStyle(.gray)
                            .rotationEffect(isChartViewPrimary ? .degrees(90) : .degrees(0))
                            .animation(.easeInOut, value: isChartViewPrimary)
                        
                    }
                    
                    
                    .onTapGesture {
                        withAnimation{
                            isChartViewPrimary.toggle()
                        }
                    }
                    
                    Spacer()
                    if isChartViewPrimary {
                        CloseButton(action: {
                            withAnimation{
                                isChartViewPrimary = false
                            }
                        })
                            .frame(width: 24, height: 24)
                            .padding(.trailing)
                    }
                                   
                }

                if isChartViewPrimary {
                    HStack{
                        VStack(alignment: .leading){
                            Text("Total")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.gray)

                            Text(shiftManager.statsMode == .earnings ? "\(shiftManager.currencyFormatter.string(from: NSNumber(value: shiftManager.getTotalPay(from: shiftManager.recentShifts))) ?? "0")" : shiftManager.formatTime(timeInHours: shiftManager.getTotalHours(from: shiftManager.recentShifts)))
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
                                /*   if #available(iOS 17, *){
                                 RuleMark(x: .value("Day", currentActiveShift.shiftStartDate, unit: .weekday))
                                 .foregroundStyle(Color(.systemGray6))
                                 .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit, y: .disabled)){
                                 if shiftManager.statsMode == .earnings {
                                 
                                 ChartAnnotation(value: "$\(String(format: "%.2f", currentActiveShift.totalPay))", date: currentActiveShift.date)
                                 .opacity(showSelectionBar ? 1.0 : 0.0)
                                 } else {
                                 ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.hoursCount))h", date: currentActiveShift.date)
                                 .opacity(showSelectionBar ? 1.0 : 0.0)
                                 }
                                 
                                 }
                                 
                                 } else { */
                                RuleMark(x: .value("Day", currentActiveShift.shiftStartDate, unit: .weekday))
                                    .foregroundStyle(Color(.systemGray6))
                                    .annotation(position: .top){
                                        if shiftManager.statsMode == .earnings {
                                            
                                            ChartAnnotation(value: "$\(String(format: "%.2f", currentActiveShift.totalPay))", date: currentActiveShift.date)
                                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                        } else {
                                            ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.hoursCount))h", date: currentActiveShift.date)
                                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                        }
                                        
                                    }
                                // }
                            }
                            
                            
                            
                            BarMark(x: .value("Day", shift.shiftStartDate, unit: .weekday),
                                    y: .value(shiftManager.statsMode == .earnings ? "Earnings" : "Hours",
                                              shift.animate
                                              ? (shiftManager.statsMode == .earnings
                                                 ? shift.totalPay
                                                 : shift.hoursCount)
                                              : 0
                                             )
                            )
                            .foregroundStyle(shiftManager.statsMode == .earnings ? LinearGradient(
                                gradient: Gradient(colors: [Color(red: 198 / 255, green: 253 / 255, blue: 80 / 255), Color(red: 112 / 255, green: 218 / 255, blue: 65 / 255)
                                                           ]),
                                startPoint: .top,
                                endPoint: .bottom) : LinearGradient(
                                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                    startPoint: .top,
                                    endPoint: .bottom)
                            )
                            .cornerRadius(shiftManager.statsMode == .earnings ? 10 : 5, style: .continuous)
                            
                            
                            
                        }
                    case .month:
                        
                        ForEach(shiftManager.monthlyShifts) { shift in
                            
                            if let currentActiveShift, currentActiveShift.id == shift.id{
                                /*    if #available(iOS 17, *){
                                 RuleMark(x: .value("Day", currentActiveShift.shiftStartDate, unit: .day))
                                 .foregroundStyle(Color(.systemGray6))
                                 .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit, y: .disabled)){
                                 if shiftManager.statsMode == .earnings {
                                 
                                 ChartAnnotation(value: "$\(String(format: "%.2f", currentActiveShift.totalPay))", date: currentActiveShift.date)
                                 .opacity(showSelectionBar ? 1.0 : 0.0)
                                 } else {
                                 ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.hoursCount))h", date: currentActiveShift.date)
                                 .opacity(showSelectionBar ? 1.0 : 0.0)
                                 }
                                 
                                 }
                                 
                                 } else { */
                                RuleMark(x: .value("Day", currentActiveShift.shiftStartDate, unit: .day))
                                    .foregroundStyle(Color(.systemGray6))
                                    .annotation(position: .top){
                                        if shiftManager.statsMode == .earnings {
                                            
                                            ChartAnnotation(value: "$\(String(format: "%.2f", currentActiveShift.totalPay))", date: currentActiveShift.date)
                                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                        } else {
                                            ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.hoursCount))h", date: currentActiveShift.date)
                                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                        }
                                        
                                    }
                                //}
                            }
                            
                            
                            
                            BarMark(x: .value("Day", shift.shiftStartDate, unit: .day),
                                    y: .value(shiftManager.statsMode == .earnings ? "Earnings" : "Hours",
                                              shift.animate
                                              ? (shiftManager.statsMode == .earnings
                                                 ? shift.totalPay
                                                 : shift.hoursCount)
                                              : 0
                                             )
                            )
                            .foregroundStyle(shiftManager.statsMode == .earnings ? LinearGradient(
                                gradient: Gradient(colors: [Color(red: 198 / 255, green: 253 / 255, blue: 80 / 255), Color(red: 112 / 255, green: 218 / 255, blue: 65 / 255)
                                                           ]),
                                startPoint: .top,
                                endPoint: .bottom) : LinearGradient(
                                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                    startPoint: .top,
                                    endPoint: .bottom)
                            )
                            .cornerRadius(shiftManager.statsMode == .earnings ? 10 : 5, style: .continuous)
                            
                            
                        }
                        
                    case .halfYear:
                        
                        
                        ForEach(shiftManager.halfYearlyShifts) { shift in
                            
                            if let currentActiveShift, currentActiveShift.id == shift.id{
                                /*   if #available(iOS 17, *){
                                 RuleMark(x: .value("Day", currentActiveShift.shiftStartDate, unit: .weekOfYear))
                                 .foregroundStyle(Color(.systemGray6))
                                 .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit, y: .disabled)){
                                 if shiftManager.statsMode == .earnings {
                                 
                                 ChartAnnotation(value: "$\(String(format: "%.2f", currentActiveShift.totalPay))", date: currentActiveShift.date)
                                 .opacity(showSelectionBar ? 1.0 : 0.0)
                                 } else {
                                 ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.hoursCount))h", date: currentActiveShift.date)
                                 .opacity(showSelectionBar ? 1.0 : 0.0)
                                 }
                                 
                                 }
                                 
                                 } else { */
                                RuleMark(x: .value("Day", currentActiveShift.shiftStartDate, unit: .weekOfYear))
                                    .foregroundStyle(Color(.systemGray6))
                                    .annotation(position: .top){
                                        if shiftManager.statsMode == .earnings {
                                            
                                            ChartAnnotation(value: "$\(String(format: "%.2f", currentActiveShift.totalPay))", date: currentActiveShift.date)
                                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                        } else {
                                            ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.hoursCount))h", date: currentActiveShift.date)
                                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                        }
                                        
                                    }
                                //}
                            }
                            
                            
                            
                            
                            
                            BarMark(x: .value("Day", shift.shiftStartDate, unit: .weekOfYear),
                                    y: .value(shiftManager.statsMode == .earnings ? "Earnings" : "Hours",
                                              shift.animate
                                              ? (shiftManager.statsMode == .earnings
                                                 ? shift.totalPay
                                                 : shift.hoursCount)
                                              : 0
                                             )
                            )
                            .foregroundStyle(shiftManager.statsMode == .earnings ? LinearGradient(
                                gradient: Gradient(colors: [Color(red: 198 / 255, green: 253 / 255, blue: 80 / 255), Color(red: 112 / 255, green: 218 / 255, blue: 65 / 255)
                                                           ]),
                                startPoint: .top,
                                endPoint: .bottom) : LinearGradient(
                                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                    startPoint: .top,
                                    endPoint: .bottom)
                            )
                            .cornerRadius(shiftManager.statsMode == .earnings ? 10 : 5, style: .continuous)
                        }
                        
                    case .year:
                        
                        ForEach(shiftManager.yearlyShifts) { shift in
                        if let currentActiveShift, currentActiveShift.id == shift.id{
                            /*   if #available(iOS 17, *){
                             RuleMark(x: .value("Day", currentActiveShift.shiftStartDate, unit: .month))
                             .foregroundStyle(Color(.systemGray6))
                             .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit, y: .disabled)){
                             if shiftManager.statsMode == .earnings {
                             
                             ChartAnnotation(value: "$\(String(format: "%.2f", currentActiveShift.totalPay))", date: currentActiveShift.date)
                             .opacity(showSelectionBar ? 1.0 : 0.0)
                             } else {
                             ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.hoursCount))h", date: currentActiveShift.date)
                             .opacity(showSelectionBar ? 1.0 : 0.0)
                             }
                             
                             }
                             
                             } else { */
                            RuleMark(x: .value("Day", currentActiveShift.shiftStartDate, unit: .month))
                                .foregroundStyle(Color(.systemGray6))
                                .annotation(position: .top){
                                    if shiftManager.statsMode == .earnings {
                                        
                                        ChartAnnotation(value: "$\(String(format: "%.2f", currentActiveShift.totalPay))", date: currentActiveShift.date)
                                            .opacity(showSelectionBar ? 1.0 : 0.0)
                                    } else {
                                        ChartAnnotation(value: "\(String(format: "%.2f", currentActiveShift.hoursCount))h", date: currentActiveShift.date)
                                            .opacity(showSelectionBar ? 1.0 : 0.0)
                                    }
                                    
                                }
                            // }
                        }
                        
                        
                        
                        BarMark(x: .value("Day", shift.shiftStartDate, unit: .month),
                                y: .value(shiftManager.statsMode == .earnings ? "Earnings" : "Hours",
                                          shift.animate
                                          ? (shiftManager.statsMode == .earnings
                                             ? shift.totalPay
                                             : shift.hoursCount)
                                          : 0
                                         )
                        )
                        .foregroundStyle(shiftManager.statsMode == .earnings ? LinearGradient(
                            gradient: Gradient(colors: [Color(red: 198 / 255, green: 253 / 255, blue: 80 / 255), Color(red: 112 / 255, green: 218 / 255, blue: 65 / 255)
                                                       ]),
                            startPoint: .top,
                            endPoint: .bottom) : LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                startPoint: .top,
                                endPoint: .bottom)
                        )
                        .cornerRadius(shiftManager.statsMode == .earnings ? 10 : 5, style: .continuous)
                        
                    }
                            }
                        
                        
                        
                    
                    
                    
                }
                .onAppear {
                    animateGraph()
                }
                
                .onReceive(shiftManager.$shiftAdded) { _ in
                    animateGraph()
                        }
                
                .onReceive(shiftManager.$statsMode) { _ in
                    animateGraph()
                        }
                .onReceive(shiftManager.shiftDataLoaded) { _ in
                    animateGraph()
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
                        } else if shiftManager.dateRange == .halfYear {
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
                                                case .halfYear:
                                                    if let currentMark = shiftManager.halfYearlyShifts.first(where: { mark in
                                                        
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
                
                if isChartViewPrimary{
                    
                    
                    
                    Picker(selection: $shiftManager.dateRange, label: Text("Duration")) {
                        ForEach(DateRange.allCases, id: \.self) { dateRange in
                            Text(dateRange.shortDescription).bold().tag(dateRange)
                        }
                    }.padding(.horizontal)
                       // .disabled(!isPickerEnabled) temp crash fix when changing picker too fast ...
                    .listRowSeparator(.hidden)
                    .pickerStyle(.segmented)
                    .contentShape(Rectangle())
                    
                    
                    .onChange(of: shiftManager.dateRange){ _ in
                        animateGraph()
                    }
                    
                }
            }//.padding(.horizontal, 10)
            //.padding(.leading)
           // Spacer()
        }
            .padding(.vertical, 8)
            .background(Color("SquaresColor"))
            .cornerRadius(12)
          
    }
    
    func animateGraph(){
        
        switch shiftManager.dateRange {
        case .week:
            for(index,_) in shiftManager.recentShifts.enumerated(){
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05){
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)){
                        shiftManager.recentShifts[index].animate = true
                        
                    }
                    
                }

            }
            
        case .month:
            for(index,_) in shiftManager.monthlyShifts.enumerated(){
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05){
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)){
                        shiftManager.monthlyShifts[index].animate = true
                        
                    }
                    
                }

            }
            
        case .halfYear:
            for(index,_) in shiftManager.halfYearlyShifts.enumerated(){
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05){
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)){
                        shiftManager.halfYearlyShifts[index].animate = true
                        
                    }
                    
                }

            }
            
        case .year:
            for(index,_) in shiftManager.yearlyShifts.enumerated(){
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05){
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)){
                        shiftManager.yearlyShifts[index].animate = true
                        
                    }
                    
                }

            }
            
            
            
        }
        

    }
    
    func compareDates(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.year, .month, .day], from: date1)
        let components2 = calendar.dateComponents([.year, .month, .day], from: date2)
        return components1 == components2
    }

    
}
/*
struct ChartSquare_Previews: PreviewProvider {
    static var previews: some View {
        ChartSquare(isChartViewPrimary: .constant(true))
            .previewLayout(.fixed(width: 400, height: 200)) // Change the width and height as per your requirement
    }
}*/


struct ChartTest: Identifiable {
    var type: String
    var count: Double
    var id = UUID()
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
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(date)
                .font(.headline)
                .bold()
                .foregroundColor(.gray)
        
                
           
        }.padding(.leading, 8)
                .padding(.trailing)
        Spacer()
        }
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        
        
    }
}
