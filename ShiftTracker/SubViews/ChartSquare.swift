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
    
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    
    @State private var selectedDateRange: DateRange = .week
    
    @Binding var isChartViewPrimary: Bool
    
    @State private var selectedDay = ""
    @State private var selectedValue: Double = 0
    @State private var lastShifts: [singleShift] = []
    
    @State private var viewOpacity: Double = 0.0
    
    @State private var offsetX = 0.0
    @State private var offsetY = 150.0
    
    @State private var isPickerEnabled: Bool = false
    
    @State private var showSelectionBar: Bool = false
    
    @State private var currentActiveMark: ShiftWeek?
    @State private var currentActiveShift: singleShift?
    @State private var currentActiveMonth: ShiftMonth?
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
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    
    init(isChartViewPrimary: Binding<Bool>){
        _isChartViewPrimary = isChartViewPrimary
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        _shifts = FetchRequest(fetchRequest: fetchRequest)
    }
    
    var body: some View {
                        
        
        let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)
        let headerColor: Color = colorScheme == .dark ? .white : .black
        HStack{
            VStack(alignment: .leading) {
                HStack(spacing: isChartViewPrimary ? 10 : 5){
                    
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
                                   
                } .onTapGesture {
                    withAnimation{
                        isChartViewPrimary.toggle()
                    }
                }

                if isChartViewPrimary {
                    HStack{
                        VStack(alignment: .leading){
                            Text("Total")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.gray)

                                Text(shiftManager.statsMode == .earnings ? "\(shiftManager.currencyFormatter.string(from: NSNumber(value: shiftManager.getTotalPay(from: lastShifts))) ?? "0")" : shiftManager.formatTime(timeInHours: shiftManager.getTotalHours(from: lastShifts)))
                                    .font(.title2)
                                    .bold()
                                
                            
                                
                        }
                        Spacer()
                        
                    }.padding(.top, 5)
                        .padding(.leading)
                    .opacity(showSelectionBar ? 0.0 : 1.0)
                }
                
                /*
                Chart {
                        ForEach(self.lastShifts) { shift in
                            
                            
                            
                            switch shiftManager.dateRange {
                                
                            case .week:
                                
                                
                                
                                    if let currentActiveShift, currentActiveShift.id == shift.id{
                                        if #available(iOS 17, *){
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
                                        
                                    } else {
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
                                    }
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
                            case .month:
                                
                           /*     if let currentActiveShift, currentActiveShift.id == shift.id{
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
                            } */
                                
                                
                                
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
                            case .halfYear:
                                
                                if let currentActiveShift, currentActiveShift.id == shift.id{
                                    if #available(iOS 17, *){
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
                                    
                                } else {
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
                                }
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
                                
                                
                            case .year:
                                
                                
                                if let currentActiveShift, currentActiveShift.id == shift.id{
                                    if #available(iOS 17, *){
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
                                    
                                } else {
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
                                }
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
                .onReceive(jobSelectionViewModel.$selectedJobUUID) { _ in
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
                                                if let currentMark = lastShifts.first(where: { mark in
                                                    
                                                    print("check check")
                                                    
                                                    return compareDates(mark.shiftStartDate, date)
                                                    
                                                    
                                                    
                                                }) {
                                                  print("check check check")
                                                    self.currentActiveShift = currentMark
                                                    self.plotWidth = proxy.plotAreaSize.width
                                                }
                                                
                                                
                                            }
                                            
                                            
                                        } .onEnded{ value in
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    showSelectionBar = false
                                                    self.currentActiveMark = nil
                                                    self.currentActiveShift = nil
                                                    self.currentActiveMonth = nil
                                                }
                                            }
                                        }
                                )
                        }
                    })
                
                */
                /*
                    .chartOverlay { pr in
                        GeometryReader { geoProxy in
                            Rectangle().foregroundStyle(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
                                .frame(width: 2, height: geoProxy.size.height * 0.95)
                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                .offset(x: shiftManager.dateRange == .week ? max(10, min(offsetX, geoProxy.size.width + 50)) : max(10, min(offsetX + 15, geoProxy.size.width + 50)))
                                //.offset(y: 800)
                            Rectangle()
                                .foregroundStyle(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
                                .frame(width: 180, height: 70)
                                .cornerRadius(8)
                                .overlay {
                                    HStack{
                                    VStack(alignment: .leading){
                                        Text("\(selectedDay)")
                                            .font(.headline)
                                            .bold()
                                            .foregroundColor(.gray)
                                        if shiftManager.statsMode == .earnings {
                                            Text("$\(String(format: "%.2f", selectedValue))")
                                                .font(.title2)
                                                .bold()
                                        } else {
                                            Text("\(String(format: "%.2f", selectedValue))h")
                                                .font(.title2)
                                                .bold()
                                        }
                                    }.padding(.leading)
                                    Spacer()
                                }

                                    Spacer()
                                }//.shadow(radius: 3, x: 0, y: 1)
                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                .offset(x: max(10, min(offsetX - 50, geoProxy.size.width - 200)), y: -70)
                            Rectangle().fill(.clear).contentShape(Rectangle()).gesture(DragGesture().onChanged{ value in
                                if !showSelectionBar {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showSelectionBar = true
                                    }
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
                                
                                let (dateDay, _) = pr.value(at: location, as: (Date, Int).self) ?? (Date(), 0)
                                
                                print("six month day: \(dateDay)")
                                
                                
                                
                                if shiftManager.dateRange == .week || shiftManager.dateRange == .month {
                                    if let chartShift = shiftManager.getLastShifts(from: shifts, jobModel: jobSelectionViewModel, dateRange: shiftManager.dateRange).first(where: { cs in
                                        
                                         
                                            if shiftManager.dateRange == .month {
                                                return cs.date.lowercased() == day.lowercased()
                                            }
                                            else {
                                                return cs.dayOfWeek.lowercased() == day.lowercased()
                                            }
                                        
                                       // return cs.date.lowercased() == day.lowercased()
                                        
                                    }) {
                                        let valueToDisplay: Double = {
                                            switch shiftManager.statsMode {
                                            case .earnings:
                                                return chartShift.totalPay
                                            case .hours:
                                                return chartShift.hoursCount
                                            case .breaks:
                                                return chartShift.breakDuration
                                            }
                                        }()
                                        selectedDay = day
                                        selectedValue = valueToDisplay
                                        
                                        
                                    } else {
                                        print("I have failed the check for some reason")
                                        selectedDay = "-"
                                        selectedValue = 0
                                    }
                                } else if shiftManager.dateRange == .halfYear {
                                    if let chartShift = shiftManager.getLastShiftWeeks(from: shifts, jobModel: jobSelectionViewModel, dateRange: shiftManager.dateRange).first(where: { cs in
                                                print("hey we got this far")
                                        return compareDates(cs.weekStartDate, dateDay)
                                  
                                    }) {
                                        let valueToDisplay: Double = {
                                            switch shiftManager.statsMode {
                                            case .earnings:
                                                return chartShift.totalPay
                                            case .hours:
                                                return chartShift.hoursCount
                                            case .breaks:
                                                return chartShift.breakDuration
                                            }
                                        }()
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "dd/M/YYYY"
                                        print("You reached the code!")
                                        selectedDay = formatter.string(from: dateDay)
                                        selectedValue = valueToDisplay
                                        
                                        
                                    } else {
                                        print("I have failed the check for some reason")
                                        selectedDay = "-"
                                        selectedValue = 0
                                    }
                                } else {
                                    if let chartShift = shiftManager.getLastShiftMonths(from: shifts, jobModel: jobSelectionViewModel, dateRange: shiftManager.dateRange).first(where: { cs in
                                                print("hey we got this far")
                                        return compareDates(cs.date, dateDay)
                                            
                                        
                                       // return cs.date.lowercased() == day.lowercased()
                                        
                                    }) {
                                        let valueToDisplay: Double = {
                                            switch shiftManager.statsMode {
                                            case .earnings:
                                                return chartShift.totalPay
                                            case .hours:
                                                return chartShift.hoursCount
                                            case .breaks:
                                                return chartShift.breakDuration
                                            }
                                        }()
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "dd/M/YYYY"
                                        print("You reached the code!")
                                        selectedDay = formatter.string(from: dateDay)
                                        selectedValue = valueToDisplay
                                        
                                        
                                    } else {
                                        print("I have failed the check for some reason")
                                        selectedDay = "-"
                                        selectedValue = 0
                                    }
                                }
                                
                                
                                
                                
                                
                                    
                                
                            }
                            .onEnded({ _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showSelectionBar = false
                                        offsetX = 0.0
                                    }
                                }
                            }))
                        }
                        
                                        
                                    }.haptics(onChangeOf: selectedValue, type: .light)
                */
                
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

        isPickerEnabled = false
        
            self.lastShifts = shiftManager.getLastShifts(from: shifts, jobModel: jobSelectionViewModel, dateRange: shiftManager.dateRange)
            for(index,_) in self.lastShifts.enumerated(){
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05){
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)){
                        self.lastShifts[index].animate = true
                        
                        
                        if index == self.lastShifts.count - 1 {
                                            isPickerEnabled = true
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
