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
    
    @FetchRequest(entity: PayPeriod.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \PayPeriod.startDate, ascending: false)])
    var payPeriods: FetchedResults<PayPeriod>

    @State private var showCreateSheet = false
    
    var body: some View {
        
        
        ZStack(alignment: .bottomTrailing) {
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
                            Label("Delete", systemImage: "trash")
                        }.tint(.red)
                        
                        Button(role: .none) {
                            
                        } label: {
                            Label("Generate Invoice", systemImage: "rectangle.and.paperclip")
                        }
                        
                        Button(role: .none) {
                            
                        } label: {
                            Label("Export to CSV", systemImage: "tablecells")
                        }
                        
                        
                        
                        
                        
                    }
                    
                    .contextMenu {
                        
                        Button(role: .destructive) {
                            payPeriodManager.deletePayPeriod(payPeriod, in: viewContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }.tint(.red)
                        
                        Button(role: .none) {
                            
                        } label: {
                            Label("Generate Invoice", systemImage: "rectangle.and.paperclip")
                        }
                        
                        Button(role: .none) {
                            
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
        
    }
        
                  
        
        
                    .navigationTitle("Pay Periods")
                
                
        
        
        
                    .onAppear{
                        payPeriodManager.updatePayPeriods(using: viewContext, payPeriods: payPeriods)
                    }
        
                .sheet(isPresented: $showCreateSheet) {
                    
                    newPeriodSheet
                    
                        
                        .customSheetRadius()
                        .customSheetBackground()
                    
                        .presentationDetents([.fraction(0.4)])
                    
                    
                }
                
        
        
        
    }
    
    var floatingButtons: some View {
        VStack{
            
            HStack(spacing: 10){
                
                
                
                Button(action: {
                    withAnimation(.spring) {
                        showCreateSheet.toggle()
                    }
                }){
                    
                    Image(systemName: "plus").customAnimatedSymbol(value: $showCreateSheet)
                        .bold()
                    
                }
                
                
                
                
            }.padding()
                .glassModifier(cornerRadius: 20)
            
                .padding()
            
          //  Spacer().frame(height: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 50 : 40)
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
                    
                    
                    Spacer(minLength: 120)
                    
                }
                .scrollContentBackground(.hidden)
               
                
                ActionButtonView(title: "Create", backgroundColor: buttonColor, textColor: textColor, icon: "note.text.badge.plus", buttonWidth: getRect().width - 60, action: {
                    
                    
                    payPeriodManager.createNewPayPeriod(using: viewContext, payPeriods: payPeriods)
                    
                    showCreateSheet = false
                    
                }).padding(.bottom, getRect().height == 667 ? 10 : 0)
                
               
            }
            
            .toolbar {
                CloseButton()
            }
            
            
            .navigationTitle("New Pay Period")
            .navigationBarTitleDisplayMode(.inline)
            
        }
        
        
    }

    
    
}
