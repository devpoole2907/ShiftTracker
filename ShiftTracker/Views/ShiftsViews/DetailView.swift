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
    
    @StateObject var viewModel: DetailViewModel = DetailViewModel()
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) var requestReview
    
    @EnvironmentObject var jobSelectionManager: JobSelectionManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var shiftStore: ShiftStore
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var scrollManager: ScrollManager
    
    let breakManager = BreaksManager()

    @FetchRequest(
        entity: Job.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]
    ) private var jobs: FetchedResults<Job>
    @FetchRequest(sortDescriptors: []) private var tags: FetchedResults<Tag>
    
    
    @State private var savedShift = false
    
    @Binding var activeSheet: ActiveSheet?
    @Binding var navPath: NavigationPath
    @FocusState private var focusedField: Field?
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    var isContextPreview: Bool = false
    
    init(shift: OldShift? = nil, isContextPreview: Bool = false, isDuplicating: Bool = false, job: Job? = nil, dateSelected: DateComponents? = nil, presentedAsSheet: Bool = false, activeSheet: Binding<ActiveSheet?>? = nil, navPath: Binding<NavigationPath> = .constant(NavigationPath())) {
        
         //self._viewModel = StateObject(wrappedValue: DetailViewModel())
        
        if let shift = shift {
            
            
            if isDuplicating {
                // shift is being duplicated, not viewed
                
                // COME BACK AND ADJUST ME!! I need to be a new shift, so pass the variables individually because we dont want to be directly editing the shift passed as we normally would when presenting detail view
                
                if let job = shift.job { // perhaps show some kind of error if this fails
                    
                    print("duplicating in the initialiser")
                    self._viewModel = StateObject(wrappedValue: DetailViewModel(selectedStartDate: shift.shiftStartDate ?? Date(), selectedEndDate: shift.shiftEndDate ?? Date(), selectedTaxPercentage: shift.tax, selectedHourlyPay: "\(shift.hourlyPay)", selectedTotalTips: "\(shift.totalTips)", addTipsToTotal: shift.addTipsToTotal, payMultiplier: shift.payMultiplier, multiplierEnabled: shift.multiplierEnabled, notes: shift.shiftNote ?? "", selectedTags: shift.tags as? Set<Tag> ?? [], shiftID: UUID(), isEditing: true, job: job, presentedAsSheet: presentedAsSheet, breaks: shift.breaks as? Set<Break> ?? [], isDuplicating: true))
                    
                }
                
            } else {
                    self._viewModel = StateObject(wrappedValue: DetailViewModel(shift: shift, presentedAsSheet: presentedAsSheet))
            }
    
            
        } else if let job = job {
            let calendar = Calendar.current
            var newShiftStartDate = Date()
            var newShiftEndDate = calendar.date(byAdding: .hour, value: 8, to: Date())
            
            if let dateSelected = dateSelected {
                newShiftStartDate = dateSelected.date ?? Date()
                newShiftEndDate = calendar.date(byAdding: .hour, value: 8, to: dateSelected.date ?? Date())
                
            }
            
            self._viewModel = StateObject(wrappedValue: DetailViewModel(selectedStartDate: newShiftStartDate, selectedEndDate: newShiftEndDate ?? Date(), selectedTaxPercentage: job.tax, selectedHourlyPay: "\(job.hourlyPay)", shiftID: UUID(), isEditing: true, job: job, presentedAsSheet: presentedAsSheet))
            
            
        }

        _activeSheet = activeSheet ?? Binding.constant(nil)
        _navPath = navPath
        
        self.isContextPreview = isContextPreview
        
        
        
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
                        
                        statsPanel
                        
                        TagPicker($viewModel.selectedTags, from: tags).allowsHitTesting(viewModel.isEditing)
                            .padding(.horizontal, 15)
                            .padding(.top, 5)
                    }
                        
                       
                    VStack {
                        shiftDatePickers
                        
                        
                        payPanels
                        
                        if viewModel.tipsEnabled || Double(viewModel.selectedTotalTips) ?? 0 > 0 {
                            
                            tipsPanel
                            
                        }
                        
                        
                        
                        if viewModel.selectedTaxPercentage > 0 || viewModel.taxEnabled {
                            
                            EstTaxPicker(taxPercentage: $viewModel.selectedTaxPercentage, isEditing: $viewModel.isEditing)
                        }
                        
                        notesField
                        
                        overtimePanel.padding(.vertical, 5)
                        
                    }.padding(.top, 10)

             


                    
                  
                }.listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 10, bottom: 10, trailing: 10))


                    .sheet(isPresented: $viewModel.isAddingBreak){
                        
                        if let shift = viewModel.shift {
                            
                            BreakInputView(buttonAction: {
                                
                                viewModel.createBreak(oldShift: shift, context: viewContext)
                                
                             
                                viewModel.isAddingBreak = false
                                
                            }
                            ).environmentObject(viewModel)
                            
                            
                                .presentationDetents([ .fraction(0.35)])
                                .customSheetRadius(35)
                                .customSheetBackground()
                            
                        } else {
                            
                            BreakInputView(buttonAction: {
                                let currentBreak = TempBreak(startDate: viewModel.selectedBreakStartDate, endDate: viewModel.selectedBreakEndDate, isUnpaid: viewModel.isUnpaid)
                                viewModel.tempBreaks.append(currentBreak)
                                viewModel.isAddingBreak = false
                            }).environmentObject(viewModel)
                            
                            
                                .presentationDetents([ .fraction(0.35)])
                                .customSheetRadius(35)
                                .customSheetBackground()
                            
                            
                        }
                    }
                
                breaksList
                
                Spacer(minLength: 100)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                
            } .scrollContentBackground(.hidden)
               // .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
               
                .listStyle(.inset)
            
             
            
            
                .background {
                    if !viewModel.presentedAsSheet && colorScheme == .dark {
                        themeManager.overviewDynamicBackground.ignoresSafeArea()
                    } else {
                        Color.clear.ignoresSafeArea()
                    }
                    
                }
            
                .customSectionSpacing()
            
            
            
            floatingButtons
            
            
        }.ignoresSafeArea(.keyboard)
        

            .navigationTitle(viewModel.navTitle)
            .navigationBarTitleDisplayMode(.inline)
        
            .toolbar(.hidden, for: .tabBar)
        
            .onAppear{
                
                if viewModel.presentedAsSheet {
                    
                    viewModel.displayedCount += 1
                    
                    print("displayed count is: \(viewModel.displayedCount)")
                    if viewModel.displayedCount == 2 {
                        
                        
                        requestReview()
                        
                        print("requested review")
                        
                        
                    }
                    
                    
                } else {
                    // hide the bar bar, we arent a sheet (only if we're not a context menu preview)
                    
                    if !isContextPreview {
                        withAnimation {
                            navigationState.hideTabBar = true
                        }
                    }
                   
                }
                
                
            }
        
            .onDisappear {
                // only hide the tab bar if we arent a contetx menu preview otherwise the tab bar will re appear when pushing further into the preview/naving here via the preview
                if !isContextPreview {
                    withAnimation {
                        navigationState.hideTabBar = false
                    }
                }
            }
        
        
        
            .toolbar{
                ToolbarItemGroup(placement: .keyboard){
                    focusFieldButtons
                    KeyboardDoneButton()
                }
            }
        
            .customScrollBackgroundModifier()
        
        
            .toolbar {
                
                
                if viewModel.presentedAsSheet{
                    ToolbarItem(placement: .navigationBarTrailing) {
                        CloseButton()
                    }
                }
            }
        
        
        
    }
    
    // to switch between focused text fields
    
    var focusFieldButtons: some View {
        return Group { Button(action: {
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
        }
    }
    
    var statsPanel: some View {
        
        let timeDigits = digitsFromTimeString(timeString: viewModel.adaptiveShiftDuration.stringFromTimeInterval())
        let breakDigits = viewModel.shift != nil ? digitsFromTimeString(timeString: viewModel.totalBreakDuration(for: viewModel.breaks).stringFromTimeInterval()) : digitsFromTimeString(timeString: viewModel.totalTempBreakDuration(for: viewModel.tempBreaks).stringFromTimeInterval())
        
        let gradientColors = colorScheme == .dark ? darkGradientColors : lightGradientColors
        
        let textColor = colorScheme == .dark ? Color.white : Color.black
        
        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                .overlay {
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(LinearGradient(colors: gradientColors,
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing))
                    
                }
                .frame(width: UIScreen.main.bounds.width - 60)
            VStack(alignment: .center, spacing: 5) {
                
                VStack {
                    HStack(alignment: .center, spacing: 0) {
                        Text("\(currencyFormatter.string(from: NSNumber(value: viewModel.totalPay)) ?? "")")
                            .padding(.horizontal, 20)
                            .font(.system(size: 60).monospacedDigit())
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(textColor)
                    }
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                if viewModel.overtimeEnabled {
                    HStack(spacing: 20){
                        VStack(alignment: .center, spacing: 2){
                            Text("Original Pay").bold().multilineTextAlignment(.center)
                                .font(.footnote)
                                .foregroundStyle(.gray)
                    
                            Text("\(currencyFormatter.string(from: NSNumber(value: viewModel.originalPay)) ?? "")")
                                .font(.caption)
                                .foregroundStyle(textColor)
                         
                            
                            
                        }
                        
                        VStack(alignment: .center, spacing: 2){
                            Text("Overtime").bold()
                                .font(.footnote)
                                .foregroundStyle(.gray)
                              
                            Text("\(currencyFormatter.string(from: NSNumber(value: viewModel.overtimeEarnings)) ?? "")")
                                .font(.caption)
                                .foregroundStyle(textColor)
                              
                            
                            
                        }
                        
                        
                    }  .roundedFontDesign()
                       
                }
                if viewModel.selectedTaxPercentage > 0 || Double(viewModel.selectedTotalTips) ?? -1 > 0 {
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
                     if Double(viewModel.selectedTotalTips) ?? -1 > 0 {
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
                     }  .minimumScaleFactor(0.5)
                     
                     .padding(.horizontal, 20)
                     
                     
                     .frame(maxWidth: .infinity)
                     .padding(.vertical, 5)
                     
                }
                
                Divider().frame(maxWidth: 200).frame(maxHeight: 5)
                
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
                    
                    // This is the conditionally displayed multiplier text
                    if viewModel.multiplierEnabled {
                        
                        
                        MultiplierView(payMultiplier: $viewModel.payMultiplier)
                        
                    }
                    
                    
                }  
                .foregroundStyle(themeManager.timerColor)
                
                .frame(maxWidth: .infinity)
                .padding(.bottom,
                         
                         ((viewModel.shift != nil && viewModel.shift?.breaks != nil && viewModel.totalBreakDuration(for: viewModel.breaks) > 0) || viewModel.totalTempBreakDuration(for: viewModel.tempBreaks) > 0) ? 0 : 20
                         
                         
                )
                
                
                
                
                
                
                if viewModel.totalTempBreakDuration(for: viewModel.tempBreaks) > 0 || (viewModel.shift != nil && viewModel.shift?.breaks != nil && viewModel.totalBreakDuration(for: viewModel.breaks) > 0) {
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
                    
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    
                    
                }

            }
        }
    }
    
    var shiftDatePickers: some View {
        return  VStack(spacing: 0){
            HStack{
                Text("Start")
                    .bold()
                
                
                
                    .frame(width: 50)
                
                Divider().frame(height: 10)
                
                Spacer()
                
                DatePicker("Start: ", selection: $viewModel.selectedStartDate, in: .distantPast...Date().endOfDay)
                    .labelsHidden()
                    .onChange(of: viewModel.selectedStartDate) { _ in
                        
                        if viewModel.selectedEndDate > viewModel.selectedStartDate.addingTimeInterval(86400) || viewModel.selectedStartDate > viewModel.selectedEndDate {
                            viewModel.selectedEndDate = viewModel.selectedStartDate.addingTimeInterval(36400)
                        }
                    }
                    .disabled(!viewModel.isEditing)
                    .scaleEffect(viewModel.isEditing ? 1.01 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isEditing)
                
            }.padding(.horizontal)
                .frame(height: 45)
            
            HStack{
                Text("End")
                    .bold()
                
                    .frame(width: 50)
                
                Divider().frame(height: 10)
                
                Spacer()
                
                DatePicker("", selection: $viewModel.selectedEndDate, in: viewModel.selectedStartDate...viewModel.selectedStartDate.addingTimeInterval(86400))
                
         //       DatePicker("", selection: $viewModel.selectedEndDate)
                    .labelsHidden()
                    .onChange(of: viewModel.selectedEndDate) { endDate in
                        if endDate < viewModel.selectedStartDate {
                            viewModel.selectedEndDate = viewModel.selectedStartDate.addingTimeInterval(36400)
                        }

                    }.disabled(!viewModel.isEditing)
                    .scaleEffect(viewModel.isEditing ? 1.01 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isEditing)
                
                
            }.padding(.horizontal)
                .frame(height: 45)
        }   .glassModifier(cornerRadius: 20)
            .padding(.bottom, 5)
    }
    
    var payPanels: some View {
        Group {
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
            
        }
        
    }
    
    var tipsPanel: some View {
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
                
                    .padding(.vertical, 5)
                    .multilineTextAlignment(.trailing)
                
            }
            
            Toggle(isOn: $viewModel.addTipsToTotal) {
                
                Text("Add to Total") .bold()
                
            }.toggleStyle(CustomToggleStyle())
                .disabled(!viewModel.isEditing)
            
        }.padding(.horizontal)
            .padding(.top, 5)
            .padding(.bottom, 16)
            .glassModifier(cornerRadius: 20)
            .padding(.bottom, 10)
    }
    
    var notesField: some View {
        VStack(alignment: .leading){
            Text("Notes")
                .bold()
            
                .padding(.vertical, 5)
                .padding(.horizontal)
                .glassModifier(cornerRadius: 20)
            
            UIKitTextEditor(text: $viewModel.notes)
                .disabled(!viewModel.isEditing)
                .focused($focusedField, equals: .field3)
            
            
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 20)
            
                .frame(minHeight: 200, maxHeight: .infinity)
        }
    }
    
    var overtimePanel: some View {
        return OvertimePanel(enabled: $viewModel.overtimeEnabled, rate: $viewModel.overtimeRate, applyAfter: $viewModel.overtimeAppliedAfter) {
            // sheet action version for iOS 16.0:
            
            viewModel.showingOvertimeSheet.toggle()
            
            
        }.disabled(!viewModel.isEditing)
            .onChange(of: viewModel.overtimeEnabled) { value in
                   guard let overtimeTag = tags.first(where: { $0.name?.lowercased() == "overtime" }) else {
                       // overtime tag not found?
                       return
                   }
                   
                   if value {
                       viewModel.selectedTags.insert(overtimeTag)
                   } else {
                       viewModel.selectedTags.remove(overtimeTag)
                   }
               }
        
            .sheet(isPresented: $viewModel.showingOvertimeSheet) {
                TimePicker(timeInterval: $viewModel.overtimeAppliedAfter)
                    .environment(\.managedObjectContext, viewContext)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([ .fraction(0.4)])
            }
        
    }
    
    var breaksList: some View {
     
        BreaksListView(showRealBreaks: viewModel.shift != nil).environmentObject(viewModel)
            .listRowInsets(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
      /*  BreaksListView(shift: viewModel.shift)
              */
        
    }
    
    var floatingButtons: some View {
        HStack(alignment: .center){
            
            if viewModel.shift != nil {
                
                Menu {
                    
                    Button(action: {
                        viewModel.isEditJobPresented.toggle()
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
                if let shift = viewModel.shift {
                    HStack(spacing: 10){
                        if viewModel.isEditing {
                            
                            Button(action: {
                                
                                viewModel.saveShift(shift, in: viewContext, dismiss: dismiss, breakAction: {
                                    viewModel.presentedAsSheet ? activeSheet = .detailSheet : nil
                                })
                                
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
                            if viewModel.presentedAsSheet{
                                dismiss()
                            }
                            
                            CustomConfirmationAlert(action: {
                                shiftStore.deleteOldShift(shift, in: viewContext)
                                dismiss()
                                
                            }, cancelAction: { viewModel.presentedAsSheet ? activeSheet = .detailSheet : nil}, title: "Are you sure you want to delete this shift?").showAndStack()
                            
                            
                            
                        }) {
                            Image(systemName: "trash").customAnimatedSymbol(value: $viewModel.showingDeleteAlert)
                                .bold()
                        }
                        .tint(.red)
                        
                        
                    }
                } else {
                    Button(action: {
                        
                        if let job = viewModel.job {
                            viewModel.addShift(in: viewContext, with: shiftStore, job: job, dismiss: dismiss, breakAction: {
                                viewModel.presentedAsSheet ? activeSheet = .detailSheet : nil
                                viewModel.presentedAsSheet ? activeSheet = .detailSheet : nil
                            })
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
        
        .fullScreenCover(isPresented: $viewModel.isEditJobPresented) {
            JobView(job: viewModel.job, isEditJobPresented: $viewModel.isEditJobPresented, selectedJobForEditing: $viewModel.job).environmentObject(ContentViewModel.shared)
            
                .customSheetBackground()
            
        }
    }
    
    
}

