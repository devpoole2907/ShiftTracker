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
    
    @EnvironmentObject var jobSelectionManager: JobSelectionManager
    
    @EnvironmentObject var shiftStore: ShiftStore
    
    @FetchRequest(
           entity: Job.entity(),
           sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]
       ) private var jobs: FetchedResults<Job>
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var savedShift = false
    
    @Environment(\.requestReview) var requestReview
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    let breakManager = BreaksManager()
    
    @AppStorage("displayedCount") private var displayedCount: Int = 0
    
    var presentedAsSheet: Bool
    @State private var isEditJobPresented: Bool = false
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
            
            self._viewModel = StateObject(wrappedValue: DetailViewModel(selectedStartDate: newShiftStartDate, selectedEndDate: newShiftEndDate ?? Date(), selectedTaxPercentage: job.tax, selectedHourlyPay: "\(job.hourlyPay)", shiftID: UUID(), isEditing: true, job: job))
            
            
        }
        
        
        self.shift = shift
        
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
        
        ZStack(alignment: .bottomLeading){
            ZStack(alignment: .bottomTrailing){
                List{
                    Section{
                        
                        VStack{
                            
                            
                            
                            if !viewModel.areAllTempBreaksWithin {
                                HStack {
                                    
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("Breaks are not within the shift start & end dates.").bold()
                                        .roundedFontDesign()
                                    
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
                                                .roundedFontDesign()
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
                                                .roundedFontDesign()
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
                                             
                                             ((shift != nil && shift?.breaks != nil && viewModel.totalBreakDuration(for: shift!.breaks as! Set<Break>) > 0) || viewModel.totalTempBreakDuration(for: viewModel.tempBreaks) > 0) ? 0 : 20
                                             
                                             
                                    )
                                    
                                    
                                    
                                    
                                    
                                    
                                    if viewModel.totalTempBreakDuration(for: viewModel.tempBreaks) > 0 || (shift != nil && shift?.breaks != nil && viewModel.totalBreakDuration(for: shift!.breaks as! Set<Break>) > 0) {
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
                            
                            
                            
                        }
                        
                        
                        
                        VStack{
                            VStack(spacing: 0){
                                HStack{
                                    Text("Start")
                                        .bold()
                                    
                                    
                                    
                                        .frame(width: 50)
                                    
                                    Divider().frame(height: 10)
                                    
                                    Spacer()
                                    
                                    DatePicker("Start: ", selection: $viewModel.selectedStartDate)
                                        .labelsHidden()
                                        .onChange(of: viewModel.selectedStartDate) { _ in
                                            if viewModel.selectedStartDate > viewModel.selectedEndDate {
                                                viewModel.selectedStartDate = viewModel.selectedEndDate
                                            }
                                            
                                        }
                                        .disabled(!viewModel.isEditing)
                                        .scaleEffect(viewModel.isEditing ? 1.01 : 1.0)
                                        .animation(.easeInOut(duration: 0.2))
                                    
                                }.padding(.horizontal)
                                    .frame(height: 45)
                                
                                HStack{
                                    Text("End")
                                        .bold()
                                    
                                        .frame(width: 50)
                                    
                                    Divider().frame(height: 10)
                                    
                                    Spacer()
                                    
                                    DatePicker("", selection: $viewModel.selectedEndDate)
                                        .labelsHidden()
                                        .onChange(of: viewModel.selectedEndDate) { _ in
                                            if viewModel.selectedEndDate < viewModel.selectedStartDate {
                                                viewModel.selectedEndDate = viewModel.selectedStartDate
                                            }
                                            
                                        }.disabled(!viewModel.isEditing)
                                        .scaleEffect(viewModel.isEditing ? 1.01 : 1.0)
                                        .animation(.easeInOut(duration: 0.2))
                                    
                                    
                                }.padding(.horizontal)
                                    .frame(height: 45)
                            }   .glassModifier(cornerRadius: 20)
                                .padding(.bottom, 5)
                            
                            HStack {
                                
                                Text("Hourly Pay")
                                    .bold()
                                
                                    .padding(.vertical, 5)
                                
                                    .frame(width: 120, alignment: .leading)
                                
                                
                                
                                Divider().frame(height: 10)
                                
                                Spacer()
                                
                                CurrencyTextField(placeholder: "Hourly Pay", text: $viewModel.selectedHourlyPay)
                                    .disabled(!viewModel.isEditing)
                                    .focused($focusedField, equals: .field1)
                                    .keyboardType(.decimalPad)
                                
                                    .padding(.vertical, 10)
                                
                                    .multilineTextAlignment(.trailing)
                   
                                
                                
                            }     .padding(.horizontal)
                                .frame(height: 45)
                                .glassModifier(cornerRadius: 16)
                            
                            HStack{
                                
                                Text("Pay Multiplier").lineLimit(1)
                                    .bold()
                                
                                    .padding(.vertical, 10)
                                    .frame(width: 120, alignment: .leading)
                                
                                
                                Divider().frame(height: 10)
                                
                                Spacer()
                                
                                Stepper(value: $viewModel.payMultiplier, in: 1.0...3.0, step: 0.05) {
                                    Text("x\(viewModel.payMultiplier, specifier: "%.2f")")
                                }.disabled(!viewModel.isEditing)
                                .onChange(of: viewModel.payMultiplier) { newMultiplier in
                                    viewModel.multiplierEnabled = newMultiplier > 1.0
                                }
                       
                                
                            } .padding(.horizontal)
                                .frame(height: 45)
                                .glassModifier(cornerRadius: 16)
                                .padding(.bottom, 5)
                            
                            if tipsEnabled || Double(viewModel.selectedTotalTips) ?? 0 > 0 {
                                
                         
                                    VStack{
                                        HStack {
                                            
                                            
                                            Text("Total Tips")
                                                .bold()
                                            
                                           
                                            
                                                .frame(width: 120, alignment: .leading)
                                            
                                            
                                            Divider().frame(height: 10)
                                            
                                            Spacer()
                                            
                                            CurrencyTextField(placeholder: "Total tips", text: $viewModel.selectedTotalTips)
                                                .disabled(!viewModel.isEditing)
                                                .focused($focusedField, equals: .field2)
                                                .keyboardType(.decimalPad)
                                            //  .padding(.horizontal)
                                                .padding(.vertical, 5)
                                                .multilineTextAlignment(.trailing)
                                            //  .frame(maxWidth: 70)
                                            //     .glassModifier(cornerRadius: 20)
                                            
                                            
                                            
                                        }
                                        
                                        Toggle(isOn: $viewModel.addTipsToTotal) {
                                            
                                            Text("Add to Total") .bold()
                                            
                                        }.toggleStyle(CustomToggleStyle())
                                            .disabled(!viewModel.isEditing)
                                        
                                    }.padding(.horizontal)
                                        .padding(.vertical)
                                        .glassModifier(cornerRadius: 20)
                                        .padding(.bottom, 10)
                                  
                                    
                                
                                
                                
                                
                             
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
                                        TimePicker(timeInterval: $viewModel.overtimeAppliedAfter)
                                            .frame(maxHeight: 75)
                                            .disabled(!viewModel.isEditing)
                                        
                                    }
                                    
                                }.padding(.horizontal)
                                    .padding(.vertical)
                                    .glassModifier(cornerRadius: 20)
                                    .padding(.bottom, 10)
                              
                                
                            }
                            
                            
                            
                            
                        }.padding(.horizontal, 10)
                        
                        
                        
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 0))
                    
                    
                    
                    
                    
                        .sheet(isPresented: $viewModel.isAddingBreak){
                            
                            if let shift = shift {
                                
                                BreakInputView(startDate: viewModel.selectedStartDate, endDate: viewModel.selectedEndDate, buttonAction: { breakManager.addBreak(oldShift: shift, startDate: viewModel.selectedBreakStartDate, endDate: viewModel.selectedBreakEndDate, isUnpaid: viewModel.isUnpaid, context: viewContext)
                                    viewModel.isAddingBreak = false}).environmentObject(viewModel)
                                
                                
                                    .presentationDetents([ .fraction(0.35)])
                                    .customSheetRadius(35)
                                    .customSheetBackground()
                                
                            } else {
                                
                                BreakInputView(startDate: viewModel.selectedStartDate, endDate: viewModel.selectedEndDate, buttonAction: {
                                    let currentBreak = TempBreak(startDate: viewModel.selectedBreakStartDate, endDate: viewModel.selectedBreakEndDate, isUnpaid: viewModel.isUnpaid)
                                    viewModel.tempBreaks.append(currentBreak)
                                    viewModel.isAddingBreak = false
                                }).environmentObject(viewModel)
                                
                                
                                    .presentationDetents([ .fraction(0.35)])
                                    .customSheetRadius(35)
                                    .customSheetBackground()
                                
                                
                            }
                        }
                    
                    if let shift = shift {
                        
                        BreaksListView(shift: shift).environmentObject(viewModel)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        
                        
                    } else {
                        BreaksListView().environmentObject(viewModel)
                            .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 0))
                    }
                    
                    Spacer(minLength: 100)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    
                } .scrollContentBackground(.hidden)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                
                  
                
                    .background {
                        if !presentedAsSheet {
                            themeManager.overviewDynamicBackground.ignoresSafeArea()
                        } else {
                            Color.clear.ignoresSafeArea()
                        }
                       
                    }
                
                    .customSectionSpacing()
                
                
                
                HStack(alignment: .center){
                    
                    if shift != nil {
                        
                        Menu {
                            
                            Button(action: {
                                isEditJobPresented.toggle()
                            }){
                                HStack{
                                    Image(systemName: "pencil")
                                    Text("Edit Job")
                                }
                            }
                            
                            Menu {
                                
                                ForEach(jobs, id: \.objectID) { job in
                                    Button(action: {viewModel.job = job}) {
                                        HStack{
                                            Image(systemName: job.icon ?? "briefcase.circle")
                                            Text(job.name ?? "Unknown")
                                        }.tag(job)
                                    }
                                    
                                    
                                }
                                
                            } label: {
                                Text("Change Job")
                            }
                            
                          
                            
                                        
                                        } label: {
                                            JobForShiftView().frame(maxWidth: 250).frame(height: 25)
                                                .environmentObject(viewModel)
                                        }.allowsHitTesting(viewModel.isEditing)
                        
                     
                    } else {
                        JobForShiftView().frame(maxWidth: 250).frame(height: 25)
                            .environmentObject(viewModel)
                    }
                    
                    
                    
                    
                      
                    
                    Spacer()
                VStack{
                    if let shift = shift {
                        HStack(spacing: 10){
                            if viewModel.isEditing {
                                
                                Button(action: {
                                    
                                    viewModel.saveShift(shift, in: viewContext)
                                    
                                    savedShift = true
                                    
                                    if viewModel.job != viewModel.originalJob {
                                        // if the job has been changed, dismiss the view then change selected job to the new one
                                        
                                        withAnimation {
                                            dismiss()
                                            
                                            guard let job = viewModel.job else { return }
                                            
                                            CustomConfirmationAlert(action: {
                                                
                                                jobSelectionManager.selectJob(job, with: jobs, shiftViewModel: ContentViewModel.shared)
                                                
                                            }, cancelAction: nil, title: "Switch to this job?").showAndStack()
                                            
                                           
                                            
                                        }
                                        
                                    }
                                    
                                    
                                }) {
                                    Text("Done").bold()
                                }
                                
                            } else {
                                Button(action: {
                                    withAnimation {
                                        viewModel.isEditing = true
                                    }
                                }) {
                                    
                                    Image(systemName: "pencil").bold().customAnimatedSymbol(value: $viewModel.isEditing)
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
                                    dismiss()
                                    
                                }, cancelAction: { presentedAsSheet ? activeSheet = .detailSheet : nil}, title: "Are you sure you want to delete this shift?").showAndStack()
                                
                                
                                
                            }) {
                                Image(systemName: "trash").customAnimatedSymbol(value: $viewModel.showingDeleteAlert)
                                    .bold()
                            }
                            .tint(.red)
                            
                            
                        }
                    } else {
                        Button(action: {
                            
                            if let job = viewModel.job {
                                viewModel.addShift(in: viewContext, with: shiftStore, job: job)
                            } else {
                                dismiss()
                                OkButtonPopup(title: "Error adding shift.").showAndStack()
                                
                            }
                            
                            
                            dismiss()
                        }) {
                            Image(systemName: "folder.badge.plus")
                                .bold()
                    
                        }
                        .disabled(viewModel.totalPay <= 0 || !viewModel.areAllTempBreaksWithin)
                    }
                    
                }.padding()
                    .glassModifier(cornerRadius: 20)
                
                    .frame(height: 25)
                
            }
                
                .padding()
                .padding(.bottom)
                
                .fullScreenCover(isPresented: $isEditJobPresented) {
                    JobView(job: viewModel.job, isEditJobPresented: $isEditJobPresented, selectedJobForEditing: $viewModel.job).environmentObject(ContentViewModel.shared)
                 
                        .customSheetBackground()
                   
                }
               
                
            }
            
         
            
            
     
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseButton {
                        dismiss()
                    }
                }
            }
        }
        
        
        
    }
    
}


struct JobForShiftView: View {
    
    @EnvironmentObject var viewModel: DetailViewModel
    
    var job: Job? = nil // used for when this view is displayed in the createshiftform where detailviewmodel isnt in the environment
    
    var body: some View {
        let jobData = job ?? viewModel.job ?? viewModel.shift?.job
        HStack{
            VStack(alignment: .leading, spacing: 2) {
                
                if let job = jobData {
                    let jobColor = Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue))
                    HStack{
                        
                        JobIconView(icon: job.icon ?? "", color: jobColor, font: .subheadline)
                        
                        
                    
                        
                        VStack(alignment: .leading, spacing: 3){
                            Text(job.name ?? "No Job Found")
                                .bold()
                                .font(.subheadline)
                                .roundedFontDesign()
                            
                            Divider().frame(maxWidth: 300)
                            
                            
                            Text(job.title ?? "No Job Title")
                                .foregroundStyle(jobColor.gradient)
                                .roundedFontDesign()
                                .bold()
                                .font(.caption)
                                .padding(.leading, 1.4)
                        }
                    }.padding(.vertical, 2)
                }
                
                
            }.frame(maxWidth: .infinity)
            Spacer()
        }
        
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
            .glassModifier(cornerRadius: 20)
    }
    
}
