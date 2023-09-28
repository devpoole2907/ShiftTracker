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
    
    @State private var jobIcon: String = "briefcase.fill"
    @State private var showLargeIcon = true
    @State private var appeared: Bool = false // for icon tap
    @State private var isEditJobPresented: Bool = false
    
    @State private var job: Job?
    @State private var jobName: String = "Summary"
    
    
    @StateObject var savedPublisher = ShiftSavedPublisher()
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var navigationState: NavigationState
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    let shiftStore = ShiftStore()
    

    
    @State private var activeSheet: ActiveSheet?
    
    private enum ActiveSheet: Identifiable {
        case addShiftSheet, configureExportSheet, symbolSheet
        
         var id: Int {
            hashValue
        }
    }
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    
    init(navPath: Binding<NavigationPath>, job: Job? = nil){
        print("job overview itself got reinitialised")
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        _shifts = FetchRequest(fetchRequest: fetchRequest)
        
        
        _navPath = navPath
        
        _job = State(initialValue: job)
        _jobIcon = State(initialValue: job?.icon ?? "briefcase.fill")
        _jobName = State(initialValue: job?.name ?? "Summary")
        
        
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
        
        let textColor: Color = colorScheme == .dark ? .white : .black

        let jobColor = Color(red: Double(job?.colorRed ?? 0.0), green: Double(job?.colorGreen ?? 0.0), blue: Double(job?.colorBlue ?? 0.0))
        
        let thisJobShifts = shifts.filter({ shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) })
        
        let shiftsThisWeek = thisJobShifts.filter { shift in
            
            shiftManager.isWithinLastWeek(date: shift.shiftStartDate!)
            
        }
        
        GeometryReader { geo in
        ZStack(alignment: .bottomTrailing){
            List{
                
             
                VStack(alignment: .leading, spacing: 0){
                    HStack(spacing: 8){
                        VStack(spacing: 0) {
                            
                            StatsSquare(shifts: thisJobShifts, shiftsThisWeek: shiftsThisWeek)
                                .environmentObject(shiftManager)
                            
                            Spacer()
                            
                            ChartSquare(shifts: shiftsThisWeek)
                                .environmentObject(shiftManager)
                            
                        }
                        
                        
                        ExportSquare(totalShifts: thisJobShifts.count, action: {
                            activeSheet = .configureExportSheet
                        })
                        .environmentObject(shiftManager)
                        
                        
                        
                        
                    }
                }.frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .frame(maxHeight: 220)
                
                
                
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 20, leading: 0, bottom: 30, trailing: 0))
                 
                
                
                Section{
                    
                    ForEach(thisJobShifts.prefix(10), id: \.self) { shift in
                        
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
                            .padding(.leading, job != nil ? -12 : -4)
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
                            
                            if #available(iOS 17.0, *){
                                UpdatedHistoryPagesView(navPath: $navPath)
                            } else {
                                HistoryPagesView(navPath: $navPath)
                            }
                            
                            
                            
                        }
                        
                    }
                    
                    
                    
                    
                }
                
                .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                
                
                
                
                
                .listRowInsets(.init(top: 10, leading: job != nil ? 20 : 10, bottom: 10, trailing: 20))
                
                
                
                
            }.scrollContentBackground(.hidden)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
            
            
                .customSectionSpacing()
            
            VStack{
                
                HStack(spacing: 10){
                    
                    
                    
                    Button(action: {
                        withAnimation(.spring) {
                            activeSheet = .addShiftSheet
                        }
                    }){
                        
                        Image(systemName: "plus").customAnimatedSymbol(value: $activeSheet)
                            .bold()
                        
                    }.disabled(job == nil)
                    
                    
                    
                    
                }.padding()
                    .glassModifier(cornerRadius: 20)
                
                    .padding()
                // .shadow(radius: 1)
                
                Spacer().frame(height: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 50 : 40)
            }
            
            .onChange(of: geo.frame(in: .global).minY) { minY in
                
                withAnimation {
                    checkTitlePosition(geometry: geo)
                }
                           }
            
        }
        
    }
            
                .sheet(item: $activeSheet) { sheet in
                    
                    switch sheet {
                        
                    case .configureExportSheet:
                        
                        
                        
                        if job != nil {
                        
                            
                            ConfigureExportView(shifts: shifts, job: job)
                                .presentationDetents([.large])
                                .customSheetRadius(35)
                                .customSheetBackground()
                  
                        }
                        else {
                            ConfigureExportView(shifts: shifts)
                                .presentationDetents([.large])
                                .customSheetRadius(35)
                                .customSheetBackground()
                        }
                   
                        
                    case .addShiftSheet:
                        
                        if job != nil {
                            
                            
              
                            NavigationStack{
                                DetailView(job: job, presentedAsSheet: true)
                            }
                            
                            .presentationDetents([.large])
                            .customSheetBackground()
                            .customSheetRadius(35)
                        } else {
                            Text("Error")
                        }
                        
                    case .symbolSheet:
                        JobIconPicker(selectedIcon: $jobIcon, iconColor: jobColor)
                            .environment(\.managedObjectContext, viewContext)
                            .presentationDetents([ .medium, .fraction(0.7)])
                            .presentationDragIndicator(.visible)
                            .customSheetBackground()
                            .customSheetRadius(35)
                      
                    }
                    
                    
                }
            

          
        
     
        .onAppear {
            navigationState.gestureEnabled = true
            
            withAnimation {
                shiftManager.showModePicker = true
            }
            
            appeared.toggle()
            
        }
            
        // adds icon to navigation title header
        
        .overlay(alignment: .topTrailing){
            
            if showLargeIcon && job != nil {
        
                NavBarIconView(appeared: $appeared, isLarge: $showLargeIcon, icon: job?.icon ?? "", color: jobColor)
                        .padding(.trailing, 20)
                        .offset(x: 0, y: -60)
                    
            }
        }
        
       
            

            
        .navigationTitle($jobName)
        
        
        
        .onChange(of: jobName) { _ in
            
            // inefficient to change it every time, look into combine debouncing in future
            
           saveJobName()
            
         
            
        }
        
        .onChange(of: jobIcon) { _ in
            
            // inefficient to change it every time, look into combine debouncing in future
            
           saveJobIcon()
            
         
            
        }
        
        .onChange(of: jobSelectionViewModel.selectedJobUUID) { jobUUID in
            
            self.job = jobSelectionViewModel.fetchJob(with: jobUUID, in: viewContext)
            
            self.jobName = job?.name ?? "Summary"
            self.jobIcon = job?.icon ?? "briefcase.fill"
        }
        
        .fullScreenCover(isPresented: $isEditJobPresented) {
            JobView(job: job, isEditJobPresented: $isEditJobPresented, selectedJobForEditing: $job).environmentObject(ContentViewModel.shared)
                .customSheetBackground()
           
        }
            
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
            
            if !showLargeIcon && job != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu{
                        Button(action: {
                            activeSheet = .symbolSheet
                        }){
                            HStack {
                                Text("Change Icon")
                                Image(systemName: job?.icon ?? "briefcase.fill")
                            }
                        }
                    } label: {
                        NavBarIconView(appeared: $appeared, isLarge: $showLargeIcon, icon: jobIcon, color: jobColor).frame(maxHeight: 25)
                    }
                }
            }
            
            ToolbarTitleMenu {
                if job != nil {
                    RenameButton()
                }
            
                    Button(action: {
                        isEditJobPresented.toggle()
                    }){
                        HStack {
                            Text("Edit Job")
                            Image(systemName: "pencil")
                        }
                    }.disabled(job == nil || ContentViewModel.shared.shift != nil)
                    
                
                
            }
            
            
        }
             
    }
    
    private func checkTitlePosition(geometry: GeometryProxy) {
            let minY = geometry.frame(in: .global).minY
            showLargeIcon = minY > 100  // adjust this threshold as needed
        }
    
    private func saveJobName() {
            guard let job = jobSelectionViewModel.fetchJob(in: viewContext) else {
                // Handle job fetching failure
                return
            }
            
            job.name = jobName
            
            do {
                try viewContext.save()
                
                jobSelectionViewModel.updateJob(job)
                
                
            } catch {
                // Handle save error
            }
        }
    
    private func saveJobIcon() {
            guard let job = jobSelectionViewModel.fetchJob(in: viewContext) else {
                // Handle job fetching failure
                return
            }
            
            job.icon = jobIcon
            
            do {
                try viewContext.save()
                
                jobSelectionViewModel.updateJob(job)
                
                
            } catch {
                // Handle save error
            }
        }
 
}

struct NavBarIconView: View {
    
    @Binding var appeared: Bool
    @Binding var isLarge: Bool
    var icon: String
    var color: Color
    
    var body: some View {
        
        let dimension: CGFloat = isLarge ? 25 : 15
        
        Image(systemName: icon)
           
            .resizable()
            .scaledToFit()
            .frame(width: dimension, height: dimension)
            .shadow(color: .white, radius: 1.0)
            .customAnimatedSymbol(value: $appeared)
          
            .padding(isLarge ? 10 : 7)
            .foregroundStyle(Color.white)
            .background{
                Circle().foregroundStyle(color.gradient).shadow(color: color, radius: 2)
            }
            .frame(width: dimension * 2, height: dimension * 2)
          
    }
}
