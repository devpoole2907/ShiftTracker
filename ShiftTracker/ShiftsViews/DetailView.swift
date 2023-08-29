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
import StoreKit

struct DetailView: View {
    
    @StateObject var viewModel: DetailViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // we need to fire this when we save a shift, as that will tell shiftslist to update sorts when a shift is saved
    @EnvironmentObject var savedPublisher: ShiftSavedPublisher
    
    @EnvironmentObject var shiftStore: ShiftStore
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var savedShift = false
    
    @Environment(\.requestReview) var requestReview
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    let breakManager = BreaksManager()
    
    @AppStorage("displayedCount") private var displayedCount: Int = 0
    
    var presentedAsSheet: Bool
    @Binding var activeSheet: ActiveSheet?
    
    @Binding var navPath: NavigationPath

    
    @FocusState private var focusedField: Field?
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    
    
    
    @AppStorage("TipsEnabled") private var tipsEnabled: Bool = true
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    

    
    var shift: OldShift?
    var job: Job?
    var dateSelected: DateComponents?
    
    init(shift: OldShift? = nil, job: Job? = nil, dateSelected: DateComponents? = nil, presentedAsSheet: Bool = false, activeSheet: Binding<ActiveSheet?>? = nil, navPath: Binding<NavigationPath> = .constant(NavigationPath())) {
        
        self._viewModel = StateObject(wrappedValue: DetailViewModel())
        
        if let shift = shift {
            
            self._viewModel = StateObject(wrappedValue: DetailViewModel(shift: shift))
            
        } else if let job = job {
            let calendar = Calendar.current
            var newShiftStartDate = Date()
            var newShiftEndDate = calendar.date(byAdding: .hour, value: 8, to: Date())
            
            if let dateSelected = dateSelected {
                newShiftStartDate = dateSelected.date ?? Date()
                newShiftEndDate = calendar.date(byAdding: .hour, value: 8, to: dateSelected.date ?? Date())
                
            }
            
            self._viewModel = StateObject(wrappedValue: DetailViewModel(selectedStartDate: newShiftStartDate, selectedEndDate: newShiftEndDate ?? Date(), selectedTaxPercentage: job.tax, selectedHourlyPay: "\(job.hourlyPay)", shiftID: UUID(), isEditing: true))
            
            
        }
        
        
        self.shift = shift
        
        self.job = job
        self.dateSelected = dateSelected
        
        self.presentedAsSheet = presentedAsSheet
        _activeSheet = activeSheet ?? Binding.constant(nil)
        _navPath = navPath
        
        
        
        
        // adds clear text button to text fields
        UITextField.appearance().clearButtonMode = .whileEditing
        
    }
    
    private let lightGradientColors = [
        Color.white.opacity(0.3),
        Color.white.opacity(0.1),
        Color.white.opacity(0.1),
        Color.white.opacity(0.4),
        Color.white.opacity(0.5),
    ]
    
    private let darkGradientColors = [
        Color.gray.opacity(0.2),
        Color.gray.opacity(0.1),
        Color.gray.opacity(0.1),
        Color.gray.opacity(0.3),
        Color.gray.opacity(0.2),
    ]
    
    
    var body: some View {
        
        var timeDigits = digitsFromTimeString(timeString: viewModel.adaptiveShiftDuration.stringFromTimeInterval())
        var breakDigits = shift != nil ? digitsFromTimeString(timeString: viewModel.totalBreakDuration(for: (shift!.breaks as? Set<Break> ?? Set<Break>())).stringFromTimeInterval()) : digitsFromTimeString(timeString: viewModel.totalTempBreakDuration(for: viewModel.tempBreaks).stringFromTimeInterval())
        
        let gradientColors = colorScheme == .dark ? darkGradientColors : lightGradientColors
        
        
        ZStack(alignment: .bottomTrailing){
            List{
                Section{
                    
                    VStack{
                        
                        
                        
                        if !viewModel.areAllTempBreaksWithin {
                            HStack {
                                
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Breaks are not within the shift start & end dates.").bold().fontDesign(.rounded)
                                
                            }
                            .padding()
                            .glassModifier(cornerRadius: 20)
                            .frame(width: UIScreen.main.bounds.width - 60)
                            
                        }
                        
                        
                        ZStack{
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Material.ultraThinMaterial)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                                .overlay {
                                    //if colorScheme == .light {
                                        RoundedRectangle(cornerRadius: 12)
                                         .stroke(LinearGradient(colors: gradientColors,
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                                   // }
                                }
                                .frame(width: UIScreen.main.bounds.width - 60)
                            VStack(alignment: .center, spacing: 5) {
                                
                                VStack {
                                    Text("\(currencyFormatter.string(from: NSNumber(value: viewModel.totalPay)) ?? "")")
                                        .padding(.horizontal, 20)
                                        .font(.system(size: 60).monospacedDigit())
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                    
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top)
                                HStack(spacing: 10){
                                    if viewModel.selectedTaxPercentage > 0 {
                                        HStack(spacing: 2){
                                            Image(systemName: "chart.line.downtrend.xyaxis")
                                                .font(.system(size: 15).monospacedDigit())
                                            
                                            Text("\(currencyFormatter.string(from: NSNumber(value: viewModel.taxedPay)) ?? "")")
                                                .font(.system(size: 20).monospacedDigit())
                                                .bold()
                                                .lineLimit(1)
                                                .allowsTightening(true)
                                        }.foregroundStyle(themeManager.taxColor)
                                            .fontDesign(.rounded)
                                    }
                                    if Double(viewModel.selectedTotalTips) ?? 0 > 0 {
                                        HStack(spacing: 2){
                                            Image(systemName: "chart.line.uptrend.xyaxis")
                                                .font(.system(size: 15).monospacedDigit())
                                            
                                            Text("\(currencyFormatter.string(from: NSNumber(value: Double(viewModel.selectedTotalTips) ?? 0)) ?? "")")
                                                .font(.system(size: 20).monospacedDigit())
                                                .bold()
                                                .lineLimit(1)
                                        }.foregroundStyle(themeManager.tipsColor)
                                            .fontDesign(.rounded)
                                    }
                                }
                                
                                .padding(.horizontal, 20)
                                
                                
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 5)
                                
                                // }
                                
                                Divider().frame(maxWidth: 200)
                                
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
                                .padding(.bottom,
                                         
                                         ((shift != nil && viewModel.totalBreakDuration(for: shift!.breaks as! Set<Break>) > 0) || viewModel.totalTempBreakDuration(for: viewModel.tempBreaks) > 0) ? 0 : 20
                                         
                                         
                                )
                                
                                
                                
                                
                                
                                
                                if viewModel.totalTempBreakDuration(for: viewModel.tempBreaks) > 0 || (shift != nil && viewModel.totalBreakDuration(for: shift!.breaks as! Set<Break>) > 0) {
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
                                    
                                    
                                }
                                
                                
                                
                                
                                
                            }
                        }
                        
                        TagPicker($viewModel.selectedTags).allowsHitTesting(viewModel.isEditing)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 5)
                        
                        HStack{
                            VStack(alignment: .leading, spacing: 2) {
                                
                                if let job = job ?? shift?.job {
                                    let jobColor = Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)).gradient
                                    HStack{
                                        Image(systemName: job.icon ?? "")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                            .padding(10)
                                            .background {
                                                
                                                Circle()
                                                    .foregroundStyle(jobColor)
                                                
                                                
                                            }
                                        
                                        VStack(alignment: .leading, spacing: 3){
                                            Text(job.name ?? "No Job Found")
                                                .bold()
                                                .font(.title2)
                                            
                                            Divider().frame(maxWidth: 300)
                                            
                                            
                                            Text(job.title ?? "No Job Title")
                                                .foregroundStyle(jobColor)
                                                .fontDesign(.rounded)
                                                .bold()
                                                .font(.callout)
                                                .padding(.leading, 1.4)
                                        }
                                    }.padding(.vertical, 2)
                                }
                                
                                
                            }.frame(maxWidth: .infinity)
                            Spacer()
                        }   .padding(.horizontal)
                            .padding(.vertical, 10)
                            .frame(width: UIScreen.main.bounds.width - 60)
                        
                            .glassModifier(cornerRadius: 20)
                        
                    }
                    
                    
                    
                    VStack{
                        VStack(alignment: .leading){
                            Text("Start")
                                .bold()
                                .padding(.horizontal)
                            //.padding(.horizontal, 15)
                                .padding(.vertical, 5)
                                .glassModifier(cornerRadius: 20)
                            
                            DatePicker("Start: ", selection: $viewModel.selectedStartDate)
                                .labelsHidden()
                                .onChange(of: viewModel.selectedStartDate) { _ in
                                    if viewModel.selectedStartDate > viewModel.selectedEndDate {
                                        viewModel.selectedStartDate = viewModel.selectedEndDate
                                    }
                                    //shift.shiftStartDate = selectedStartDate
                                    //saveContext() // Save the value of tax percent whenever it changes
                                }
                                .disabled(!viewModel.isEditing)
                                .scaleEffect(viewModel.isEditing ? 1.01 : 1.0) // Add a scale effect that pulses the picker
                                .animation(.easeInOut(duration: 0.2))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .glassModifier(cornerRadius: 20)
                        }
                        VStack(alignment: .leading){
                            Text("End")
                                .bold()
                                .padding(.horizontal)
                            //.padding(.horizontal, 15)
                                .padding(.vertical, 5)
                                .glassModifier(cornerRadius: 20)
                            
                            DatePicker("", selection: $viewModel.selectedEndDate)
                                .labelsHidden()
                                .onChange(of: viewModel.selectedEndDate) { _ in
                                    if viewModel.selectedEndDate < viewModel.selectedStartDate {
                                        viewModel.selectedEndDate = viewModel.selectedStartDate
                                    }
                                    //shift.shiftEndDate = selectedEndDate
                                    //saveContext() // Save the value of tax percent whenever it changes
                                }.disabled(!viewModel.isEditing)
                                .scaleEffect(viewModel.isEditing ? 1.01 : 1.0) // Add a scale effect that pulses the picker
                                .animation(.easeInOut(duration: 0.2)) // Add an animation modifier to create the pulse effect
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .glassModifier(cornerRadius: 20)
                            
                        }
                    }.padding(.horizontal)
                    
                    VStack{
                        VStack(alignment: .leading) {
                            
                            Text("Hourly Pay")
                                .bold()
                            
                                .padding(.vertical, 5)
                                .padding(.horizontal)
                                .glassModifier(cornerRadius: 20)
                            
                            
                            CurrencyTextField(placeholder: "Hourly Pay", text: $viewModel.selectedHourlyPay)
                                .disabled(!viewModel.isEditing)
                                .focused($focusedField, equals: .field1)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .glassModifier(cornerRadius: 20)
                            
                        }
                        if viewModel.selectedTaxPercentage > 0 || taxEnabled {
                            
                            VStack(alignment: .leading){
                                Text("Estimated Tax")
                                    .bold()
                                    .padding(.vertical, 5)
                                    .padding(.horizontal)
                                    .glassModifier(cornerRadius: 20)
                                    .padding(.leading, -3)
                                
                                Picker("Estimated tax:", selection: $viewModel.selectedTaxPercentage) {
                                    ForEach(Array(stride(from: 0, to: 50, by: 0.5)), id: \.self) { index in
                                        Text(index / 100, format: .percent)
                                    }
                                }.pickerStyle(.wheel)
                                    .frame(maxHeight: 100)
                                    .disabled(!viewModel.isEditing)
                                    .tint(Color("SquaresColor"))
                            }
                            .padding(.horizontal, 5)
                        }
                        
                        if tipsEnabled || Double(viewModel.selectedTotalTips) ?? 0 > 0 {
                            VStack(alignment: .leading) {
                                
                                Text("Total Tips")
                                    .bold()
                                
                                    .padding(.vertical, 5)
                                    .padding(.horizontal)
                                    .glassModifier(cornerRadius: 20)
                                
                                
                                CurrencyTextField(placeholder: "Total tips", text: $viewModel.selectedTotalTips)
                                    .disabled(!viewModel.isEditing)
                                    .focused($focusedField, equals: .field2)
                                    .keyboardType(.decimalPad)
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    .glassModifier(cornerRadius: 20)
                                
                                
                                
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
                            
                            Text("Pay Multiplier")
                                .bold()
                            
                                .padding(.vertical, 5)
                                .padding(.horizontal)
                                .glassModifier(cornerRadius: 20)
                            
                            Stepper(value: $viewModel.payMultiplier, in: 1.0...3.0, step: 0.05) {
                                Text("x\(viewModel.payMultiplier, specifier: "%.2f")")
                            }
                            .onChange(of: viewModel.payMultiplier) { newMultiplier in
                                viewModel.multiplierEnabled = newMultiplier > 1.0
                            }
                            
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .padding(.horizontal)
                            .glassModifier(cornerRadius: 20)
                            
                        }
                        
                        VStack(alignment: .leading){
                            Text("Notes")
                                .bold()
                            
                                .padding(.vertical, 5)
                                .padding(.horizontal)
                                .glassModifier(cornerRadius: 20)
                            
                            TextEditor(text: $viewModel.notes)
                                .disabled(!viewModel.isEditing)
                                .focused($focusedField, equals: .field3)
                            
                            
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .glassModifier(cornerRadius: 20)
                            
                                .frame(minHeight: 200, maxHeight: .infinity)
                        }
                        
                        VStack(alignment: .leading){
                            
                            Text("Overtime")
                                .bold()
                            
                                .padding(.vertical, 5)
                                .padding(.horizontal)
                                .glassModifier(cornerRadius: 20)
                            VStack{
                                Stepper(value: $viewModel.overtimeRate, in: 1.00...3, step: 0.25) {
                                    
                                    
                                    Text("Rate: \(viewModel.overtimeRate, specifier: "%.2f")x")
                                    
                                }
                                
                                HStack {
                                    
                                    
                                    
                                    Image(systemName: "calendar.badge.clock")
                                    Text("Applied after:")
                                    OvertimeView(overtimeAppliedAfter: $viewModel.overtimeAppliedAfter)
                                        .frame(maxHeight: 75)
                                        .disabled(!viewModel.isEditing)
                                    
                                }
                                
                            }.padding(.horizontal)
                                .padding(.vertical)
                                .glassModifier(cornerRadius: 20)
                            
                            
                               // .background(Color("SquaresColor"),in:
                                          //      RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            
                        }
                        
                    }.padding(.horizontal)
                    
                }.listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 0))
                
                
                
                
                
                    .sheet(isPresented: $viewModel.isAddingBreak){
                        
                        if let shift = shift {
                            
                            BreakInputView(startDate: viewModel.selectedStartDate, endDate: viewModel.selectedEndDate, buttonAction: { breakManager.addBreak(oldShift: shift, startDate: viewModel.selectedBreakStartDate, endDate: viewModel.selectedBreakEndDate, isUnpaid: viewModel.isUnpaid, context: viewContext)
                                viewModel.isAddingBreak = false}).environmentObject(viewModel)
                            
                            
                                .presentationDetents([ .fraction(0.35)])
                                .presentationBackground(.ultraThinMaterial)
                                .presentationCornerRadius(35)
                            
                        } else {
                            
                            BreakInputView(startDate: viewModel.selectedStartDate, endDate: viewModel.selectedEndDate, buttonAction: {
                                let currentBreak = TempBreak(startDate: viewModel.selectedBreakStartDate, endDate: viewModel.selectedBreakEndDate, isUnpaid: viewModel.isUnpaid)
                                viewModel.tempBreaks.append(currentBreak)
                                viewModel.isAddingBreak = false
                            }).environmentObject(viewModel)
                            
                            
                                .presentationDetents([ .fraction(0.35)])
                                .presentationBackground(.ultraThinMaterial)
                                .presentationCornerRadius(35)
                            
                            
                        }
                    }
                
                if let shift = shift {
                    
                    BreaksListView(shift: shift).environmentObject(viewModel)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    
                    
                } else {
                    BreaksListView().environmentObject(viewModel)
                        .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 0))
                }
                
                Spacer()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                
            } .scrollContentBackground(.hidden)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
       
                .background{
                    
                    if presentedAsSheet {
                        Color.clear.ignoresSafeArea()
                    } else {
                        Color(.systemGroupedBackground).ignoresSafeArea()
                    }
                   
                }
            
            
            
            VStack{
            if let shift = shift {
                HStack(spacing: 10){
                    if viewModel.isEditing {
                        
                        Button(action: {
                            
                            viewModel.saveShift(shift, in: viewContext)
                            
                            savedShift = true
                            
                        }) {
                            Text("Done").bold()
                        }
                        
                    } else {
                        Button(action: {
                            withAnimation {
                                viewModel.isEditing = true
                            }
                        }) {
                            
                            Image(systemName: "pencil").bold()
                        }
                    }
                    
                    Divider().frame(height: 10)
                    
                    Button(action: {
                        viewModel.showingDeleteAlert = true
                        if presentedAsSheet{
                            dismiss()
                        }
                        
                        CustomConfirmationAlert(action: {
                            shiftStore.deleteOldShift(shift, in: viewContext)
                        }, cancelAction: { presentedAsSheet ? activeSheet = .detailSheet : nil}, title: "Are you sure you want to delete this shift?").showAndStack()
                        
                        
                        
                    }) {
                        Image(systemName: "trash")
                            .bold()
                    }
                    .foregroundColor(.red)
                    
                    
                }
            } else {
                Button(action: {
                    
                    if let job = job {
                        viewModel.addShift(in: viewContext, with: shiftStore, job: job)
                    } else {
                        dismiss()
                        OkButtonPopup(title: "Error adding shift.").showAndStack()
                        
                    }
                    
                    
                    dismiss()
                }) {
                    Image(systemName: "folder.badge.plus")
                        .bold()
                       // .padding()
                }
                .disabled(viewModel.totalPay <= 0 || !viewModel.areAllTempBreaksWithin)
            }
            
            }.padding()
                .glassModifier(cornerRadius: 20)
            
            .padding()
           // .shadow(radius: 3)
            
    }
        
        .navigationTitle(shift == nil ? "Add Shift" : "Shift Details")
        .navigationBarTitleDisplayMode(.inline)
        
        .onAppear{
            
            
            
            if presentedAsSheet {
                
                displayedCount += 1
                
                print("displayed count is: \(displayedCount)")
                if displayedCount == 2 {
                    
                    
                    requestReview()
                    
                    print("requested review")
                    
                    
                }
                
                
            }
            
            
        }
        
        
        
        .toolbar{
            ToolbarItemGroup(placement: .keyboard){
                Button(action: {
                    switch focusedField {
                    case .field1, .none:
                        focusedField = .field3
                    case .field2:
                        focusedField = .field1
                    case .field3:
                        focusedField = .field2
                    }
                }) {
                    Image(systemName: "chevron.up")
                        .bold()
                }
                Button(action: {
                    switch focusedField {
                    case .field1:
                        focusedField = .field2
                    case .field2:
                        focusedField = .field3
                    case .field3, .none:
                        focusedField = .field1
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .bold()
                }
                
                
                
                
                Spacer()
                
                Button("Done"){
                    
                    hideKeyboard()
                    
                }
            }
        }
        
        
        //.scrollContentBackground(.hidden)
        
        .customScrollBackgroundModifier()
        
        
        .toolbar {
            
        
            if presentedAsSheet{
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton {
                        dismiss()
                    }
                }
            }
        }
        
        
        
    }
    
}


