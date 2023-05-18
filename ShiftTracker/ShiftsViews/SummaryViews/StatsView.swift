//
//  StatsView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//

import SwiftUI
import CoreData
import Haptics
import PopupView

struct StatsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    //@FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    //var shifts: FetchedResults<OldShift>
    @State private var selection = 0
    let options = ["W", "M", "6M", "Y", "All"]
    @State private var refreshingID = UUID()
    @State private var selectedShifts = Set<NSManagedObjectID>()
    @State private var isEditing = false
    @State private var sortOption: Int = 0
    @State private var ductTapeDisableLatest = false
    let sortOptions = ["Latest", "Pay", "Length", "Latest"]
    let statsModes = ["Earnings", "Hours", "Breaks"]
    @State private var showingAddShiftSheet = false
    @State private var isShareSheetShowing = false
    @State private var statsMode: StatsMode = .earnings
    @AppStorage("isProVersion", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isProVersion = false
    
    let jobId: NSManagedObjectID  // the job object's unique ID passed into this view
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    @FetchRequest var latestShifts: FetchedResults<OldShift>
    @FetchRequest var highPayShifts: FetchedResults<OldShift>
    @FetchRequest var longestShifts: FetchedResults<OldShift>
    @FetchRequest var latestShiftsDuctTapeFix: FetchedResults<OldShift>
    
    init(statsMode: StatsMode, jobId: NSManagedObjectID) {
        self.jobId = jobId
        
        let predicate = NSPredicate(format: "%K == %@", #keyPath(OldShift.job), jobId)
        
        _shifts = FetchRequest(
            entity: OldShift.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)],
            predicate: predicate
        )
        
        _latestShifts = FetchRequest(
            entity: OldShift.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)],
            predicate: predicate
        )
        
        _highPayShifts = FetchRequest(
            entity: OldShift.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.taxedPay, ascending: false)],
            predicate: predicate
        )
        
        _longestShifts = FetchRequest(
            entity: OldShift.entity(),
            sortDescriptors: [NSSortDescriptor(key: "duration", ascending: false)],
            predicate: predicate
        )
        
        _latestShiftsDuctTapeFix = FetchRequest(
            entity: OldShift.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)],
            predicate: predicate
        )
        
        
    }
    
    
    func convertHoursToHourMinuteFormat(hours: Double) -> String {
        let hour = Int(hours)
        let minute = Int((hours - Double(hour)) * 60)
        return "\(hour) hr \(minute) min"
    }
    
    var filteredShifts: [[OldShift]] {
        let filteredLatestShifts = filterShifts(shifts: latestShifts)
        let filteredHighPayShifts = filterShifts(shifts: highPayShifts)
        let filteredLongestShifts = filterShifts(shifts: longestShifts)
        // shitty workaround test
        let filteredWorkaroundShifts = filterShifts(shifts: latestShiftsDuctTapeFix)
        
        return [filteredLatestShifts, filteredHighPayShifts, filteredLongestShifts, filteredWorkaroundShifts]
    }
    
    private func toggleSelection(for shift: OldShift) {
        let id = shift.objectID
        if selectedShifts.contains(id) {
            selectedShifts.remove(id)
        } else {
            selectedShifts.insert(id)
        }
    }
    
    @State private var searchText = ""
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    var job: Job? {
        try? viewContext.existingObject(with: jobId) as? Job
    }
    
    func filterShifts(shifts: FetchedResults<OldShift>) -> [OldShift] {
        if searchText.isEmpty {
            return Array(shifts)
        } else {
            let components = searchText.lowercased().components(separatedBy: " ")
            
            return shifts.filter { shift in
                let shiftDateComponents = Calendar.current.dateComponents([.year, .month, .day, .weekday], from: shift.shiftStartDate!)
                
                var matched = false
                for component in components {
                    if let day = Int(component.trimmingCharacters(in: CharacterSet.decimalDigits.inverted)),
                       shiftDateComponents.day == day {
                        matched = true
                    } else if let month = DateFormatter().monthSymbols.firstIndex(where: { $0.lowercased().contains(component) }) {
                        if shiftDateComponents.month == month + 1 {
                            matched = true
                        }
                    } else if let month = DateFormatter().shortMonthSymbols.firstIndex(where: { $0.lowercased().contains(component) }) {
                        if shiftDateComponents.month == month + 1 {
                            matched = true
                        }
                    } else if let weekdayIndex = Calendar.current.weekdaySymbols.firstIndex(where: { $0.lowercased().contains(component) }) {
                        if shiftDateComponents.weekday == weekdayIndex + 1 {
                            matched = true
                        }
                    }
                }
                
                return matched
            }
        }
    }
    
    private func deleteShift(_ shift: OldShift) {
        viewContext.delete(shift)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting shift: \(error)")
        }
    }
    
    private func deleteSelectedShifts() {
        for id in selectedShifts {
            if let shift = shifts.first(where: { $0.objectID == id }) {
                viewContext.delete(shift)
            }
        }
        do {
            try viewContext.save()
            selectedShifts.removeAll()
        } catch {
            print("Error deleting selected shifts: \(error)")
        }
    }
    
    var query: Binding<String>{
        Binding{
            searchText
        } set: { newValue in
            searchText = newValue
            latestShifts.nsPredicate = newValue.isEmpty
            ? nil
            : NSPredicate(format: "shiftStartDate CONTAINS %@", newValue)
        }
        
    }
    
    let searchMonths = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    
    var body: some View{
        let backgroundColor: Color = colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : .white
        let textColor: Color = colorScheme == .dark ? .white : .black
        let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8)
        NavigationStack{
            List{
                
                
                let today = Date()
                let calendar = Calendar.current
                let currentWeekday = calendar.component(.weekday, from: today)
                
                // Calculate the number of days to subtract to get to the previous Monday
                let daysToSubtract = currentWeekday == 1 ? 6 : (currentWeekday == 2 ? 0 : currentWeekday - 2)
                
                
                // Calculate the date for the previous Monday
                // Calculate the date for the previous Monday without time components
                let previousMondayWithTime = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
                let previousMondayComponents = calendar.dateComponents([.year, .month, .day], from: previousMondayWithTime)
                let previousMonday = calendar.date(from: previousMondayComponents)!
                
                
                let lastWeekShifts = shifts.filter { shift in
                    return shift.shiftStartDate! >= previousMonday
                }
                
                let weekShifts = lastWeekShifts.map { shift in
                    return singleShift(shift: shift)
                }.reversed()
                
                let lastMonthShifts = shifts.filter { shift in
                    let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
                    return shift.shiftStartDate! > oneMonthAgo
                }
                
                let monthShifts = lastMonthShifts.map { shift in
                    return singleShift(shift: shift)
                }.reversed()
                
                let lastThreeMonthShifts = shifts.filter { shift in
                    let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
                    return shift.shiftStartDate! > threeMonthsAgo
                }
                
                let threeMonthShifts = lastThreeMonthShifts.map { shift in
                    return singleShift(shift: shift)
                }.reversed()
                
                
                let groupedShifts = Dictionary(grouping: shifts) { shift -> Date in
                    let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shift.shiftStartDate!))!
                    return startOfWeek
                }.filter { weekStart, _ in
                    let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
                    return weekStart > sixMonthsAgo
                }
                
                let sixMonthShifts = groupedShifts.map { weekStart, shiftsInWeek -> fullWeekShifts in
                    let endDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "d/M"
                    
                    let startDateString = dateFormatter.string(from: weekStart)
                    let endDateString = dateFormatter.string(from: endDate)
                    
                    let weekShifts = shiftsInWeek.map { shift in
                        return singleShift(shift: shift)
                    }
                    
                    let totalHoursCount = weekShifts.reduce(0.0) { $0 + $1.hoursCount }
                    let totalPay = weekShifts.reduce(0.0) { $0 + $1.totalPay }
                    let totalBreakDuration = weekShifts.reduce(0.0) { $0 + $1.breakDuration }
                    
                    return fullWeekShifts(hoursCount: totalHoursCount, totalPay: totalPay, breakDuration: totalBreakDuration, startDate: startDateString, endDate: endDateString)
                }.reversed()
                
                
                
                
                
                let lastTwelveMonthShifts = shifts.filter { shift in
                    let twelveMonthsAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
                    return shift.shiftStartDate! > twelveMonthsAgo
                }
                
                let twelveMonthShifts = lastTwelveMonthShifts.map { shift in
                    return singleShift(shift: shift)
                }.reversed()
                
                
                let allShifts = shifts.map { shift in
                    return singleShift(shift: shift)
                }.reversed()
                
                let totalPayInWeek = weekShifts.reduce(0) { total, weekShift in
                    total + weekShift.totalPay
                }
                let totalHoursInWeek = weekShifts.reduce(0) { total, weekShift in
                    total + weekShift.hoursCount
                }
                let totalBreaksInWeek = weekShifts.reduce(0) { total, weekShift in
                    total + weekShift.breakDuration
                }
                
                let totalPayInMonth = monthShifts.reduce(0) { total, weekShift in
                    total + weekShift.totalPay
                }
                let totalHoursInMonth = monthShifts.reduce(0) { total, weekShift in
                    total + weekShift.hoursCount
                }
                let totalBreaksInMonth = monthShifts.reduce(0) { total, weekShift in
                    total + weekShift.breakDuration
                }
                
                let totalPayInThreeMonths = threeMonthShifts.reduce(0) { total, weekShift in
                    total + weekShift.totalPay
                }
                let totalHoursInThreeMonths = threeMonthShifts.reduce(0) { total, weekShift in
                    total + weekShift.hoursCount
                }
                let totalBreaksInThreeMonths = threeMonthShifts.reduce(0) { total, weekShift in
                    total + weekShift.breakDuration
                }
                
                
                let totalPayInSixMonths = sixMonthShifts.reduce(0) { total, weekShift in
                    total + weekShift.totalPay
                }
                let totalHoursInSixMonths = sixMonthShifts.reduce(0) { total, weekShift in
                    total + weekShift.hoursCount
                }
                let totalBreaksInSixMonths = sixMonthShifts.reduce(0) { total, weekShift in
                    total + weekShift.breakDuration
                }
                
                let totalPayInTwelveMonths = twelveMonthShifts.reduce(0) { total, weekShift in
                    total + weekShift.totalPay
                }
                let totalHoursInTwelveMonths = twelveMonthShifts.reduce(0) { total, weekShift in
                    total + weekShift.hoursCount
                }
                let totalBreaksInTwelveMonths = twelveMonthShifts.reduce(0) { total, weekShift in
                    total + weekShift.breakDuration
                }
                
                let totalPayAllTime = allShifts.reduce(0) { total, weekShift in
                    total + weekShift.totalPay
                }
                let totalHoursAllTime = allShifts.reduce(0) { total, weekShift in
                    total + weekShift.hoursCount
                }
                let totalBreaksAllTime = allShifts.reduce(0) { total, weekShift in
                    total + weekShift.breakDuration
                }
                
                let averagePayPerShift: Double = weekShifts.count > 0 ? totalPayInWeek / Double(weekShifts.count) : 0
                let averageHoursPerShift: Double = weekShifts.count > 0 ? Double(totalHoursInWeek) / Double(weekShifts.count) : 0
                let averageBreakPerShift: Double = weekShifts.count > 0 ? totalBreaksInWeek / Double(weekShifts.count) : 0
                
                let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
                let todayNoTime = calendar.date(from: todayComponents)!
                
                let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: todayNoTime)!
                let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: todayNoTime)!
                
                let previousWeekShifts = shifts.filter { shift in
                    return shift.shiftStartDate! <= eightDaysAgo && shift.shiftStartDate! > fourteenDaysAgo
                }
                
                
                let previousWeekShiftsMapped = previousWeekShifts.map { shift in
                    return singleShift(shift: shift)
                }.reversed()
                
                
                let totalPayInPreviousWeek = previousWeekShiftsMapped.reduce(0) { total, weekShift in
                    total + Int(weekShift.totalPay)
                }
                let totalHoursInPreviousWeek = previousWeekShiftsMapped.reduce(0) { total, weekShift in
                    total + Int(weekShift.hoursCount)
                }
                let totalBreaksInPreviousWeek = previousWeekShiftsMapped.reduce(0) { total, weekShift in
                    total + Int(weekShift.breakDuration)
                }
                
                let averageHoursPerShiftPreviousWeek: Double = previousWeekShiftsMapped.count > 0 ? Double(totalHoursInPreviousWeek) / Double(previousWeekShiftsMapped.count) : 0
                let averagePayPerShiftPreviousWeek: Double = previousWeekShiftsMapped.count > 0 ? Double(totalPayInPreviousWeek) / Double(previousWeekShiftsMapped.count) : 0
                let averageBreakPerShiftPreviousWeek: Double = previousWeekShiftsMapped.count > 0 ? Double(totalBreaksInPreviousWeek) / Double(previousWeekShiftsMapped.count) : 0
                
                let earningsDifference = averagePayPerShift - averagePayPerShiftPreviousWeek
                let hoursDifference = averageHoursPerShift - averageHoursPerShiftPreviousWeek
                let breaksDifference = averageBreakPerShift - averageBreakPerShiftPreviousWeek
                
                
                
                Section{
                VStack(alignment: .leading){
                    if statsMode == .earnings {
                        if selection == 0{
                            
                            ChartView(graphedShifts: weekShifts, chartDataType: .totalPay, chartDateType: .day, barColor: .green, yDomain: 1000, chartTitle: "$\(String(format: "%.2f", totalPayInWeek))", statsMode: statsMode)
                            
                        }
                        else if selection == 1{
                            ChartView(graphedShifts: monthShifts, chartDataType: .totalPay, chartDateType: .date, barColor: .green, yDomain: 1000, chartTitle: "$\(String(format: "%.2f", totalPayInMonth))", statsMode: statsMode)
                            
                        }
                        else if selection == 2 {
                            ChartView(graphedWeeks: sixMonthShifts, chartDataType: .totalPay, chartDateType: .date, barColor: .green, yDomain: 6000, chartTitle: "$\(String(format: "%.2f", totalPayInSixMonths))", statsMode: statsMode)
                        }
                        else if selection == 3 {
                            ChartView(graphedShifts: twelveMonthShifts, chartDataType: .totalPay, chartDateType: .date, barColor: .green, yDomain: 1000, chartTitle: "$\(String(format: "%.2f", totalPayInTwelveMonths))", statsMode: statsMode)
                        }
                        else {
                            ChartView(graphedShifts: allShifts, chartDataType: .totalPay, chartDateType: .date, barColor: .green, yDomain: 1000, chartTitle: "$\(String(format: "%.2f", totalPayAllTime))", statsMode: statsMode)
                        }
                    } else if statsMode == .hours {
                        
                        if selection == 0{
                            ChartView(graphedShifts: weekShifts, chartDataType: .hoursCount, chartDateType: .day, barColor: .orange, yDomain: 16, chartTitle: convertHoursToHourMinuteFormat(hours: totalHoursInWeek - totalBreaksInWeek), statsMode: statsMode)
                        }
                        else if selection == 1{
                            ChartView(graphedShifts: monthShifts, chartDataType: .hoursCount, chartDateType: .date, barColor: .orange, yDomain: 16, chartTitle: convertHoursToHourMinuteFormat(hours: totalHoursInMonth - totalBreaksInMonth), statsMode: statsMode)
                        }
                        else if selection == 2 {
                            ChartView(graphedWeeks: sixMonthShifts, chartDataType: .hoursCount, chartDateType: .date, barColor: .orange, yDomain: 110, chartTitle: convertHoursToHourMinuteFormat(hours: totalHoursInSixMonths - totalBreaksInSixMonths), statsMode: statsMode)
                        }
                        else if selection == 3 {
                            ChartView(graphedShifts: twelveMonthShifts, chartDataType: .hoursCount, chartDateType: .date, barColor: .orange, yDomain: 16, chartTitle: convertHoursToHourMinuteFormat(hours: totalHoursInTwelveMonths - totalBreaksInTwelveMonths), statsMode: statsMode)
                        }
                        else {
                            ChartView(graphedShifts: allShifts, chartDataType: .hoursCount, chartDateType: .date, barColor: .orange, yDomain: 16, chartTitle: convertHoursToHourMinuteFormat(hours: totalHoursAllTime - totalBreaksAllTime), statsMode: statsMode)
                        }
                        
                    } else {
                        if selection == 0{
                            ChartView(graphedShifts: weekShifts, chartDataType: .breakDuration, chartDateType: .day, barColor: .indigo, yDomain: 4, chartTitle: convertHoursToHourMinuteFormat(hours: totalBreaksInWeek), statsMode: statsMode)
                        }
                        else if selection == 1{
                            ChartView(graphedShifts: monthShifts, chartDataType: .breakDuration, chartDateType: .date, barColor: .indigo, yDomain: 4, chartTitle: convertHoursToHourMinuteFormat(hours: totalBreaksInMonth), statsMode: statsMode)
                            
                        }
                        else if selection == 2 {
                            ChartView(graphedWeeks: sixMonthShifts, chartDataType: .breakDuration, chartDateType: .date, barColor: .indigo, yDomain: 35, chartTitle: convertHoursToHourMinuteFormat(hours: totalBreaksInSixMonths), statsMode: statsMode)
                        }
                        else if selection == 3 {
                            ChartView(graphedShifts: twelveMonthShifts, chartDataType: .breakDuration, chartDateType: .date, barColor: .indigo, yDomain: 4, chartTitle: convertHoursToHourMinuteFormat(hours: totalBreaksInTwelveMonths), statsMode: statsMode)
                        }
                        else {
                            ChartView(graphedShifts: allShifts, chartDataType: .breakDuration, chartDateType: .date, barColor: .indigo, yDomain: 4, chartTitle: convertHoursToHourMinuteFormat(hours: totalBreaksAllTime), statsMode: statsMode)
                        }
                    }
                    Picker(selection: $selection, label: Text("Duration")) {
                        ForEach(0..<5) { index in
                            Text(options[index]).bold()
                        }
                    }
                    .listRowSeparator(.hidden)
                    .pickerStyle(.segmented)
                    //.padding(.horizontal, 10)
                }
            }header: {
                    HStack{
                        Text(statsModes[statsMode.rawValue])
                            .font(.title)
                            .bold()
                            .textCase(nil)
                            .foregroundColor(textColor)
                            .padding(.leading, -12)
                        Spacer()
                        Menu {
                            ForEach(0..<statsModes.count) { index in
                                Button(action: {
                                    statsMode = StatsMode(rawValue: index) ?? .earnings
                                }) {
                                    HStack {
                                        Text(statsModes[index])
                                            .textCase(nil)
                                        if index == statsMode.rawValue {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.accentColor) // Customize the color if needed
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                        }
                        .disabled(isEditing)
                        .haptics(onChangeOf: statsMode, type: .soft)
                    }
                }
                .listRowBackground(Color.primary.opacity(0.04))
                // .listRowBackground(Color.clear)
                
                Section {
                    ForEach(filteredShifts[sortOption]) { shift in
                        ZStack(alignment: .leading) {
                            Button(action: {
                                if isEditing {
                                    toggleSelection(for: shift)
                                }
                            }, label: {
                                HStack{
                                    let isSelected = selectedShifts.contains(shift.objectID)
                                    if isEditing {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(isSelected ? .orange : .gray)
                                    }
                                    let shiftStartDate = shift.shiftStartDate ?? Date()
                                    let shiftEndDate = shift.shiftEndDate ?? Date()
                                    let duration = shiftEndDate.timeIntervalSince(shiftStartDate) / 3600.0
                                    let durationString = String(format: "%.1f", duration)
                                    
                                    let dateString = dateFormatter.string(from: shiftStartDate)
                                    let payString = String(format: "%.2f", shift.taxedPay)
                                    
                                    VStack(alignment: .leading, spacing: 5){
                                        Text("\(currencyFormatter.currencySymbol ?? "")\(payString)")
                                            .foregroundColor(textColor)
                                            .font(.title)
                                            .bold()
                                        Text(" \(durationString) hours")
                                            .foregroundColor(.orange)
                                            .font(.subheadline)
                                            .bold()
                                        Text(dateString)
                                            .foregroundColor(.gray)
                                            .font(.footnote)
                                            .bold()
                                    }
                                }
                            })
                            if !isEditing {
                                NavigationLink(destination: DetailView(shift: shift).navigationBarTitle(Text("Shift Details")).background(backgroundColor), label: {
                                    EmptyView()
                                })
                            }
                        }.listRowBackground(Color.primary.opacity(0.04))
                            .swipeActions {
                                if !isEditing {
                                    Button(role: .destructive) {
                                        deleteShift(shift)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                    }.id(refreshingID)
                } header: {
                    HStack{
                        Text(sortOption == 0 ? "Latest Shifts" : sortOption == 1 ? "Highest Pay" : sortOption == 2 ? "Longest Shifts" : "Latest Shifts")
                            .font(.title)
                            .bold()
                            .textCase(nil)
                            .foregroundColor(textColor)
                            .padding(.leading, -12)
                        Spacer()
                        Menu {
                            ForEach(0 ..< 4) { index in
                                // duct tape stuff, if the boolean is true and the option is 0 then hide it from the menu so they cant return to the broken latestShifts
                                if (index == 0 && ductTapeDisableLatest) || (index == 3 && !ductTapeDisableLatest) {
                                    // Exclude this menu option
                                } else {
                                    Button(action: {
                                        sortOption = index
                                    }) {
                                        HStack {
                                            Text(self.sortOptions[index])
                                                .textCase(nil)
                                            if index == sortOption {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.accentColor) // Customize the color if needed
                                            }
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title2)
                        }
                        .disabled(isEditing)
                        
                        //.padding(.horizontal, 50)
                        .haptics(onChangeOf: sortOption, type: .soft)
                    }
                }
                
                
                Section{
                    Spacer()
                }.listRowBackground(Color.clear)
                
                
            }.scrollContentBackground(.hidden)
            
                .sheet(isPresented: $showingAddShiftSheet) {
                    if #available(iOS 16.4, *) {
                        AddShiftView().environment(\.managedObjectContext, viewContext)
                            .presentationDetents([ .medium, .large])
                            .presentationDragIndicator(.visible)
                            .presentationBackground(.thinMaterial)
                            .presentationCornerRadius(12)
                    }
                    else {
                        AddShiftView().environment(\.managedObjectContext, viewContext)
                    }
                }
            
                .toolbar{
                    ToolbarItem(placement: .navigationBarTrailing) {
                        
                        
                        Button(action: shareButton){
                            Text("\(Image(systemName: "square.and.arrow.up"))")
                        }
                        .disabled(isEditing || !isProVersion)
                        
                       
                    }
                       if !isEditing {
                               ToolbarItem(placement: .navigationBarTrailing) {
                                   Button("\(Image(systemName: "plus"))") {
                                       showingAddShiftSheet.toggle()
                                   }
                                   .disabled(isEditing)
                               }
                           
                       }
                       else{
                               ToolbarItem(placement: .navigationBarTrailing) {
                                   Button("\(Image(systemName: "trash"))") {
                                       
                                       DeleteShiftAlert(action: {
                                           deleteSelectedShifts()
                                           isEditing = false
                                       }).present()
                                   }
                                   
                                   .disabled(selectedShifts.isEmpty)
                               }
                           
                       }
                           
                       
                       
                  /*    ToolbarItem(placement: .navigationBarTrailing) {
                           Button(action: {
                               generateTestData(context: viewContext)
                           }) {
                               Label("Generate Test Data", systemImage: "arrow.clockwise")
                           }
                       } */
                       
                       ToolbarItem(placement: .navigationBarTrailing) {
                           if isEditing {
                               Button("Done") {
                                   withAnimation {
                                       isEditing.toggle()
                                   }
                               }
                           } else {
                               Button("\(Image(systemName: "pencil"))") {
                                   withAnimation {
                                       isEditing.toggle()
                                       
                                   }
                               }
                           }
                       }
                       
                       
                   }.haptics(onChangeOf: isEditing, type: .light)
            
                .searchable(text: query, placement: .navigationBarDrawer(displayMode: .always))
                .searchSuggestions {
                    ForEach(searchMonths, id: \.self) { month in
                        if searchText.isEmpty || month.lowercased().starts(with: searchText.lowercased()) {
                            Text(month).searchCompletion(month.lowercased())
                        }
                    }
                }
            // more ducttape fix stuff, if the sortOption is 0 when searching toggle the disable latest boolean which will then use the copy of latest shifts, which works
                .onSubmit(of: .search) {  // Add the onSubmit closure
                    // Perform search
                    if sortOption == 0 {
                        sortOption = 3
                        ductTapeDisableLatest.toggle()
                    }
                }
                .onAppear{
                    viewContext.reset()
                    self.refreshingID = UUID()
                }
            
            
                .navigationBarTitle(job?.name ?? "Job Name")
        }
        
    }
    
    func shareButton() {
        let fileName = "export.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = "Start Date,End Date,Break Start,Break End,Before Tax,After Tax\n"
        
        for latestShift in latestShifts {
            csvText += "\(latestShift.shiftStartDate ?? Date()),\(latestShift.shiftEndDate ?? Date()),\(latestShift.breakStartDate ?? Date())\(latestShift.breakEndDate ?? Date()),\(latestShift.shiftEndDate ?? Date()),\(latestShift.totalPay ),\(latestShift.taxedPay )\n"
        }
        
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create file")
            print("\(error)")
        }
        print(path ?? "not found")
        
        var filesToShare = [Any]()
        filesToShare.append(path!)
        
        let av = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
        
        isShareSheetShowing.toggle()
    }
    
}

//rename this back to DeleteShiftAlert later
struct DeleteJobShiftAlert: CentrePopup {
    let action: () -> Void
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        VStack(spacing: 5) {
            
            createTitle()
                .padding(.vertical)
            //Spacer(minLength: 32)
            //  Spacer.height(32)
            createButtons()
            // .padding()
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background(.primary.opacity(0.05))
    }
}

private extension DeleteJobShiftAlert {
    
    func createTitle() -> some View {
        Text("Are you sure you want to delete these shifts?")
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    func createButtons() -> some View {
        HStack(spacing: 4) {
            createCancelButton()
            createUnlockButton()
        }
    }
}

private extension DeleteJobShiftAlert {
    func createCancelButton() -> some View {
        Button(action: dismiss) {
            Text("Cancel")
            
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.primary.opacity(0.1))
                .cornerRadius(8)
        }
    }
    func createUnlockButton() -> some View {
        Button(action: {
            action()
            dismiss()
        }) {
            Text("Confirm")
                .bold()
                .foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
    }
}
