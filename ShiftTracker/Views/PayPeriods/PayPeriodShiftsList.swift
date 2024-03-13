//
//  PayPeriodShiftsList.swift
//  ShiftTracker
//
//  Created by James Poole on 10/03/24.
//

import SwiftUI
import CoreData

struct PayPeriodShiftsList: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var shiftStore: ShiftStore
    @EnvironmentObject var overviewModel: JobOverviewViewModel
    @EnvironmentObject var scrollManager: ScrollManager
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @Environment(\.managedObjectContext) var viewContext
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var navPath: NavigationPath
    
    @State var editMode = EditMode.inactive
    @State private var showExportView = false
    @State private var showInvoiceView = false
    @State private var showingProView = false
    
    let shiftManager = ShiftDataManager()
    
    @State private var clearSelection = false // only set to true if export all/generate all to invoice button is pressed to clear the selection on dismiss
    
    var payPeriod: PayPeriod
    
    var job: Job
    
    // use a fetch instead of the relationship to ensure always up to date data
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    @State private var selection = Set<NSManagedObjectID>()

    init(payPeriod: PayPeriod, navPath: Binding<NavigationPath>, job: Job) {
        self.payPeriod = payPeriod
            var predicates: [NSPredicate] = [NSPredicate(format: "isActive == NO")]
               let jobPredicate = NSPredicate(format: "job == %@", job)
               let datePredicate = NSPredicate(format: "shiftStartDate >= %@ AND shiftEndDate <= %@", payPeriod.startDate! as CVarArg, payPeriod.endDate! as CVarArg)
        predicates.append(jobPredicate)
        predicates.append(datePredicate)
               let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
               self._shifts = FetchRequest(
                   entity: OldShift.entity(),
                   sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)],
                   predicate: compoundPredicate
               )

               _navPath = navPath
        self.job = job
        
           }

       
    
    var body: some View {
        ZStack(alignment: .bottom){
        ScrollViewReader { proxy in
            List(selection: editMode.isEditing ? $selection : .constant(Set<NSManagedObjectID>())) {
                
                Spacer(minLength: 38).id(0)
                
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            // dirty but fixes it
                            scrollManager.timeSheetsScrolled = false
                        }
                        
                    }
                
                
                ForEach(Array(shifts.enumerated()), id: \.element.objectID) { index, shift in
                    NavigationLink(value: shift) {
                        ShiftDetailRow(shift: shift)
                    }
                    
                    .background {
                        
                        
                        
                        let deleteUIAction = UIAction(title: "Delete", image: UIImage(systemName: "trash.fill"), attributes: .destructive) { _ in
                           
                            deleteShift(shift)
                           
                        }
                        
                        let duplicateUIAction = UIAction(title: "Duplicate", image: UIImage(systemName: "plus.square.fill.on.square.fill")) { _ in
                            
                           duplicateShift(shift)
                            
                        }
                        
                        let shareUIAction = UIAction(title: "Export", image: UIImage(systemName: "square.and.arrow.up.fill")) { _ in
                            
                            exportShift(shift)
                            
                        }
                        
                        
                        
                        ContextMenuPreview(shift: shift, themeManager: themeManager, navigationState: navigationState, viewContext: viewContext, actionsArray: [deleteUIAction, duplicateUIAction, shareUIAction], editMode: $editMode, action: {
                            if !editMode.isEditing {
                                navPath.append(shift)
                            }
                        })
                        
                        
                    }
                    
                    .listRowBackground(Color.clear)
                    
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
                        
                        OldShiftSwipeActions(deleteAction: {deleteShift(shift)}, duplicateAction: {duplicateShift(shift)})
                        
                    }
                    
                    .swipeActions(edge: .leading) {
                        Button(action: {
                            exportShift(shift)
                        }){
                            Image(systemName: "square.and.arrow.up.fill")
                        }.tint(.gray)
                        
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
            
            VStack {
                
                statsSection.padding(.top, 5)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    floatingButtons
                }.padding(.bottom, navigationState.hideTabBar ? 49 : 0).animation(.none, value: navigationState.hideTabBar)
                
            }
            
                .padding(.bottom)
        
                .sheet(isPresented: $showExportView, onDismiss: {
                    if selection.count <= 1 || clearSelection {
                        selection = Set()
                    }
                }) {
                    
                    
                    
                    ConfigureExportView(shifts: shifts, job: selectedJobManager.fetchJob(in: viewContext), selectedShifts: selection)
                        .presentationDetents([.large])
                        .customSheetRadius(35)
                        .customSheetBackground()
                    
                }
            
                .sheet(isPresented: $showInvoiceView, onDismiss: {
                    if selection.count <= 1 || clearSelection {
                        selection = Set()
                    }
                    
                   
                    
                }) {
                    GenerateInvoiceView(shifts: shifts, job: selectedJobManager.fetchJob(in: viewContext), selectedShifts: selection)
                    
                        .customSheetBackground()
                        .customSheetRadius(35)
                }
            
                .fullScreenCover(isPresented: $showingProView) {
                    ProView()
                        .environmentObject(purchaseManager)
                    
                        .customSheetBackground()
                }
            
            
    } .onAppear {
        if selectedJobManager.fetchJob(in: viewContext) == nil || shifts.isEmpty {
             dismiss()
         }
     }
        
        
        .navigationTitle(!selection.isEmpty ? "\(selection.count) selected" : "\(payPeriod.periodRange)")
        .navigationBarBackButtonHidden(editMode.isEditing)
        
        .navigationBarTitleDisplayMode(.inline)
        
        .toolbar{
            if editMode.isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        
                        selectOrDeselectAll()
                        
                    }){
                        Text(selection.isEmpty ? "Select All" : "Unselect All")
                    }
                }
            }
        }
        .environment(\.editMode, $editMode)
        
        .toolbar(editMode.isEditing ? .hidden : .visible, for: .tabBar)
        
        .onChange(of: editMode.isEditing) { value in
            withAnimation {
            if value {
              
                    navigationState.hideTabBar = true
                    
                } else {
                    navigationState.hideTabBar = false
                }
            }
            
        }
        
        
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
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .glassModifier()
        .frame(width: getRect().width - 20)
         
        
    }
    
    var floatingButtons: some View {
        VStack(alignment: .trailing) {
            
            VStack{
                
                HStack(spacing: 10){
                    
                    
                    
                    Group {
                        
                        
                        if editMode.isEditing {
                            
                            
                            Menu {
                                
                                Button(action: {
                                    
                                    if purchaseManager.hasUnlockedPro {
                                        showExportView.toggle()
                                    } else {
                                        
                                        showingProView.toggle()
                                        
                                    }
                                    
                                    
                                }){
                                    Text("Export to CSV")
                                    Image(systemName: "tablecells").bold()
                                }
                                
                             
                                    // allow invoices if not pro, just dont allow export
                                Button(action: {
                                    
                                 //   if purchaseManager.hasUnlockedPro {
                                        showInvoiceView.toggle()
                                //    } else {
                                        
                                  //      showingProView.toggle()
                                        
                                 //   }
                                    
                                    
                                }){
                                    Text("Generate Invoice or Timesheet")
                                    Image(systemName: "rectangle.and.paperclip").bold()
                                }.disabled(selectedJobManager.fetchJob(in: viewContext) == nil) // dont allow invoicing if no job is currently selected
                                
                            } label: {
                                Image(systemName: "square.and.arrow.up").bold()
                            }.disabled(selection.isEmpty)
                            
                           
                            
                            Divider().frame(height: 10)
                            
                            
                            
                            Button(action: {
                                CustomConfirmationAlert(action: deleteItems, cancelAction: nil, title: "Are you sure?").showAndStack()
                            }) {
                                Image(systemName: "trash").customAnimatedSymbol(value: $selection)
                                    .bold()
                            }.disabled(selection.isEmpty)
                                .tint(.red)
                            
                        } else {
                            
                            // same buttons as above? export all in the current pay period
                            
                            Menu {
                                
                                Button(action: {
                                    
                                    if purchaseManager.hasUnlockedPro {
                                        
                                        clearSelection = true
                                        
                                        selectOrDeselectAll()
                                        
                                        showExportView.toggle()
                                    } else {
                                        
                                        showingProView.toggle()
                                        
                                    }
                                    
                                    
                                }){
                                    Text("Export All to CSV")
                                    Image(systemName: "tablecells").bold()
                                }
                                
                             
                                    // allow invoices if not pro, just dont allow export
                                Button(action: {
                                    
                                 //   if purchaseManager.hasUnlockedPro {
                                    
                                    clearSelection = true
                                    
                                    selectOrDeselectAll() // select all shifts to export
                                    
                                        showInvoiceView.toggle()
                                //    } else {
                                        
                                  //      showingProView.toggle()
                                        
                                 //   }
                                    
                                    
                                }){
                                    Text("Generate Invoice/Timesheet for Pay Period")
                                    Image(systemName: "rectangle.and.paperclip").bold()
                                }.disabled(selectedJobManager.fetchJob(in: viewContext) == nil) // dont allow invoicing if no job is currently selected
                                
                            } label: {
                                Image(systemName: "square.and.arrow.up").bold()
                            }//.disabled(selection.isEmpty)
                            
                            
                        }
                        
                        
                        Divider().frame(height: 10)
                        
                        
                    }  .animation(.easeInOut, value: editMode.isEditing)
                    
                    
                    CustomEditButton(editMode: $editMode, action: {
                        selection.removeAll()
                    })
                    
                    
                    
                    
                    
                    
                    
                    
                    
                }.padding()
                    .glassModifier(cornerRadius: 20)
                
            }.padding(.trailing)

            
            
        }
    }
    
    func selectOrDeselectAll() {
        if selection.isEmpty {
            let objectIDs = shifts.map { shift in
                return shift.objectID
            }
            
            selection = Set(objectIDs)
        } else {
            selection = Set()
        }
    }
    
    func deleteShift(_ shift: OldShift) {
        withAnimation {
            shiftStore.deleteOldShift(shift, in: viewContext)

        }
    }
    
    func duplicateShift(_ shift: OldShift) {
        overviewModel.selectedShiftToDupe = shift
        
        overviewModel.activeSheet = .addShiftSheet
    }
    
    func exportShift(_ shift: OldShift) {
        
        if purchaseManager.hasUnlockedPro {
            
            selection = Set(arrayLiteral: shift.objectID)
            showExportView.toggle()
            
        } else {
            showingProView.toggle()
        }
    }
    
    private func deleteItems() {
        withAnimation {
            selection.forEach { objectID in
                let itemToDelete = viewContext.object(with: objectID)
                viewContext.delete(itemToDelete)
            }
            
            do {
                try viewContext.save()
                selection.removeAll()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            
            editMode = .inactive
            
        }
    }
    
}
