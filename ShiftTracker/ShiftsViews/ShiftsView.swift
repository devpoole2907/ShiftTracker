//
//  ShiftsView.swift
//  ShiftTracker
//
//  Created by James Poole on 19/03/23.
//

import SwiftUI
import CoreData
import Haptics

struct ShiftsView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @AppStorage("isProVersion", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isProVersion = false
    
    @FetchRequest(
        entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var latestShifts: FetchedResults<OldShift>
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.taxedPay, ascending: false)])
    var highPayShifts: FetchedResults<OldShift>
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(key: "duration", ascending: false)])
    var longestShifts: FetchedResults<OldShift>
    
    
    // shitty workaround test
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var latestShiftsDuctTapeFix: FetchedResults<OldShift>
    
    
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: []) var oldShifts: FetchedResults<OldShift>
        
        @State private var selectedSortingOption = 0
        
        private var sortedOldShifts: [OldShift] {
            switch selectedSortingOption {
            case 0:
                return oldShifts.sorted(by: { $0.shiftStartDate ?? Date() < $1.shiftStartDate ?? Date() })
            case 1:
                // Other sorting option, e.g. descending by shiftStartDate
                return oldShifts.sorted(by: { $0.totalPay < $1.totalPay })
            case 2:
                // Another sorting option
                return oldShifts.sorted(by: { $0.duration < $1.duration })
            default:
                return oldShifts.sorted(by: { $0.shiftStartDate ?? Date() < $1.shiftStartDate ?? Date() })
            }
        }
    
    func generateTestData(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        
        // Calculate the start date for the 2 years ago period
        let startDate = calendar.date(byAdding: .year, value: -2, to: Date())!
        let endDate = Date()
        
        // Iterate through the days to create 600 OldShifts
        var currentDate = startDate
        var count = 0
        while count < 600 && currentDate <= endDate {
            let oldShift = OldShift(context: context)
            
            // Randomize values
            let tax = Double.random(in: 10.0...40.0)
            let totalPay = Double.random(in: 200.0...400.0)
            let taxedPay = totalPay * (1 - tax / 100)
            let totalTips = Double.random(in: 0.0...100.0)
            let hourlyPay = (totalPay - totalTips) / 8.0
            let duration = 8.0 // Assuming an 8-hour shift
            let shiftEndDate = calendar.date(byAdding: .hour, value: Int(duration), to: currentDate)!
            
            // Assign values
            oldShift.taxedPay = taxedPay
            oldShift.totalPay = totalPay
            oldShift.duration = duration
            oldShift.shiftStartDate = currentDate
            oldShift.shiftEndDate = shiftEndDate
            oldShift.totalTips = totalTips
            oldShift.hourlyPay = hourlyPay
            oldShift.tax = tax
            
            // Save context
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
            
            // Move to the next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            count += 1
        }
    }

    
    @State private var searchText = ""
    
    @State private var isTotalShiftsTapped: Bool = false
    @State private var isTotalPayTapped: Bool = false
    @State private var isTaxedPayTapped: Bool = false
    @State private var isTotalHoursTapped: Bool = false
    @State private var isToggled = false
    @State private var isShareSheetShowing = false
    @State private var isEditing = false
    @State private var showAlert = false
    @State private var showingAddShiftSheet = false
    
    @State private var showProView = false
    
    @State private var searchBarOpacity: Double = 0.0
    @State private var searchBarScale: CGFloat = 0.9
    
    
    @State private var refreshingID = UUID()
    
    @State private var totalShiftsPay: Double = 0.0
    
    @State private var selectedShifts = Set<NSManagedObjectID>()
    
    
    var sortedByPayShifts: [OldShift] {
        return shifts.sorted(by: { $0.taxedPay > $1.taxedPay })
    }
    
    var sortedByLengthShifts: [OldShift] {
        return shifts.sorted(by: { $0.duration > $1.duration })
    }
    
    
    
    func startDateFromSectionKey(_ key: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE d, MMMM yyyy"
        
        let dates = key.split(separator: "-")
        let startDateString = String(dates[0]).trimmingCharacters(in: .whitespaces)
        
        return dateFormatter.date(from: startDateString)
    }



    
    var shiftSections: [(key: String, value: [OldShift])] {
        let sortedShifts: [OldShift]
        sortedShifts = shifts.sorted(by: { $0.shiftStartDate! > $1.shiftStartDate! })
        
        let groupedShifts = Dictionary(grouping: sortedShifts) { shift in
            let calendar = Calendar.current
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shift.shiftStartDate!))!
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            dateFormatter.dateFormat = "EEEE d, MMMM yyyy"
            return "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endOfWeek))"
        }
        
        return groupedShifts.sorted(by: {
            guard let date1 = startDateFromSectionKey($0.key), let date2 = startDateFromSectionKey($1.key) else {
                return false
            }
            return date1 > date2
        })
    }

    
    var filteredShifts: [[OldShift]] {
        let filteredLatestShifts = filterShifts(shifts: latestShifts)
        let filteredHighPayShifts = filterShifts(shifts: highPayShifts)
        let filteredLongestShifts = filterShifts(shifts: longestShifts)
        // shitty workaround test
        let filteredWorkaroundShifts = filterShifts(shifts: latestShiftsDuctTapeFix)
        
        return [filteredLatestShifts, filteredHighPayShifts, filteredLongestShifts, filteredWorkaroundShifts]
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






    private func sortShifts(_ shifts: [OldShift]) -> [OldShift] {
        switch sortOption {
        case 0:
            return shifts.sorted(by: { $0.shiftStartDate! > $1.shiftStartDate! })
        case 1:
            return shifts.sorted(by: { $0.taxedPay < $1.taxedPay })
        case 2:
            let duration: (OldShift) -> TimeInterval = { $0.shiftEndDate!.timeIntervalSince($0.shiftStartDate!) }
            return shifts.sorted(by: { duration($0) > duration($1) })
        default:
            return shifts.sorted(by: { $0.shiftStartDate! > $1.shiftStartDate! })
        }
    }



    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    @State private var sortOption: Int = 0
    @State private var ductTapeDisableLatest = false
    
    // the fourth option is a copy of the first (0), which we switch to if the user searches
    let sortOptions = ["Latest", "Pay", "Length", "Latest"]
    
    var shifts: FetchedResults<OldShift> {
        switch sortOption {
        case 0:
            return latestShifts
        case 1:
            return highPayShifts
        case 2:
            return longestShifts
        case 3:
            return latestShiftsDuctTapeFix
        default:
            return latestShiftsDuctTapeFix
        }
    }
    
    
    private var sortedShiftSections: [OldShift] {
        switch sortOption {
        case 0:
            return shifts.sorted(by: { $0.shiftStartDate! > $1.shiftStartDate! })
        case 1:
            return shifts.sorted(by: { $0.taxedPay > $1.taxedPay })
        case 2:
            let duration: (OldShift) -> TimeInterval = { $0.shiftEndDate!.timeIntervalSince($0.shiftStartDate!) }
            return shifts.sorted(by: { duration($0) > duration($1) })
        default:
            return shifts.sorted(by: { $0.shiftStartDate! > $1.shiftStartDate! })
        }
    }

    
    
    private func toggleSelection(for shift: OldShift) {
        let id = shift.objectID
        if selectedShifts.contains(id) {
            selectedShifts.remove(id)
        } else {
            selectedShifts.insert(id)
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
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        let backgroundColor: Color = colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : .white
        let countColor: Color = colorScheme == .dark ? Color.blue.opacity(0.5) : .blue.opacity(0.8)
        let hourColor: Color = colorScheme == .dark ? Color.orange.opacity(0.5) : .orange.opacity(0.8)
        let taxedColor: Color = colorScheme == .dark ? Color.green.opacity(0.5) : .green.opacity(0.8)
        let totalColor: Color = colorScheme == .dark ? Color.pink.opacity(0.5) : .pink.opacity(0.8)
        
        let squareColor: Color = colorScheme == .dark ? Color(.systemGray6) : Color.white
        
        
        NavigationStack{
            VStack(spacing: 1){
                List {
                    Section{
                        VStack(spacing: 15) {
                            HStack(spacing: 15) { // increased spacing between squares
                                RoundedSquareView(text: "Shifts", count: "\(oldShifts.count)", color: squareColor, imageColor: .blue, systemImageName: "briefcase.circle.fill")
                                    .frame(maxWidth: .infinity) // increased width of the square
                                    .scaleEffect(isTotalShiftsTapped ? 1.1 : 1)
                                    .animation(.easeInOut(duration: 0.3))
                                    .onTapGesture {
                                        withAnimation{
                                            isTotalShiftsTapped.toggle()
                                            sortOption = 0
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            withAnimation {
                                                isTotalShiftsTapped.toggle()
                                            }
                                        }
                                        
                                    }
                                RoundedSquareView(text: "Taxed", count: "\(currencyFormatter.currencySymbol ?? "")\(addAllTaxedPay())", color: squareColor, imageColor: .green, systemImageName: "dollarsign.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .scaleEffect(isTaxedPayTapped ? 1.1 : 1)
                                    .animation(.easeInOut(duration: 0.3))
                                    .onTapGesture {
                                        withAnimation{
                                            isTaxedPayTapped.toggle()
                                            sortOption = 1
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            withAnimation {
                                                isTaxedPayTapped.toggle()
                                            }
                                        }
                                        
                                    }
                            }
                            HStack(spacing: 15) {
                                
                                
                                
                                RoundedSquareView(text: "Hours", count: "\(addAllHours())", color: squareColor, imageColor: .orange, systemImageName: "stopwatch.fill")
                                
                                    .frame(maxWidth: .infinity)
                                    .scaleEffect(isTotalHoursTapped ? 1.1 : 1)
                                    .animation(.easeInOut(duration: 0.3))
                                    .onTapGesture {
                                        withAnimation{
                                            isTotalHoursTapped.toggle()
                                            sortOption = 2
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            withAnimation {
                                                isTotalHoursTapped.toggle()
                                            }
                                        }
                                        
                                    }
                                
                                RoundedSquareView(text: "Total", count: "\(currencyFormatter.currencySymbol ?? "")\(addAllPay())", color: squareColor, imageColor: .pink, systemImageName: "chart.line.downtrend.xyaxis.circle.fill")
                                
                                    .frame(maxWidth: .infinity)
                                    .scaleEffect(isTotalPayTapped ? 1.1 : 1)
                                    .animation(.easeInOut(duration: 0.3))
                                    .onTapGesture {
                                        withAnimation{
                                            isTotalPayTapped.toggle()
                                            sortOption = 1
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            withAnimation {
                                                isTotalPayTapped.toggle()
                                            }
                                        }
                                        
                                    }
                            }
                        }.padding(.horizontal, -15)
                        //  HStack{
                        
                    }.dynamicTypeSize(.small)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.top, 20)
                    
                    Section{
                        NavigationLink(destination: PayPeriodView()){
                            HStack(spacing: 10){
                                Image(systemName: "dollarsign.square.fill")
                                    .font(.title)
                                    .padding(.leading, -10)
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 5){
                                    Text("Pay Period for --/-- to --/--")
                                        .font(.subheadline)
                                        .bold()
                                    Text("Current earnings: $--")
                                        .font(.caption)
                                        .bold()
                                }
                            }
                        }
                        
                        
                    }
                    
                    Section{
                    if sortOption == 0 {
                     
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
                                            let durationString = String(format: "%.1f", (shift.shiftEndDate!.timeIntervalSince(shift.shiftStartDate!) / 3600.0))
                                            let dateString = dateFormatter.string(from: shift.shiftStartDate!)
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
                                }
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
                        
                    }

                    else if sortOption == 1 {
                     
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
                                            let durationString = String(format: "%.1f", (shift.shiftEndDate!.timeIntervalSince(shift.shiftStartDate!) / 3600.0))
                                            let dateString = dateFormatter.string(from: shift.shiftStartDate!)
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
                                }
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
                        
                    }


                        else if sortOption == 2 {
                           
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
                                                let durationString = String(format: "%.1f", (shift.shiftEndDate!.timeIntervalSince(shift.shiftStartDate!) / 3600.0))
                                                let dateString = dateFormatter.string(from: shift.shiftStartDate!)
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
                                    }
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
                                
                            }
                        else {
                           
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
                                                let durationString = String(format: "%.1f", (shift.shiftEndDate!.timeIntervalSince(shift.shiftStartDate!) / 3600.0))
                                                let dateString = dateFormatter.string(from: shift.shiftStartDate!)
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
                                    }
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
                                
                            }
                            
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
                    
                }
            .onChange(of: isEditing) { newValue in
                if !newValue {
                    selectedShifts.removeAll()
                }
            }
            }
            //.background(backgroundColor)
            .navigationTitle("Shifts")
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: shareButton){
                        Text("\(Image(systemName: "square.and.arrow.up"))")
                    }
                    .disabled(isEditing || !isProVersion)
                }
                if isEditing{
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("\(Image(systemName: "trash"))") {
                            
                            showAlert = true
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
                
                ToolbarItem(placement: .navigationBarLeading) {
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("\(Image(systemName: "plus"))") {
                        showingAddShiftSheet.toggle()
                    }
                    
                    .disabled(isEditing)
                }
                
            }.haptics(onChangeOf: isEditing, type: .light)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Delete Shifts?"),
                    message: Text("Are you sure you want to delete these shifts?"),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteSelectedShifts()
                    },
                    secondaryButton: .cancel()
                )
            }
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
            
        }.searchable(text: query, placement: .navigationBarDrawer(displayMode: .always))
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
    }
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }
    
    private func addAllTaxedPay() -> String {
        let total = oldShifts.reduce(0) { $0 + $1.taxedPay }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: total)) ?? "0.00"
    }
    
    private func addAllPay() -> String {
        let total = oldShifts.reduce(0) { $0 + $1.totalPay }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: total)) ?? "0.00"
    }
    
    private func addAllHours() -> String {
        let total = oldShifts.reduce(0) { $0 + $1.duration }
        let totalHours = total / 3600.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: totalHours)) ?? "0.00"
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

struct ShiftsView_Previews: PreviewProvider {
    static var previews: some View {
        ShiftsView()
    }
}


// old search bar view:

/*  SearchBarView(text: $searchText)
  
      .disabled(isEditing || sortOption == 0)
  //.padding(.horizontal, 50)
      //.padding(.top, 10)
      .frame(maxWidth: .infinity)
             .frame(height: (isEditing || sortOption == 0) ? 0 : nil)
             .clipped() // <-- Clip the content when the frame height is reduced
             .animation(.easeInOut(duration: 0.3)) */
struct ShiftRow: View {
    var oldShift: OldShift

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(oldShift.shiftStartDate ?? Date(), formatter: dateFormatter)")
                    .font(.headline)
               
            }
            Spacer()
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

struct PayPeriodView: View {
    var body: some View{
        VStack(spacing: 50){
            Text("You have entered the backrooms! ooo")
            
            Text("Invoice generation etc and pay period to go here")
        }
    }
}



