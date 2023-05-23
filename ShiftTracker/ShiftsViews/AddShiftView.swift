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
    @State private var hourlyPay: Double = 0.0
    @State private var taxedPay: Double = 0.0
    @State private var totalPay: Double = 0.0
    @State private var totalTips: Double = 0.0
    @State private var duration: Double = 0.0
    @State private var taxPercentage: Double = 0.0
    @State private var autoCalcPay: Bool = true
    
    @FocusState private var payIsFocused: Bool
    @FocusState private var tipIsFocused: Bool
    
    @AppStorage("TipsEnabled") private var tipsEnabled: Bool = true
    
    private func saveShift() {
        let newShift = OldShift(context: viewContext)
        newShift.shiftStartDate = shiftStartDate
        newShift.shiftEndDate = shiftEndDate
        newShift.breakStartDate = breakStartDate
        newShift.breakEndDate = breakEndDate
        newShift.hourlyPay = hourlyPay
        newShift.tax = taxPercentage
        newShift.totalTips = totalTips
        
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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Shift Details")) {
                    DatePicker("Start Date", selection: $shiftStartDate, displayedComponents: [.date, .hourAndMinute])
                        .onChange(of: shiftStartDate) { newValue in
                            if newValue > shiftEndDate {
                                shiftEndDate = newValue
                            }
                        }
                    DatePicker("End Date", selection: $shiftEndDate, displayedComponents: [.date, .hourAndMinute])
                        .onChange(of: shiftEndDate) { newValue in
                            if newValue < shiftStartDate {
                                shiftStartDate = newValue
                            }
                        }
                    HStack{
                        Text("Hourly Pay:")
                        Spacer()
                        TextField("", value: $hourlyPay, formatter: NumberFormatter())
                            .frame(width: 45, alignment: .trailing)
                            .focused($payIsFocused)
                    }
                    Picker("Estimated Tax: ", selection: $taxPercentage){
                        ForEach(Array(stride(from: 0, to: 50, by: 0.5)), id: \.self){ index in
                            Text(index/100, format: .percent)
                        }
                    }
                    if tipsEnabled {
                        HStack {
                            
                            Text("Total tips:")
                            //.foregroundColor(isEditing ? Color.black.opacity(0.8) : Color.white.opacity(0.5))
                            
                            TextField("", value: $totalTips, format: .currency(code: Locale.current.currency?.identifier ?? "NZD"))
                                .keyboardType(.decimalPad)
                                .focused($tipIsFocused)
                            //.foregroundColor(isEditing ? Color.white.opacity(0.8) : Color.white.opacity(0.5))
                            
                            
                        }
                    }
                }.listRowSeparator(.hidden)
                Section(header: Text("Pay Details")){
                    Toggle(isOn: $autoCalcPay){
                        HStack {

                            Text("Auto Calculate pay")
                        }
                    }
                    .toggleStyle(OrangeToggleStyle())
                    HStack{
                        Text("Total Pay:")
                        Spacer()
                        TextField("", value: $totalPay, formatter: NumberFormatter())
                            .frame(width: 45, alignment: .trailing)
                            
                    }.disabled(autoCalcPay)
                    HStack{
                        Text("Taxed Pay:")
                        Spacer()
                        TextField("", value: $taxedPay, formatter: NumberFormatter())
                            .frame(width: 45, alignment: .trailing)
                    }.disabled(autoCalcPay)
                }.listRowSeparator(.hidden)
                
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
                ToolbarItem{
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
                        saveShift()
                    }){
                    Image(systemName: "folder.badge.plus")
                    .bold()
                    .padding()
                    }
                    .disabled(hourlyPay <= 0 || (totalPay <= 0 && !autoCalcPay) || (taxedPay <= 0 && !autoCalcPay))
                }
                   
                
            }
        }
    }
}

struct AddShiftView_Previews: PreviewProvider {
    static var previews: some View {
        AddShiftView()
    }
}
