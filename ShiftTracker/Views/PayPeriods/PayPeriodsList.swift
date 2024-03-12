//
//  PayPeriodsList.swift
//  ShiftTracker
//
//  Created by James Poole on 10/03/24.
//

import SwiftUI

struct PayPeriodsList: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var payPeriodManager: PayPeriodManager
    
    @EnvironmentObject var shiftStore: ShiftStore
    @EnvironmentObject var overviewModel: JobOverviewViewModel
    @EnvironmentObject var scrollManager: ScrollManager
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    
    let shiftManager = ShiftDataManager()
    
    @FetchRequest var payPeriods: FetchedResults<PayPeriod>
    
    @State private var showCreateSheet = false
    @State private var showExportView = false
    @State private var showInvoiceView = false
    
    @State private var shiftsToExport: [OldShift]? = nil
    
    func loadShiftsToExport(payPeriod: PayPeriod) {
        
        
        
        shiftsToExport = payPeriod.shifts?.allObjects as? [OldShift] ?? []
        
    }
    
    init(job: Job) {
        let jobPredicate = NSPredicate(format: "job == %@", job)
        self._payPeriods = FetchRequest(
            entity: PayPeriod.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \PayPeriod.startDate, ascending: false)],
            predicate: jobPredicate
        )
    }
    
    var body: some View {
        
        
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                List {
                    
                    ForEach(Array(payPeriods.enumerated()), id: \.element.objectID) { index, payPeriod in
                        
                        NavigationLink(value: payPeriod) {
                            
                            PayPeriodDetailRow(payPeriod)
                            
                            
                        }.listRowBackground(Color.clear)
                        
                            .id(index)
                        
                            .background {
                                
                                // we dont need the geometry reader, performance is better just doing this
                                if index == 0 {
                                    Color.clear
                                        .onDisappear {
                                            scrollManager.timeSheetsScrolled = true
                                        }
                                        .onAppear {
                                            scrollManager.timeSheetsScrolled = false
                                        }
                                }
                            }
                        
                            .swipeActions {
                                Button(role: .destructive) {
                                    payPeriodManager.deletePayPeriod(payPeriod, in: viewContext)
                                } label: {
                                    Image(systemName: "trash")
                                    
                                }.tint(.red)
                                
                                Button(role: .none) {
                                    loadShiftsToExport(payPeriod: payPeriod)
                                    showInvoiceView.toggle()
                                } label: {
                                    Image(systemName: "rectangle.and.paperclip")
                                    
                                }
                                
                                Button(role: .none) {
                                    loadShiftsToExport(payPeriod: payPeriod)
                                    showExportView.toggle()
                                } label: {
                                    Image(systemName: "tablecells")
                                    
                                }
                                
                                
                                
                                
                                
                            }
                        
                            .contextMenu {
                                
                                Button(role: .destructive) {
                                    payPeriodManager.deletePayPeriod(payPeriod, in: viewContext)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }.tint(.red)
                                
                                Button(role: .none) {
                                    loadShiftsToExport(payPeriod: payPeriod)
                                    
                                    showInvoiceView.toggle()
                                    
                                } label: {
                                    Label("Generate Invoice or Timesheet", systemImage: "rectangle.and.paperclip")
                                }
                                
                                Button(role: .none) {
                                    loadShiftsToExport(payPeriod: payPeriod)
                                    
                                    
                                    showExportView.toggle()
                                    
                                } label: {
                                    Label("Export to CSV", systemImage: "tablecells")
                                }
                            }
                        
                    }
                }.listStyle(.plain)
                
                    .tint(Color.gray)
                    .scrollContentBackground(.hidden)
                
                
                    .background {
                        // this could be worked into the themeManagers pure dark mode?
                        
                        
                        // weirdly enough it looks good switching to the settings background here
                        if colorScheme == .dark {
                            themeManager.settingsDynamicBackground.ignoresSafeArea()
                        } else {
                            Color.clear.ignoresSafeArea()
                        }
                    }
                
                    .onChange(of: scrollManager.scrollOverviewToTop) { value in
                        if value {
                            withAnimation(.spring) {
                                proxy.scrollTo(0, anchor: .top)
                            }
                            DispatchQueue.main.async {
                                
                                scrollManager.scrollOverviewToTop = false
                            }
                        }
                        
                        
                        
                    }
                
                
                
                
            }
            
            floatingButtons
            
                .sheet(isPresented: $showExportView, onDismiss: {
                    
                    shiftsToExport = nil
                    
                }) {
                    
                    
                    
                    ConfigureExportView(job: selectedJobManager.fetchJob(in: viewContext), arrayShifts: shiftsToExport)
                    
                        .presentationDetents([.large])
                        .customSheetRadius(35)
                        .customSheetBackground()
                    
                    
                    
                }
            
                .sheet(isPresented: $showInvoiceView, onDismiss: {
                    
                    shiftsToExport = nil
                    
                }) {
                    
                    
                    GenerateInvoiceView(job: selectedJobManager.fetchJob(in: viewContext), arrayShifts: shiftsToExport)
                    
                        .customSheetBackground()
                        .customSheetRadius(35)
                    
                }
            
        }
        
        .onChange(of: payPeriods.count) { value in
            // dirty fixes it being set to true after deleting the last one
            if value == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7){
                    scrollManager.timeSheetsScrolled = false
                }
                
            }
            
        }
        
        
        
        
        .navigationTitle("Pay Periods")
        
        
        
        
        
        .onAppear{
            
            if let job = selectedJobManager.fetchJob(in: viewContext) {
                
                payPeriodManager.updatePayPeriods(using: viewContext, payPeriods: payPeriods, job: job)
            } else {
                // no job, dismiss
                dismiss()
                
                
            }
        }
        
        .sheet(isPresented: $showCreateSheet) {
            
            newPeriodSheet
            
            
                .customSheetRadius()
                .customSheetBackground()
            
                .presentationDetents([.fraction(0.44)])
            
            
        }
        
        
        
        
    }
    
    var floatingButtons: some View {
        
        let buttonColor: Color = colorScheme == .dark ? Color.white : Color.black
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        return ActionButtonView(title: "Create Pay Period", backgroundColor: buttonColor, textColor: textColor, icon: "note.text.badge.plus", buttonWidth: getRect().width - 60, action: {
            withAnimation(.spring) {
                showCreateSheet.toggle()
            }
        })
        .padding(.bottom)
        .padding(.bottom, getRect().height == 667 ? 10 : 0)
        
        
    }
    
    var isDateConflict: Bool {
           let newStartDate = payPeriodManager.newPeriodStartDate
           let newEndDate = payPeriodManager.newPeriodEndDate
        
        guard newStartDate <= newEndDate else {
            return false
        }
            
            return payPeriods.contains { existingPayPeriod in
                guard let existingStartDate = existingPayPeriod.startDate,
                let existingEndDate = existingPayPeriod.endDate,
                      existingStartDate <= existingEndDate else {
                    return false
                }
                return (newStartDate...newEndDate).overlaps(existingStartDate...existingEndDate)
            }
            
        
       }
    
    var newPeriodSheet: some View {
        
        
        let buttonColor: Color = colorScheme == .dark ? Color.white : Color.black
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        return NavigationStack {
            
            ZStack(alignment: .bottom){
                ScrollView {
                    VStack {
                     
                            DatePicker("Start Date", selection: $payPeriodManager.newPeriodStartDate, displayedComponents: .date)
                        
                            DatePicker("End Date", selection: $payPeriodManager.newPeriodEndDate, in: payPeriodManager.newPeriodStartDate..., displayedComponents: .date)

                        
                    }.padding()
                        .glassModifier(cornerRadius: 20)
                        .padding(.horizontal)
                    
                    if isDateConflict {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill") .bold().foregroundStyle(Color.gray)
                           
                            Text("Dates conflict with another pay period.")
                            Spacer()
                        }.padding()
                            .glassModifier(cornerRadius: 20)
                            .padding(.horizontal)
                        
                    }
                    
                    VStack(alignment: .leading, spacing: 10){
                        Toggle(isOn: $payPeriodManager.remindMeAtEnd){
                            
                            Text("Notify at End").bold()
                            
                        }.toggleStyle(CustomToggleStyle())
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        
                    }.glassModifier(cornerRadius: 20)
                        .padding(.horizontal)
                    
                    
                    Spacer(minLength: 120)
                    
                }
                .scrollContentBackground(.hidden)
                
                
                ActionButtonView(title: "Create", backgroundColor: buttonColor, textColor: textColor, icon: "note.text.badge.plus", buttonWidth: getRect().width - 60, action: {
                    
                    if let job = selectedJobManager.fetchJob(in: viewContext) {
                        payPeriodManager.createNewPayPeriod(using: viewContext, payPeriods: payPeriods, job: job)
                    }
                    
                    showCreateSheet = false
                    
                }).padding(.bottom, getRect().height == 667 ? 10 : 0)
                
                    .opacity(!isDateConflict ? 1.0 : 0.5)
                    .disabled(isDateConflict)
                
                
            }
            
            .toolbar {
                CloseButton()
            }
            
            
            .navigationTitle("New Pay Period")
            .navigationBarTitleDisplayMode(.inline)
            
        }
        
        
    }
    
    
    
}
