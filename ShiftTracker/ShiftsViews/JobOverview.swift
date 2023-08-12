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
    
    @State private var showingAddShiftSheet = false
    
    @State private var isShareSheetShowing = false
    
    @State private var isChartViewPrimary: Bool = false
    
    @StateObject var savedPublisher = ShiftSavedPublisher()
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var navigationState: NavigationState
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    let shiftStore = ShiftStore()
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    
    init(navPath: Binding<NavigationPath>){
        print("job overview itself got reinitialised")
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        _shifts = FetchRequest(fetchRequest: fetchRequest)
        
        
        _navPath = navPath
        
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
        List{
            Section{
                GeometryReader { geometry in
                    VStack(alignment: .leading, spacing: 0){
                    HStack(spacing: 8){
                        VStack(spacing: 0) {
                            if !isChartViewPrimary {
                                StatsSquare()
                                    .environmentObject(shiftManager)
                                    .frame(width: geometry.size.width / 2 - 8)
                                Spacer()
                            }
                            ChartSquare(isChartViewPrimary: $isChartViewPrimary)
                                .environmentObject(shiftManager)
                                .frame(width: isChartViewPrimary ? geometry.size.width : geometry.size.width / 2 - 8)
                                .frame(height: isChartViewPrimary ? geometry.size.height : geometry.size.height / 2)
                                .animation(.easeInOut, value: isChartViewPrimary)
                        }
                        if !isChartViewPrimary {
                        
                            ExportSquare(action: shareButton)
                                .environmentObject(shiftManager)
                                .frame(width: geometry.size.width / 2 - 8)
                                .frame(height: geometry.size.height)
                            
                        }
                        
                    }
                    }.frame(maxWidth: .infinity)
                }
                    .padding(.trailing, 2)
            }.frame(minHeight: isChartViewPrimary ? 400 : 200)
            
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 20, leading: 0, bottom: 20, trailing: 0))
                .haptics(onChangeOf: isChartViewPrimary, type: .light)
            
            
            Section{
                ForEach(shifts.filter({ shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) }).prefix(10), id: \.self) { shift in
                    
                    NavigationLink(value: shift) {
                        ShiftDetailRow(shift: shift)
                            
                        
                    }
                  
                                
                    .navigationDestination(for: OldShift.self) { shift in
                        
                        // it was not the worlds greatest workaround ... lets do things properly!
                            DetailView(shift: shift, navPath: $navPath).environmentObject(savedPublisher)

                            
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
                        .foregroundColor(textColor)
                        .padding(.leading, jobSelectionViewModel.fetchJob(in: viewContext) != nil ? -12 : -4)
                        .font(.title2)
                        .bold()
                    Spacer()
                    Image(systemName: "chevron.right")
                    .bold()
                    
                }
                .navigationDestination(for: Int.self) { _ in
                       
                    ShiftsList(navPath: $navPath).environmentObject(jobSelectionViewModel).environmentObject(shiftManager).environmentObject(navigationState).environmentObject(savedPublisher).environmentObject(sortSelection)
                       
                   }
                
                        
                  
                    
            }
            .listRowBackground(Color("SquaresColor"))
            .listRowInsets(.init(top: 10, leading: jobSelectionViewModel.fetchJob(in: viewContext) != nil ? 20 : 10, bottom: 10, trailing: 20))
           
           
            
        }.scrollContentBackground(.hidden)
            
        .sheet(isPresented: $showingAddShiftSheet) {
            if let job = jobSelectionViewModel.fetchJob(in: viewContext){
                
                
  
                NavigationStack{
                    DetailView(job: job, presentedAsSheet: true)
                }
                
                .presentationDetents([.large])
                .presentationCornerRadius(35)
                .presentationBackground(Color("allSheetBackground"))
            } else {
                Text("Error")
            }
        }
            
        
     
        .onAppear {
            navigationState.gestureEnabled = true
            
  
            
   
                loadShiftData()
                print("on appear called")
            
            
        }
            
            
  
        .onReceive(shiftManager.$shiftAdded) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                loadShiftData()
                print("shift recieved called")
            }
        }
            
        .onReceive(jobSelectionViewModel.$selectedJobUUID){ _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                
                loadShiftData()
                print("selected job called")
            }
        }
            
            
            

            
        .navigationBarTitle(jobSelectionViewModel.fetchJob(in: viewContext)?.name ?? "Summary")
            
        .toolbar{
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddShiftSheet.toggle()
                }){
                    
                    Image(systemName: "plus")
                    .bold()
                    
                }.disabled(jobSelectionViewModel.selectedJobUUID == nil)
                    
                
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(0..<shiftManager.statsModes.count) { index in
                        Button(action: {
                            withAnimation {
                                shiftManager.statsMode = StatsMode(rawValue: index) ?? .earnings
                                shiftManager.shiftDataLoaded.send(())
                            }
                        }) {
                            HStack {
                                Text(shiftManager.statsModes[index])
                                    .textCase(nil)
                                if index == shiftManager.statsMode.rawValue {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor) // Customize the color if needed
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .bold()
                }
                .haptics(onChangeOf: shiftManager.statsMode, type: .soft)
            }
            
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
        shiftManager.halfYearlyShifts = shiftManager.getLastShifts(from: shifts, jobModel: jobSelectionViewModel, dateRange: .halfYear)
        shiftManager.yearlyShifts = shiftManager.getLastShifts(from: shifts, jobModel: jobSelectionViewModel, dateRange: .year)
        
        shiftManager.totalPay = shiftManager.addAllPay(shifts: shifts, jobModel: jobSelectionViewModel)
        shiftManager.totalHours = shiftManager.addAllHours(shifts: shifts, jobModel: jobSelectionViewModel)
        shiftManager.totalShifts = shiftManager.getShiftCount(from: shifts, jobModel: jobSelectionViewModel)
        shiftManager.totalBreaksHours = shiftManager.addAllBreaksHours(shifts: shifts, jobModel: jobSelectionViewModel)
        
        shiftManager.shiftDataLoaded.send(())
    }
    
    func shareButton() {
        
        var fileName = "export.csv"
        
        if let job = jobSelectionViewModel.fetchJob(in: viewContext) {
            
            fileName = "\(job.name ?? "") ShiftTracker export"
            
        }
        
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = "Job,Start Date,End Date,Duration,Hourly Rate,Before Tax,After Tax,Tips,Notes\n"
        
        
        for shift in shifts {
            
            if let jobid = jobSelectionViewModel.selectedJobUUID {
                if shift.job?.uuid == jobSelectionViewModel.selectedJobUUID {
                    csvText += "\(shift.job?.name ?? ""),\(shift.shiftStartDate ?? Date()),\(shift.shiftEndDate ?? Date()),\(shift.duration),\(shift.hourlyPay),\(shift.totalPay ),\(shift.taxedPay),\(shift.totalTips),\(shift.shiftNote ?? "")\n"
                }
                
            } else {
                
                csvText += "\(shift.job?.name ?? ""),\(shift.shiftStartDate ?? Date()),\(shift.shiftEndDate ?? Date()),\(shift.duration),\(shift.hourlyPay),\(shift.totalPay ),\(shift.taxedPay),\(shift.totalTips),\(shift.shiftNote ?? "")\n"
                
            }
            
            
        }
        
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create file")
            print("\(error)")
        }
        print(path ?? "not found")
        
        var filesToShare = [Any]()
        filesToShare.append(path!)
        
        let av = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
        
        isShareSheetShowing.toggle()
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
