//
//  DetailView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/03/23.
//

import SwiftUI
import CoreData
import Foundation
import Charts

struct DetailView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.managedObjectContext) private var context
    
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    @StateObject var temporaryViewModel = ContentViewModel()
    
    let breakManager = BreaksManager()
    
    var presentedAsSheet: Bool
    @Binding var activeSheet: ActiveSheet?
    
    @Binding var navPath: NavigationPath
    
    @State private var notes: String
    @FocusState private var noteIsFocused: Bool
    @State var isEditing: Bool = false
    @State private var isAddingBreak: Bool = false
    @State private var isUnpaid: Bool = false
    
    @State private var showingDeleteAlert = false
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    @State private var selectedStartDate: Date
    @State private var selectedEndDate: Date
    @State private var selectedBreakStartDate: Date
    @State private var selectedBreakEndDate: Date
    @State private var selectedTaxPercentage: Double
    @State private var selectedHourlyPay: String = ""
    @State private var shiftDuration: TimeInterval
    @State private var selectedTotalTips: String = ""
    @State private var addTipsToTotal: Bool = false
    
    //tags stuff
    
    @AppStorage("tagList") private var tagsList: Data = Data()
    @State private var tags: [Tag] = []
    @State private var selectedTag: Tag? = nil
    
    @AppStorage("TipsEnabled") private var tipsEnabled: Bool = true
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    
    @FocusState private var payIsFocused: Bool
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var shifts: FetchedResults<OldShift>
    
    @ObservedObject var shift: OldShift
    
    @EnvironmentObject var navigationState: NavigationState
    
    init(shift: OldShift, presentedAsSheet: Bool, activeSheet: Binding<ActiveSheet?>? = nil, navPath: Binding<NavigationPath>) {
        self.shift = shift
        _notes = State(wrappedValue: shift.shiftNote ?? "")
        _selectedStartDate = State(wrappedValue: shift.shiftStartDate ?? Date())
        _selectedEndDate = State(wrappedValue: shift.shiftEndDate ?? Date())
        _selectedBreakStartDate = State(wrappedValue: shift.breakStartDate ?? Date())
        _selectedBreakEndDate = State(wrappedValue: shift.breakEndDate ?? Date())
        _selectedTaxPercentage = State(wrappedValue: shift.tax )
        _selectedHourlyPay = State(initialValue: "\(shift.hourlyPay)")
        //_selectedTag = State(wrappedValue: shift.tag)
        _shiftDuration = State(wrappedValue: shift.duration)
        _selectedTotalTips = State(wrappedValue: "\(shift.totalTips)")
        self.presentedAsSheet = presentedAsSheet
        _activeSheet = activeSheet ?? Binding.constant(nil)
        _navPath = navPath 
    }
    
    func totalBreakDuration(for breaks: Set<Break>) -> TimeInterval {
        let paidBreaks = breaks.filter { $0.isUnpaid == true }
        let totalDuration = paidBreaks.reduce(0) { (sum, breakItem) -> TimeInterval in
            let breakDuration = breakItem.endDate?.timeIntervalSince(breakItem.startDate ?? Date())
            return sum + (breakDuration ?? 0.0)
        }
        return totalDuration
    }
    
    let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    

    
    @State private var offsetX = 0.0
    @State private var offsetY = 150.0
    
    @State private var showSelectionBar = false
    
    @State private var selectedDay = ""
    @State private var selectedValue: Double = 0
    @State private var selectedMins = 0.0
    
    var body: some View {
        
        var timeDigits = digitsFromTimeString(timeString: shift.duration.stringFromTimeInterval())
        var breakDigits = digitsFromTimeString(timeString: totalBreakDuration(for: (shift.breaks as? Set<Break> ?? Set<Break>())).stringFromTimeInterval())
        
        List{
            
            Section{
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundColor(Color("SquaresColor"))
                            .frame(width: UIScreen.main.bounds.width - 40)
                            .shadow(radius: 5, x: 0, y: 4)
                        VStack(alignment: .center, spacing: 5) {
                            VStack {
                                Text("\(currencyFormatter.string(from: NSNumber(value: shift.taxedPay)) ?? "")")
                                    .padding(.horizontal, 20)
                                    .font(.system(size: 60).monospacedDigit())
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .allowsTightening(true)
                                
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top)
                            HStack(spacing: 10){
                                if shift.tax > 0 {
                                    HStack(spacing: 2){
                                        Image(systemName: "chart.line.downtrend.xyaxis")
                                            .font(.system(size: 15).monospacedDigit())
                                            .fontWeight(.light)
                                        Text("\(currencyFormatter.string(from: NSNumber(value: shift.totalPay)) ?? "")")
                                            .font(.system(size: 20).monospacedDigit())
                                            .bold()
                                            .lineLimit(1)
                                            .allowsTightening(true)
                                    }.foregroundStyle(themeManager.taxColor)
                                }
                                if shift.totalTips > 0 {
                                    HStack(spacing: 2){
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.system(size: 15).monospacedDigit())
                                            .fontWeight(.light)
                                        Text("\(currencyFormatter.string(from: NSNumber(value: shift.totalTips)) ?? "")")
                                            .font(.system(size: 20).monospacedDigit())
                                            .bold()
                                            .lineLimit(1)
                                    }.foregroundStyle(themeManager.tipsColor)
                                }
                            }
                                
                                    .padding(.horizontal, 20)
                                
                                
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 5)
                            
                            // }
                            
                            Divider().frame(maxWidth: 200)
                            if let shiftsBreaks = shift.breaks, totalBreakDuration(for: shift.breaks as! Set<Break>) > 0 {
                                    HStack(spacing: 0) {
                                        ForEach(0..<timeDigits.count, id: \.self) { index in
                                            RollingDigit(digit: timeDigits[index])
                                                .frame(width: 20, height: 30)
                                                .mask(FadeMask())
                                            if index == 1 || index == 3 {
                                                Text(":")
                                                    .font(.system(size: 30, weight: .bold).monospacedDigit())
                                            }
                                        }
                                    }
                                    .foregroundStyle(themeManager.timerColor)
                                    //.frame(width: 250, height: 70)
                                    .frame(maxWidth: .infinity)
                                    
                                    HStack(spacing: 0) {
                                        ForEach(0..<breakDigits.count, id: \.self) { index in
                                            RollingDigit(digit: breakDigits[index])
                                                .frame(width: 9, height: 14)
                                                .mask(FadeMask())
                                            if index == 1 || index == 3 {
                                                Text(":")
                                                    .font(.system(size: 12, weight: .bold).monospacedDigit())
                                            }
                                        }
                                    }
                                    .foregroundStyle(themeManager.breaksColor)
                                    //.frame(width: 250, height: 70)
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom)
                                
                                    
                                } else {
                                    HStack(spacing: 0) {
                                        ForEach(0..<timeDigits.count, id: \.self) { index in
                                            RollingDigit(digit: timeDigits[index])
                                                .frame(width: 20, height: 30)
                                                .mask(FadeMask())
                                            if index == 1 || index == 3 {
                                                Text(":")
                                                    .font(.system(size: 30, weight: .bold).monospacedDigit())
                                            }
                                        }
                                    }
                                    .foregroundStyle(themeManager.timerColor)
                                    //.frame(width: 250, height: 70)
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom)
                                }
                                
                            
                            
                            
                            
                        }
                    }
                
                // WIP
                
               TagButtonView().environmentObject(temporaryViewModel)
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                
                    .onAppear {
                        
                        
                        temporaryViewModel.selectedTags = Set(shift.tags?.compactMap { ($0 as? Tag)?.tagID } ?? [])
                        
                        
                    }
                
            }.listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            
            
            Section{
                VStack{
                    VStack(alignment: .leading){
                        Text("Start:")
                            .bold()
                        //.padding(.horizontal, 15)
                            .padding(.vertical, 5)
                        
                        DatePicker("Start: ", selection: $selectedStartDate)
                            .labelsHidden()
                            .onChange(of: selectedStartDate) { _ in
                                if selectedStartDate > selectedEndDate {
                                    selectedStartDate = selectedEndDate
                                }
                                //shift.shiftStartDate = selectedStartDate
                                //saveContext() // Save the value of tax percent whenever it changes
                            }
                            .disabled(!isEditing)
                            .onAppear {
                                noteIsFocused = false // Dismiss the text editor when the picker appears
                            }
                            .scaleEffect(isEditing ? 1.01 : 1.0) // Add a scale effect that pulses the picker
                            .animation(.easeInOut(duration: 0.2))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color("SquaresColor"),in:
                                            RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    VStack(alignment: .leading){
                        Text("End:")
                            .bold()
                        //.padding(.horizontal, 15)
                            .padding(.vertical, 5)
                        
                        DatePicker("", selection: $selectedEndDate)
                            .labelsHidden()
                            .onChange(of: selectedEndDate) { _ in
                                if selectedEndDate < selectedStartDate {
                                    selectedEndDate = selectedStartDate
                                }
                                //shift.shiftEndDate = selectedEndDate
                                //saveContext() // Save the value of tax percent whenever it changes
                            }.disabled(!isEditing)
                            .onAppear {
                                noteIsFocused = false // Dismiss the text editor when the picker appears
                            }
                            .scaleEffect(isEditing ? 1.01 : 1.0) // Add a scale effect that pulses the picker
                            .animation(.easeInOut(duration: 0.2)) // Add an animation modifier to create the pulse effect
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color("SquaresColor"),in:
                                            RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                    }
                }
            }.listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            Section{
                VStack(alignment: .leading) {
                    
                    Text("Hourly pay:")
                        .bold()
                    
                        .padding(.vertical, 5)
                    
                        .cornerRadius(20)
                    
                    
                    CurrencyTextField(placeholder: "Hourly Pay", text: $selectedHourlyPay)
                        .disabled(!isEditing)
                        .keyboardType(.decimalPad)
                        .focused($payIsFocused)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color("SquaresColor"),in:
                                        RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                }
                if shift.tax > 0 || taxEnabled {
                    
                    VStack(alignment: .leading){
                        Text("Estimated Tax")
                            .bold()
                            .padding(.vertical, 5)
                            .padding(.leading, -2)
                        Picker("Estimated tax:", selection: $selectedTaxPercentage) {
                            ForEach(Array(stride(from: 0, to: 50, by: 0.5)), id: \.self) { index in
                                Text(index / 100, format: .percent)
                            }
                        }.pickerStyle(.wheel)
                            .frame(maxHeight: 100)
                            .disabled(!isEditing)
                    }
                    .padding(.horizontal, 5)
                }
                
                if tipsEnabled || shift.totalTips > 0 {
                    VStack(alignment: .leading) {
                        
                        Text("Total tips:")
                            .bold()
                        
                            .padding(.vertical, 5)
                        
                            .cornerRadius(20)
                        
                        
                        CurrencyTextField(placeholder: "Total tips", text: $selectedTotalTips)
                            .disabled(!isEditing)
                            .keyboardType(.decimalPad)
                            .focused($payIsFocused)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color("SquaresColor"),in:
                                            RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        
                        
                    }
                    /*  Toggle(isOn: $addTipsToTotal) {
                     HStack {
                     Image(systemName: "chart.line.downtrend.xyaxis")
                     Spacer().frame(width: 10)
                     Text("Add tips to total pay")
                     }
                     }.toggleStyle(OrangeToggleStyle()) */
                    
                }
                VStack(alignment: .leading){
                    Text("Notes:")
                        .bold()
              
                        .padding(.vertical, 5)
            
                        .cornerRadius(20)
                    
                    TextEditor(text: $notes)
                    .disabled(!isEditing)
         
                        .focused($noteIsFocused)

                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color("SquaresColor"),in:
                                        RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                        .frame(minHeight: 200, maxHeight: .infinity)
                }
            }.listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            
            
            HStack{
                Text("Breaks:")
                    .bold()
                
                    .padding(.vertical, 5)
                Spacer()
                Button(action: {
                    isAddingBreak = true
                }) {
                    Image(systemName: "plus")
                        .bold()
                }.disabled(!isEditing)
            }.font(.title2)
                .padding(.horizontal, 5)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .sheet(isPresented: $isAddingBreak){
         
                    BreakInputView(newBreakStartDate: $selectedBreakStartDate, newBreakEndDate: $selectedBreakEndDate, isUnpaid: $isUnpaid, startDate: selectedStartDate, endDate: selectedEndDate, buttonAction: { breakManager.addBreak(oldShift: shift, startDate: selectedBreakStartDate, endDate: selectedBreakEndDate, isUnpaid: isUnpaid, context: context)
                        isAddingBreak = false})
                    
                    
                        .presentationDetents([ .fraction(0.45)])
                        .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
                        .presentationCornerRadius(35)
                }
            if let breaks = shift.breaks as? Set<Break> {
                let sortedBreaks = breaks.sorted { $0.startDate ?? Date() < $1.startDate ?? Date() }
                BreaksListView(breaks: sortedBreaks, isEditing: $isEditing, shift: shift)
            }
            
            Spacer()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .toolbar{
                    ToolbarItemGroup(placement: .keyboard){
                        Spacer()
                        
                        Button("Done"){
                            noteIsFocused = false
                            payIsFocused = false
                            shift.shiftNote = notes
                            //shift.tag = selectedTag
                            saveContext()
                        }
                    }
                }
            // }
            
        }
            .scrollContentBackground(.hidden)
            .listStyle(.inset)
        
            .onAppear {
                navigationState.gestureEnabled = false
            }
        //.padding(.horizontal, 30)
        
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "\(Image(systemName: "pencil"))") {
                        
                        let allBreaks = (shift.breaks?.allObjects as? [Break]) ?? []
                            let allBreaksAreWithin = allBreaks.allSatisfy {
                                $0.startDate! >= selectedStartDate && $0.endDate! <= selectedEndDate
                            }
                        
                        
                        if allBreaksAreWithin {
                            isEditing.toggle()
                            shift.shiftStartDate = selectedStartDate
                            shift.shiftEndDate = selectedEndDate
                            
                            
                            // ignore this block its old
                            shift.breakStartDate = selectedBreakStartDate
                            shift.breakEndDate = selectedBreakEndDate
                            
                            //
                            
                            shift.tax = selectedTaxPercentage
                            shift.hourlyPay = Double(selectedHourlyPay) ?? 0.0
                            //shift.tag = selectedTag
                            shift.totalTips = Double(selectedTotalTips) ?? 0.0
                            // this is old code....
                            
                            shift.duration = selectedEndDate.timeIntervalSince(selectedStartDate)
                            
                            
                            let unpaidBreaks = (shift.breaks?.allObjects as? [Break])?.filter { $0.isUnpaid == true } ?? []
                            let totalBreakDuration = unpaidBreaks.reduce(0) { $0 + $1.endDate!.timeIntervalSince($1.startDate!) }
                            let paidDuration = shift.duration - totalBreakDuration
                            shift.totalPay = (paidDuration / 3600.0) * shift.hourlyPay
                            
                            
                            shift.taxedPay = shift.totalPay - (shift.totalPay * shift.tax / 100.0)
                            saveContext()
                            breakManager.saveChanges(in: context)
                            
                        }
                        else {
                            
                            OkButtonPopup(title: "Saved breaks are not within the shift start and end dates.", action: nil).showAndStack()
                            
                        }
                        
                        
                        
                        
                    }.padding(.vertical)
                }
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        showingDeleteAlert = true
                        if presentedAsSheet{
                            dismiss()
                            
                            CustomConfirmationAlert(action: deleteShift, cancelAction: { activeSheet = .detailSheet}, title: "Are you sure you want to delete this shift?").showAndStack()
                            
                        }
                        else {
                            CustomConfirmationAlert(action: {
                                deleteShift()
                                dismiss()
                            }, cancelAction: nil, title: "Are you sure you want to delete this shift?").showAndStack()
                        }
                    }) {
                        Image(systemName: "trash")
                    }
                    .foregroundColor(.red)
                    .padding([.vertical, .trailing])
                    
                }
                if presentedAsSheet{
                    ToolbarItem(placement: .navigationBarLeading) {
                        CloseButton {
                            dismiss()
                        }
                    }
                }
            }
        
        
        
    }
    
    private func deleteShift() {
        context.delete(shift)
        saveContext()
        
    }
    
    // A date formatter to display the shift dates in a more readable format
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    
    private func shiftLengthString(shiftLength: TimeInterval) -> String {
        
        let hours = Int(shiftLength) / 3600
        let minutes = (Int(shiftLength) % 3600) / 60
        return String(format: "%1ih %02im", hours, minutes)
    }
    
    private func shiftDurationDouble() -> TimeInterval {
        guard let startDate = shift.shiftStartDate, let endDate = shift.shiftEndDate else {
            return 0.0
        }
        return endDate.timeIntervalSince(startDate)
    }
    
    private func saveContext() {
        do {
            try shift.managedObjectContext?.save()
        } catch let error {
            print("Error saving notes: \(error.localizedDescription)")
        }
    }
    
    
}
/*
struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var navigationState = NavigationState()
        let shift = OldShift(context: PersistenceController.preview.container.viewContext)
        shift.shiftNote = "Some notes"
        shift.taxedPay = 120.0
        shift.totalPay = 200.0
        shift.hourlyPay = 20.0
        shift.shiftStartDate = Date().addingTimeInterval(-3600)
        shift.shiftEndDate = Date()
        shift.duration = 53434.0
        shift.totalTips = 50.0
        
        return NavigationStack {
            DetailView(shift: shift, presentedAsSheet: false)
                .environmentObject(navigationState)
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} */

private extension TimeInterval {
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let hours = (time / 3600)
        let minutes = (time / 60) % 60
        let seconds = time % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}
