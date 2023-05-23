//
//  AddShiftView.swift
//  ShiftTracker
//
//  Created by James Poole on 1/04/23.
//

import SwiftUI

struct AddShiftView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    

    
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
    
    @FocusState private var payIsFocused: Bool
    @FocusState private var tipIsFocused: Bool
    @FocusState private var noteIsFocused: Bool
    
    @AppStorage("TipsEnabled") private var tipsEnabled: Bool = true
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    
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
        let hoursWorked = shiftDuration / 3600
        return hoursWorked * (Double(hourlyPay) ?? 0.0)
    }
    
    var taxedPay: Double {
        return totalPay - (totalPay * taxPercentage / 100.0)
    }
    
    private func saveShift() {
        let newShift = OldShift(context: viewContext)
        newShift.shiftStartDate = shiftStartDate
        newShift.shiftEndDate = shiftEndDate
        newShift.breakStartDate = breakStartDate
        newShift.breakEndDate = breakEndDate
        newShift.hourlyPay = Double(hourlyPay) ?? 0.0
        newShift.tax = taxPercentage
        newShift.totalTips = Double(totalTips) ?? 0.0
        
        if autoCalcPay {
            // review this, might not work correctly if no date is entered for breaks
            let newBreakElapsed = newShift.breakEndDate?.timeIntervalSince(newShift.breakStartDate ?? Date())
            newShift.duration = (newShift.shiftEndDate?.timeIntervalSince(newShift.shiftStartDate ?? Date()) ?? 0.0) - ( newBreakElapsed ?? 0.0)
            newShift.totalPay = (newShift.duration / 3600.0) * newShift.hourlyPay
            newShift.taxedPay = newShift.totalPay - (newShift.totalPay * newShift.tax / 100.0)
        }
        else {
            newShift.taxedPay = taxedPay
            newShift.totalPay = totalPay
        }
        
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
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
    }
    
    
    
    var body: some View {
        
        var timeDigits = digitsFromTimeString(timeString: shiftDuration.stringFromTimeInterval())
        
        NavigationStack {
            ZStack{
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
            Form {
                
                Section{
                    //  HStack{
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundColor(.primary.opacity(0.04))
                            .frame(width: UIScreen.main.bounds.width - 40)
                            .shadow(radius: 5, x: 0, y: 4)
                        VStack(alignment: .center, spacing: 5) {
                            VStack {
                                Text("\(currencyFormatter.string(from: NSNumber(value: taxedPay)) ?? "")")
                                //.foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .font(.system(size: 60).monospacedDigit())
                                    .fontWeight(.bold)
                                
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
                                    }
                                    
                                }
                                
                                
                                
                            }
                            
                            .padding(.horizontal, 20)
                            
                            
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 5)
                            
                            // }
                            
                            Divider().frame(maxWidth: 200)
                            
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
                                        shiftStartDate = shiftEndDate
                                    }
                                }
                                .onAppear {
                                    //  noteIsFocused = false // Dismiss the text editor when the picker appears
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color.primary.opacity(0.04),in:
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
                                .background(Color.primary.opacity(0.04),in:
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
                            .focused($payIsFocused)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color.primary.opacity(0.04),in:
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
                                .background(Color.primary.opacity(0.04),in:
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
                        
                        //.textFieldStyle(PlainTextFieldStyle())
                            .focused($noteIsFocused)
                        //.padding()
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color.primary.opacity(0.04),in:
                                            RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        
                        
                            .frame(minHeight: 200, maxHeight: .infinity)
                    }
                }.listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                
                
                /*   Section(header: Text("Break Details")) {
                 DatePicker("Break Start", selection: $breakStartDate, displayedComponents: [.date, .hourAndMinute])
                 .onChange(of: breakStartDate) { newValue in
                 if newValue < shiftStartDate {
                 breakStartDate = shiftStartDate
                 } else if newValue > shiftEndDate {
                 breakStartDate = shiftEndDate
                 }
                 }
                 DatePicker("Break End", selection: $breakEndDate, displayedComponents: [.date, .hourAndMinute])
                 .onChange(of: breakEndDate) { newValue in
                 if newValue < breakStartDate {
                 breakEndDate = breakStartDate
                 } else if newValue > shiftEndDate {
                 breakEndDate = shiftEndDate
                 }
                 }
                 }.listRowSeparator(.hidden) */
            }.scrollContentBackground(.hidden)
        }
            .toolbar{
                ToolbarItemGroup(placement: .keyboard){
                    Spacer()
                    
                    Button("Done"){
                        payIsFocused = false
                        tipIsFocused = false
                    }
                }
            }
            .navigationBarTitle("Add Shift", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading){
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .bold()
                            .padding()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveShift) {
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
