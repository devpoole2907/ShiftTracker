//
//  AddShiftView.swift
//  ShiftTracker
//
//  Created by James Poole on 1/04/23.
//

import SwiftUI


struct AddShiftView: View {
    
    let breaksManager = BreaksManager()
    
    @EnvironmentObject var shiftManager: ShiftDataManager
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var shiftStartDate = Date()
    @State private var shiftEndDate = Date()
    @State private var breakStartDate = Date()
    @State private var breakEndDate = Date()
    @State private var hourlyPay: String
    @State private var totalTips: String = ""
    @State private var notes: String = ""
    @State private var duration: Double = 0.0
    @State private var taxPercentage: Double
    @State private var autoCalcPay: Bool = true
    @State private var isAddingBreak = false
    
    var job: Job
    
    @FocusState private var payIsFocused: Bool
    @FocusState private var tipIsFocused: Bool
    @FocusState private var noteIsFocused: Bool
    
    @AppStorage("TipsEnabled") private var tipsEnabled: Bool = true
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    
    // breaks stuff
    @State private var tempBreaks: [TempBreak] = []
    @State private var newBreakStartDate = Date()
    @State private var newBreakEndDate = Date().addingTimeInterval(10 * 60)
    @State private var isUnpaid = false
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    var shiftDuration: TimeInterval {
        shiftEndDate.timeIntervalSince(shiftStartDate)
    }
    
    var totalPay: Double {
        let totalHoursWorked = shiftDuration / 3600 - totalBreakDuration(for: tempBreaks) / 3600
        return totalHoursWorked * (Double(hourlyPay) ?? 0.0)
    }
    
    var taxedPay: Double {
        return totalPay - (totalPay * taxPercentage / 100.0)
    }
    
    private func saveShift(job: Job) {
        let newShift = OldShift(context: viewContext)
        newShift.shiftStartDate = shiftStartDate
        newShift.shiftEndDate = shiftEndDate
        newShift.hourlyPay = Double(hourlyPay) ?? 0.0
        newShift.tax = taxPercentage
        newShift.totalTips = Double(totalTips) ?? 0.0
        newShift.shiftNote = notes
        
        
        newShift.duration = (newShift.shiftEndDate?.timeIntervalSince(newShift.shiftStartDate ?? Date()) ?? 0.0)
        
        let unpaidBreaks = (tempBreaks).filter { $0.isUnpaid == true }
        let totalBreakDuration = unpaidBreaks.reduce(0) { $0 + $1.endDate!.timeIntervalSince($1.startDate) }
        let paidDuration = newShift.duration - totalBreakDuration
        newShift.totalPay = (paidDuration / 3600.0) * newShift.hourlyPay
        newShift.taxedPay = newShift.totalPay - (newShift.totalPay * newShift.tax / 100.0)
        
        newShift.job = job
        
        for tempBreak in tempBreaks {
            if let breakEndDate = tempBreak.endDate {
                breaksManager.createBreak(oldShift: newShift, startDate: tempBreak.startDate, endDate: breakEndDate, isUnpaid: tempBreak.isUnpaid, in: viewContext)
            }
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving new shift: \(error)")
        }
    }
    
    private func digitsFromTimeString(timeString: String) -> [Int] {
        return timeString.flatMap { char in
            if let digit = Int(String(char)) {
                return [digit]
            } else {
                return []
            }
        }
    }
    
    
    init(job: Job){
        _hourlyPay = State(initialValue: "\(job.hourlyPay)")
        _taxPercentage = State(initialValue: job.tax)
        self.job = job
        
        
        // adds clear text button to text fields
        UITextField.appearance().clearButtonMode = .whileEditing
        
    }
    
    func totalBreakDuration(for tempBreaks: [TempBreak]) -> TimeInterval {
        let unpaidBreaks = tempBreaks.filter { $0.isUnpaid == true }
        let totalDuration = unpaidBreaks.reduce(0) { (sum, breakItem) -> TimeInterval in
            let breakDuration = breakItem.endDate?.timeIntervalSince(breakItem.startDate)
            return sum + (breakDuration ?? 0)
        }
        return totalDuration
    }
    
    
    
    var body: some View {
        
        var timeDigits = digitsFromTimeString(timeString: shiftDuration.stringFromTimeInterval())
        var breakDigits = digitsFromTimeString(timeString: totalBreakDuration(for: tempBreaks).stringFromTimeInterval())
        
        NavigationStack {
            ZStack{
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                Form {
                    
                    Section{
                        //  HStack{
                        
                        ZStack{
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(Color("SquaresColor"))
                                .frame(width: UIScreen.main.bounds.width - 40)
                                .shadow(radius: 5, x: 0, y: 4)
                            VStack(alignment: .center, spacing: 5) {
                                VStack {
                                    Text("\(currencyFormatter.string(from: NSNumber(value: taxedPay)) ?? "")")
                                    //.foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .font(.system(size: 60).monospacedDigit())
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                    
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top)
                                
                                
                                HStack(spacing: 10){
                                    if taxPercentage > 0 {
                                        HStack(spacing: 2){
                                            Image(systemName: "chart.line.downtrend.xyaxis")
                                                .font(.system(size: 15).monospacedDigit())
                                                .fontWeight(.light)
                                                .foregroundColor(.pink)
                                            Text("\(currencyFormatter.string(from: NSNumber(value: totalPay)) ?? "")")
                                                .font(.system(size: 20).monospacedDigit())
                                                .bold()
                                                .foregroundColor(.pink)
                                                .lineLimit(1)
                                                .allowsTightening(true)
                                        }
                                    }
                                    if Double(totalTips) ?? 0 > 0 {
                                        HStack(spacing: 2){
                                            Image(systemName: "chart.line.uptrend.xyaxis")
                                                .font(.system(size: 15).monospacedDigit())
                                                .fontWeight(.light)
                                                .foregroundColor(.teal)
                                            Text("\(currencyFormatter.string(from: NSNumber(value: Double(totalTips) ?? 0)) ?? "")")
                                                .font(.system(size: 20).monospacedDigit())
                                                .bold()
                                                .foregroundColor(.teal)
                                                .lineLimit(1)
                                                .allowsTightening(true)
                                        }
                                        
                                    }
                                    
                                    
                                    
                                }
                                
                                .padding(.horizontal, 20)
                                
                                
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 5)
                                
                                // }
                                
                                Divider().frame(maxWidth: 200)
                                if totalBreakDuration(for: tempBreaks) > 0{
                                    HStack(spacing: 0) {
                                        ForEach(0..<timeDigits.count, id: \.self) { index in
                                            FuckingRollingDigitAgain(digit: timeDigits[index])
                                                .frame(width: 20, height: 30)
                                                .mask(AnotherFuckingFadeMaskBecauseXcodeIsGood())
                                            if index == 1 || index == 3 {
                                                Text(":")
                                                    .font(.system(size: 30, weight: .bold).monospacedDigit())
                                            }
                                        }
                                    }
                                    .foregroundColor(.orange)
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
                                    .foregroundColor(.indigo)
                                    //.frame(width: 250, height: 70)
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom)
                                    
                                } else {
                                    HStack(spacing: 0) {
                                        ForEach(0..<timeDigits.count, id: \.self) { index in
                                            FuckingRollingDigitAgain(digit: timeDigits[index])
                                                .frame(width: 20, height: 30)
                                                .mask(AnotherFuckingFadeMaskBecauseXcodeIsGood())
                                            if index == 1 || index == 3 {
                                                Text(":")
                                                    .font(.system(size: 30, weight: .bold).monospacedDigit())
                                            }
                                        }
                                    }
                                    .foregroundColor(.orange)
                                    //.frame(width: 250, height: 70)
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom)
                                }
                                
                                
                                
                                
                                
                            }
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
                                
                                DatePicker("Start: ", selection: $shiftStartDate)
                                    .labelsHidden()
                                    .onChange(of: shiftStartDate) { _ in
                                        if shiftStartDate > shiftEndDate {
                                            shiftEndDate = shiftStartDate
                                        }
                                    }
                                    .onAppear {
                                        //  noteIsFocused = false // Dismiss the text editor when the picker appears
                                    }
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
                                
                                DatePicker("", selection: $shiftEndDate)
                                    .labelsHidden()
                                    .onChange(of: shiftEndDate) { _ in
                                        if shiftEndDate < shiftStartDate {
                                            shiftEndDate = shiftStartDate
                                        }
                                    }
                                
                                    .onAppear {
                                        //noteIsFocused = false // Dismiss the text editor when the picker appears
                                    }
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
                            
                            
                            AFuckingCurrencyTextFieldBecauseLetsJustDuplicateBloodyCode(placeholder: "Hourly Pay", text: $hourlyPay)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color("SquaresColor"),in:
                                                RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            
                            
                            
                            
                            
                        }
                        if taxEnabled {
                            
                            VStack(alignment: .leading){
                                Text("Estimated Tax")
                                    .bold()
                                    .padding(.vertical, 5)
                                    .padding(.leading, -2)
                                Picker("Estimated tax:", selection: $taxPercentage) {
                                    ForEach(Array(stride(from: 0, to: 50, by: 0.5)), id: \.self) { index in
                                        Text(index / 100, format: .percent)
                                    }
                                }.pickerStyle(.wheel)
                                    .frame(maxHeight: 100)
                            }
                            .padding(.horizontal, 5)
                        }
                        
                        if tipsEnabled {
                            VStack(alignment: .leading) {
                                
                                Text("Total tips:")
                                    .bold()
                                
                                    .padding(.vertical, 5)
                                
                                    .cornerRadius(20)
                                
                                
                                AFuckingCurrencyTextFieldBecauseLetsJustDuplicateBloodyCode(placeholder: "Total tips", text: $totalTips)
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
                            //.padding(.horizontal, 15)
                                .padding(.vertical, 5)
                            //.background(Color.primary.opacity(0.04))
                                .cornerRadius(20)
                            
                            TextEditor(text: $notes)
                   
             
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
                        }
                    }.font(.title2)
                        .padding(.horizontal, 5)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .sheet(isPresented: $isAddingBreak){
                            
                            BreakInputView(newBreakStartDate: $newBreakStartDate, newBreakEndDate: $newBreakEndDate, isUnpaid: $isUnpaid, startDate: shiftStartDate, endDate: shiftEndDate, buttonAction: {
                                let currentBreak = TempBreak(startDate: newBreakStartDate, endDate: newBreakEndDate, isUnpaid: isUnpaid)
                                tempBreaks.append(currentBreak)
                                isAddingBreak = false
                            })
                                .presentationDetents([ .fraction(0.4)])
                                .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
                                .presentationCornerRadius(35)
                        }
                    TempBreaksListView(breaks: $tempBreaks)
                    /*   if let breaks = shift.breaks as? Set<Break> {
                     let sortedBreaks = breaks.sorted { $0.startDate ?? Date() < $1.startDate ?? Date() }
                     BreaksListView(breaks: sortedBreaks, isEditing: $isEditing, shift: shift)
                     }*/
                    
                    Spacer()
                        .listRowBackground(Color.clear)

                }.scrollContentBackground(.hidden)
                    .listStyle(.inset)
                
                
                    .toolbar{
                        ToolbarItemGroup(placement: .keyboard){
                            
                           
                            
                            Spacer()
                            
                            Button("Done"){
                                hideKeyboard()
                            }
                        }
                    }
                    
            }
            
            .navigationBarTitle("Add Shift", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading){
                    CloseButton {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveShift(job: job)
                        shiftManager.shiftAdded.toggle()
                        dismiss()
                    }) {
                        Image(systemName: "folder.badge.plus")
                            .bold()
                            .padding()
                    }
                    .disabled(totalPay <= 0)
                }
            }
            
            
            
            
            
        }
    }
    
    
    
    
}

struct AFuckingCurrencyTextFieldBecauseLetsJustDuplicateBloodyCode: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(Locale.current.currencySymbol ?? "")
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
        }
    }
}

struct AnotherFuckingFadeMaskBecauseXcodeIsGood: View {
    var body: some View {
        LinearGradient(gradient: Gradient(stops: [
            Gradient.Stop(color: Color.clear, location: 0),
            Gradient.Stop(color: Color.black, location: 0.1),
            Gradient.Stop(color: Color.black, location: 0.9),
            Gradient.Stop(color: Color.clear, location: 1),
        ]), startPoint: .top, endPoint: .bottom)
    }
}

struct FuckingRollingDigitAgain: View {
    let digit: Int
    @State private var shouldAnimate = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach((0...10), id: \.self) { index in
                    Text(index == 10 ? "0" : "\(index)")
                        .font(.system(size: geometry.size.height).monospacedDigit())
                        .bold()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .offset(y: -CGFloat(digit) * geometry.size.height)
            .animation(shouldAnimate ? .easeOut(duration: 0.2) : nil)
            .onAppear {
                shouldAnimate = true
            }
            .onDisappear {
                shouldAnimate = false
            }
        }
    }
}

private extension TimeInterval {
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let hours = (time / 3600)
        let minutes = (time / 60) % 60
        let seconds = time % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}
/*
 struct AddShiftView_Previews: PreviewProvider {
 static var previews: some View {
 AddShiftView()
 }
 }
 */


struct TempBreaksListView: View {
    @Binding var breaks: [TempBreak]
    
    let breakManager = BreaksManager()
    
    @State private var newBreakStartDate = Date()
    @State private var newBreakEndDate = Date()
    @State private var isUnpaid = false
    
    private func delete(at offsets: IndexSet) {
        breaks.remove(atOffsets: offsets)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy   h:mm a"
        return formatter.string(from: date)
    }
    
    
    var body: some View {
        ForEach(breaks, id: \.self) { breakItem in
            Section{
                VStack(alignment: .leading){
                    VStack(alignment: .leading, spacing: 8){
                        if breakItem.isUnpaid{
                            Text("Unpaid")
                                .font(.subheadline)
                                .foregroundColor(.indigo)
                                .bold()
                        }
                        else {
                            Text("Paid")
                                .font(.subheadline)
                                .foregroundColor(.indigo)
                                .bold()
                        }
                        Text("\(breakManager.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate))")
                            .listRowSeparator(.hidden)
                            .font(.subheadline)
                            .bold()
                    }
                    Divider()
                    HStack{
                        Text("Start:")
                            .bold()
                        //.padding(.horizontal, 15)
                            .frame(width: 50, alignment: .leading)
                            .padding(.vertical, 5)
                        
                        Text(formatDate(breakItem.startDate))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    HStack{
                        Text("End:")
                            .bold()
                            .frame(width: 50, alignment: .leading)
                        //.padding(.horizontal, 15)
                            .padding(.vertical, 5)
                        Text(formatDate(breakItem.endDate ?? Date()))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }.padding()
                    .background(Color("SquaresColor"),in:
                                    RoundedRectangle(cornerRadius: 12, style: .continuous))
                
            }.listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }.onDelete(perform: delete)
    }
}
