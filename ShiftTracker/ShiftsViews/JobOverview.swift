//
//  JobOverview.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI
import CoreData
import Haptics



struct JobOverview: View {
    
    @EnvironmentObject var sortSelection: SortSelection
    
    @EnvironmentObject var shiftManager: ShiftDataManager
    
    @State private var isShareSheetShowing = false
    
    @State private var isChartViewPrimary: Bool = false
    
    @StateObject var savedPublisher = ShiftSavedPublisher()
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var navigationState: NavigationState
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    let shiftStore = ShiftStore()
    
    @State private var activeSheet: ActiveSheet?
    
    private enum ActiveSheet: Identifiable {
        case addShiftSheet, configureExportSheet
        
         var id: Int {
            hashValue
        }
    }
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    
    init(navPath: Binding<NavigationPath>){
        print("job overview itself got reinitialised")
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        _shifts = FetchRequest(fetchRequest: fetchRequest)
        
        
        _navPath = navPath
        
        UITableView.appearance().backgroundColor = UIColor.clear
        
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    @Binding var navPath: NavigationPath
    
    
    
   // @State var testNav: [OldShift] = []
    
    @State private var selectedView: String? = nil
    
    
    @State private var showSquare1 = false
    
    @State var animate = false
    
    var body: some View {
        
        let backgroundColor: Color = colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : .white
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        
        
        NavigationStack(path: $navPath){
            ZStack(alignment: .bottomTrailing){
            List{
             
               
                        VStack(alignment: .leading, spacing: 0){
                            HStack(spacing: 8){
                                VStack(spacing: 0) {
                                  
                                        StatsSquare()
                                            .environmentObject(shiftManager)
                                
                                        Spacer()
                               
                                    ChartSquare(isChartViewPrimary: $isChartViewPrimary)
                                       .environmentObject(shiftManager)
                                     
                                }
                    
                                    
                                    ExportSquare(action: {
                                        activeSheet = .configureExportSheet
                                    })
                                    .environmentObject(shiftManager)
                              
                                    
                                
                                
                            }
                        }.frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .frame(maxHeight: 220)
                    
                    
                  
                    
                //.frame(minHeight: isChartViewPrimary ? 400 : 200)
                
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 20, leading: 0, bottom: 30, trailing: 0))
                    .haptics(onChangeOf: isChartViewPrimary, type: .light)
                
                
                Section{
                    
                    ForEach(shifts.filter({ shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) }).prefix(10), id: \.self) { shift in
                        
                        NavigationLink(value: shift) {
                            ShiftDetailRow(shift: shift)
                            
                            
                        }
                        
                        
                        .navigationDestination(for: OldShift.self) { shift in
                            
                            // it was not the worlds greatest workaround ... lets do things properly!
                            DetailView(shift: shift, navPath: $navPath).environmentObject(savedPublisher)
                                .onAppear {
                                    withAnimation {
                                        shiftManager.showModePicker = false
                                    }
                                }
                            
                        }
                        
                        
                        /*    */
                        
                        .swipeActions {
                            
                            Button(role: .destructive) {
                                shiftStore.deleteOldShift(shift, in: viewContext)
                                shiftManager.shiftAdded.toggle()
                                
                            } label: {
                                Image(systemName: "trash")
                            }
                            
                        }
                        
                        
                    }
                    
                    
                } header: {
                    
                    NavigationLink(value: 1) {
                        
                        Text("Latest Shifts")
                            .textCase(nil)
                            .foregroundStyle(textColor)
                            .padding(.leading, jobSelectionViewModel.fetchJob(in: viewContext) != nil ? -12 : -4)
                            .font(.title2)
                            .bold()
                        
                        Image(systemName: "chevron.right")
                            .bold()
                            .foregroundStyle(.gray)
                        Spacer()
                        
                    }
                    .navigationDestination(for: Int.self) { value in
                        
                        if value == 1 {
                            ShiftsList(navPath: $navPath).environmentObject(jobSelectionViewModel).environmentObject(shiftManager).environmentObject(navigationState).environmentObject(savedPublisher).environmentObject(sortSelection)
                            
                                .onAppear {
                                    withAnimation {
                                        shiftManager.showModePicker = false
                                    }
                                }
                            
                        } else if value == 2 {
                            
                            
                            HistoryPagesView(navPath: $navPath)
                            
                            
                            
                            
                        }
                        
                    }
                    
                    
                    
                    
                }
                
                .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                
              
               
                
            
                .listRowInsets(.init(top: 10, leading: jobSelectionViewModel.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
               
               
                
                
            }.scrollContentBackground(.hidden)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
                
           
            
                VStack{
                    
                    HStack(spacing: 10){
                        
                        
                        
                        Button(action: {
                            activeSheet = .addShiftSheet
                        }){
                            
                            Image(systemName: "plus")
                            .bold()
                            
                        }.disabled(jobSelectionViewModel.selectedJobUUID == nil)
                        
                        
                        
                        
                    }.padding()
                            .glassModifier(cornerRadius: 20)
                    
                        .padding()
                       // .shadow(radius: 1)
                    
                        Spacer().frame(height: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 50 : 40)
                }
            
            
        }
            
                .sheet(item: $activeSheet) { sheet in
                    
                    switch sheet {
                        
                    case .configureExportSheet:
                        
                        
                        
                        if let job = jobSelectionViewModel.fetchJob(in: viewContext) {
                        
                            
                            ConfigureExportView(shifts: shifts, job: job)
                                .presentationDetents([.large])
                                .presentationCornerRadius(35)
                                .presentationBackground(.ultraThinMaterial)
                  
                        }
                        else {
                            ConfigureExportView(shifts: shifts)
                                .presentationDetents([.large])
                                .presentationCornerRadius(35)
                                .presentationBackground(.ultraThinMaterial)
                        }
                   
                        
                    case .addShiftSheet:
                        
                        if let job = jobSelectionViewModel.fetchJob(in: viewContext){
                            
                            
              
                            NavigationStack{
                                DetailView(job: job, presentedAsSheet: true)
                            }
                            
                            .presentationDetents([.large])
                            .presentationCornerRadius(35)
                            .presentationBackground(.ultraThinMaterial)
                        } else {
                            Text("Error")
                        }
                        
                    }
                    
                    
                }
            

            
        
     
        .onAppear {
            navigationState.gestureEnabled = true
            
            withAnimation {
                shiftManager.showModePicker = true
            }
            
   
              //  loadShiftData()
                print("on appear called")
            
            
        }
            
            
  
        .onReceive(shiftManager.$shiftAdded) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
              //  loadShiftData()
                print("shift recieved called")
            }
        }
            
        .onReceive(jobSelectionViewModel.$selectedJobUUID){ _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                
              //  loadShiftData()
                print("selected job called")
            }
        }
            
            
            

            
        .navigationTitle(jobSelectionViewModel.fetchJob(in: viewContext)?.name ?? "Summary")
            
        .toolbar{

            
            ToolbarItem(placement: .navigationBarLeading){
                Button{
                    withAnimation{
                        navigationState.showMenu.toggle()
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .bold()
                    
                }
            }
        }
            
    }
        
        
        
        
        
    }
    
    private func loadShiftData() {
        
        if let selectedJob = jobSelectionViewModel.selectedJobUUID {
            shifts.nsPredicate = NSPredicate(format: "job.uuid == %@", selectedJob as CVarArg)
        } else {
            shifts.nsPredicate = nil
        }
        
        let weeklyShifts = shiftManager.getLastShifts(from: shifts, jobModel: jobSelectionViewModel, dateRange: .week)
        shiftManager.recentShifts = weeklyShifts
        shiftManager.weeklyTotalPay = shiftManager.getTotalPay(from: weeklyShifts)
        shiftManager.weeklyTotalHours = shiftManager.getTotalHours(from: weeklyShifts)
        shiftManager.weeklyTotalBreaksHours = shiftManager.getTotalBreaksHours(from: weeklyShifts)

        shiftManager.monthlyShifts = shiftManager.getLastShifts(from: shifts, jobModel: jobSelectionViewModel, dateRange: .month)
        shiftManager.yearlyShifts = shiftManager.getLastShifts(from: shifts, jobModel: jobSelectionViewModel, dateRange: .year)
        
        shiftManager.totalPay = shiftManager.addAllPay(shifts: shifts, jobModel: jobSelectionViewModel)
        shiftManager.totalHours = shiftManager.addAllHours(shifts: shifts, jobModel: jobSelectionViewModel)
        shiftManager.totalShifts = shiftManager.getShiftCount(from: shifts, jobModel: jobSelectionViewModel)
        shiftManager.totalBreaksHours = shiftManager.addAllBreaksHours(shifts: shifts, jobModel: jobSelectionViewModel)
        
        shiftManager.shiftDataLoaded.send(())
    }
    
    


    
}
/*
struct JobOverview_Previews: PreviewProvider {
    static var previews: some View {
        let mockShiftManager = ShiftDataManager() // provide mock implementation
        let mockNavigationState = NavigationState() // provide mock implementation
        let mockJobSelectionViewModel = JobSelectionViewModel() // provide mock implementation
        let mockManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType) // provide mock implementation

        JobOverview(navPath: <#Binding<[OldShift]>#>)
            .environmentObject(mockShiftManager)
            .environmentObject(mockNavigationState)
            .environmentObject(mockJobSelectionViewModel)
            .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
*/
