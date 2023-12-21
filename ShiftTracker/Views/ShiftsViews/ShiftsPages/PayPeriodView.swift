//
//  PayPeriodView.swift
//  ShiftTracker
//
//  Created by James Poole on 21/12/23.
//

import SwiftUI
import CoreData

struct PayPeriodView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var scrollManager: ScrollManager
    @EnvironmentObject private var themeManager: ThemeDataManager
    @EnvironmentObject private var navigationState: NavigationState
    @EnvironmentObject private var selectedJobManager: JobSelectionManager
    @EnvironmentObject private var overviewModel: JobOverviewViewModel
    @EnvironmentObject var shiftStore: ShiftStore
    
    
    @State var editMode = EditMode.inactive
    @State private var selection = Set<NSManagedObjectID>()
    @State private var showExportView = false
    @State private var showingProView = false
    @State private var payPeriod: (Date, Date)? = nil
    @State var job: Job? = nil
    
    @Binding var navPath: NavigationPath
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var shifts: FetchedResults<OldShift>
    
    init(navPath: Binding<NavigationPath>, job: Job? = nil) {
        
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: true)]
    
        if let job = job {
            
            let payPeriod = calculateCurrentPayPeriod(lastEndDate: job.lastPayPeriodEndedDate!, duration: Int(job.payPeriodLength))
         
            fetchRequest.predicate = NSPredicate(format: "shiftStartDate >= %@ AND shiftEndDate <= %@", payPeriod.0 as CVarArg, payPeriod.1 as CVarArg)
            _payPeriod = State(initialValue: payPeriod)
            _job = State(initialValue: job)
            
        }

        _navPath = navPath
        _shifts = FetchRequest(fetchRequest: fetchRequest, animation: .default)
        
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing){
            ScrollViewReader { proxy in
                
                List(selection: editMode.isEditing ? $selection : .constant(Set<NSManagedObjectID>())) {
                    
                  
                    
              
                    Section {
                        statsSection.id(0)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        
           
                        
                        
                            .onDisappear {
                                scrollManager.timeSheetsScrolled = true
                            }
                            .onAppear {
                                scrollManager.timeSheetsScrolled = false
                            }
                        
                        shiftsSection
                            .listRowBackground(Color.clear)
                        
                    } header: {
                        if let payPeriod = payPeriod {
                            HStack {
                                Text(payPeriod.0, style: .date)
                                Text("-")
                                Text(payPeriod.1, style: .date)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            
                            .font(.headline)
                            
                        }
                    }
                    
                }.scrollContentBackground(.hidden)
                    .tint(Color.gray)
                //  .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                    .listStyle(.plain)
                    .background {
                        // this could be worked into the themeManagers pure dark mode?
                        if colorScheme == .dark {
                            themeManager.overviewDynamicBackground.ignoresSafeArea()
                        } else {
                            Color.clear.ignoresSafeArea()
                        }
                    }
                
                    .customSectionSpacing()
                
                    .onChange(of: scrollManager.scrollOverviewToTop) { value in
                        if value {
                            withAnimation {
                                proxy.scrollTo(0, anchor: .top)
                            }
                            DispatchQueue.main.async {
                                
                                scrollManager.scrollOverviewToTop = false
                            }
                        }
                    }
                
            }
            
            floatingButtons
            
        } .environment(\.editMode, $editMode)
        
            .onChange(of: editMode.isEditing) { value in
                withAnimation {
                if value {
                  
                        navigationState.hideTabBar = true
                        
                    } else {
                        navigationState.hideTabBar = false
                    }
                }
                
            }
      
        
            .sheet(isPresented: $showExportView) {
                
                ConfigureExportView(shifts: shifts, job: selectedJobManager.fetchJob(in: viewContext), selectedShifts: selection)
                    .presentationDetents([.large])
                    .customSheetRadius(35)
                    .customSheetBackground()
                
            }
        
        
            .navigationTitle(selection.isEmpty ? "Pay Period" : "\(selection.count) selected")
                                    
            .navigationBarBackButtonHidden(editMode.isEditing)
        
            .toolbar(editMode.isEditing ? .hidden : .visible, for: .tabBar)
        
            .toolbar{
                       if editMode.isEditing {
                           ToolbarItem(placement: .topBarLeading) {
                               Button(action: {
                                   
                                   
                                   
                                   if selection.isEmpty {
                                      
                                    
                                       // select all the shifts
                                       
                                       selection = Set(shifts.map { $0.objectID })
                
                                   } else {
                                       selection = Set()
                                   }
                                   
                               }){
                                   Text(selection.isEmpty ? "Select All" : "Unselect All")
                               }
                           }
                       } else {
                           ToolbarItem(placement: .topBarTrailing) {
                               
                               Button(action: {
                                   // show picker with list of all pay periods. selecting one changes the payPeriod variable above
                               }){
                                   Text("View All")
                               }
                               
                           }
                       }
                
                    
                
                   }
                   .environment(\.editMode, $editMode)
        
    }
    

    
    
    var statsSection: some View {
        
        VStack {
            
            
            
            HStack(spacing: 0){
                
                Spacer()
                
                StatView(title: "Earnings", value: "\(shiftManager.currencyFormatter.string(from: NSNumber(value: shiftManager.addAllPay(shifts: shifts, jobModel: selectedJobManager))) ?? "0")")
                
                Spacer()
      
                StatView(title: "Hours", value: shiftManager.formatTime(timeInHours: shiftManager.addAllHours(shifts: shifts, jobModel: selectedJobManager)))
            Spacer()
                StatView(title: "On Break", value: shiftManager.formatTime(timeInHours: shiftManager.addAllBreaksHours(shifts: shifts, jobModel: selectedJobManager)))
                
                Spacer()
                
                
            
                
                
                
                
            }//.padding(.top, 5)
            
            
            // should show shift count ideally
            
          /*
            Text("\(shifts.filter { shiftManager.shouldIncludeShift($0, jobModel: selectedJobManager) }.count) shifts")
                .roundedFontDesign()
                .bold()
                .padding()
            */
          
  
              //  .opacity(historyModel.chartSelection == nil ? 1.0 : 0.0)
            
                // let barMarks = historyModel.aggregatedShifts[index].dailyOrMonthlyAggregates
            
            // gotta do it this way, for some reason doing the check in the chartView fails and builds anyway for ios 16 causing a crash
            if #available(iOS 17.0, *){
                
               /* ChartView(dateRange: dateRange, shifts: barMarks)
                    .environmentObject(historyModel)
                    .padding(.leading)*/
                
            } else {
               /* iosSixteenChartView(dateRange: dateRange, shifts: barMarks)
                    
                    .padding(.leading)*/
            }
            
            
        }      
        .padding()
        .glassModifier()
        .frame(width: getRect().width - 44)
         
        
    }
    
    var shiftsSection: some View {
        
        
        let filteredShifts = shifts.filter { shiftManager.shouldIncludeShift($0, jobModel: selectedJobManager) }
        
       
        
        return ForEach(Array(filteredShifts.enumerated()), id: \.element.objectID) { index, shift in
            
            NavigationLink(value: shift) {
                ShiftDetailRow(shift: shift)
            }
      
            
            .background(ContextMenuPreview(shift: shift, themeManager: themeManager, navigationState: navigationState, viewContext: viewContext, deleteAction: {
                
                withAnimation {
                    shiftStore.deleteOldShift(shift, in: viewContext)
          
                    
                    if filteredShifts.isEmpty {
                        // navigates back if all shifts are deleted
                        navPath.removeLast()
                        
                    }
                }
                
            }, duplicateAction: {
                
                overviewModel.selectedShiftToDupe = shift
                overviewModel.activeSheet = .addShiftSheet
                
            }, editMode: $editMode, action: {
                if !editMode.isEditing {
                    navPath.append(shift)
                }
            }))
            
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
                
                
                
                Button(action: {
                    withAnimation {
                        shiftStore.deleteOldShift(shift, in: viewContext)
                
                        if filteredShifts.isEmpty {
                            // navigates back if all shifts are deleted
                            navPath.removeLast()
                            
                        }
                    }
                }){
                    Image(systemName: "trash")
                }
                
                .tint(.red)
                
                Button(action: {
                    
                    overviewModel.selectedShiftToDupe = shift
                    
                    
                    
                    
                    overviewModel.activeSheet = .addShiftSheet
                    
                    
                }){
                    Image(systemName: "plus.square.fill.on.square.fill")
                }.tint(.gray)
                
            }
            
            .id(index)
            
        }
            
            .onAppear {
                
                withAnimation {
                    shiftManager.showModePicker = false
                }
                
                if payPeriod == nil || selectedJobManager.fetchJob(in: viewContext) == nil {
                    dismiss()
                }
            }

        
    }
    
    var floatingButtons: some View {
        
        VStack{
            HStack(spacing: 10){
                
                if editMode.isEditing {
                    
                    Group {
                        
                        
                        Button(action: {
                            
                            if purchaseManager.hasUnlockedPro {
                                showExportView.toggle()
                            } else {
                                
                               showingProView.toggle()
                                
                            }
                            
                            
                        }){
                            Image(systemName: "square.and.arrow.up").bold()
                        }.disabled(selection.isEmpty)
                        
                        Divider().frame(height: 10)
                        
                        Button(action: {
                            CustomConfirmationAlert(action: {}, cancelAction: nil, title: "Are you sure?").showAndStack()
                        }) {
                            Image(systemName: "trash")
                                .bold()
                            
                                .customAnimatedSymbol(value: $selection)
                        }.disabled(selection.isEmpty)
                            .tint(.red)
                        
                        Divider().frame(height: 10)
                        
                    }
                    .animation(.easeInOut, value: editMode.isEditing)
                }
                
                CustomEditButton(editMode: $editMode, action: {
                    selection.removeAll()
                })
                
                
                
            }.padding()
                .glassModifier(cornerRadius: 20)
                .padding()
            
           // Spacer().frame(height: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 50 : 40)
        } .padding(.bottom, navigationState.hideTabBar ? 49 : 0).animation(.none, value: navigationState.hideTabBar)
    }
    
}

struct StatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .center) {
            Text(title)
                .font(.headline)
                .bold()
                .roundedFontDesign()
                .foregroundColor(.gray)

            Text(value)
                .font(.title2)
                .bold()
        }
    }
}
