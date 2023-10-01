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
    
    @State private var jobIcon: String = "briefcase.fill"
    @State private var showLargeIcon = true
    @State private var appeared: Bool = false // for icon tap
    @State private var isEditJobPresented: Bool = false
    
    @State private var job: Job?
    @State private var jobName: String = "Summary"
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var navigationState: NavigationState
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    let shiftStore = ShiftStore()
    
    func generateTestData() {

        guard let selectedJob = jobSelectionViewModel.fetchJob(in: viewContext) else { return }
        var currentDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        for _ in 0..<300 {
            let oldShift = OldShift(context: viewContext)
            
            let duration = Int.random(in: 2...12) * 3600  
            let endDate = Calendar.current.date(byAdding: .second, value: duration, to: currentDate)!
            
            oldShift.shiftStartDate = currentDate
            oldShift.shiftEndDate = endDate
            oldShift.duration = Double(duration)
            oldShift.totalPay = Double.random(in: 100...300)
            oldShift.taxedPay = oldShift.totalPay * 0.9
            oldShift.tax = 0.1
            oldShift.job = selectedJob

            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!

            do {
                try viewContext.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    
    
    @State private var activeSheet: ActiveSheet?
    
    private enum ActiveSheet: Identifiable {
        case addShiftSheet, configureExportSheet, symbolSheet
        
        var id: Int {
            hashValue
        }
    }
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    @FetchRequest var weeklyShifts: FetchedResults<OldShift>
    @FetchRequest var lastTenShifts: FetchedResults<OldShift>
    
    init(navPath: Binding<NavigationPath>, job: Job? = nil){
        print("job overview itself got reinitialised")
        
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        let weekFetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        let lastTenFetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        if let jobID = job?.objectID {
            fetchRequest.predicate = NSPredicate(format: "job == %@", jobID)
            
            
            let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date().endOfDay) ?? Date()
            
            let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "job == %@", jobID), NSPredicate(format: "shiftStartDate >= %@", oneWeekAgo as NSDate)])
            
            weekFetchRequest.predicate = compoundPredicate
            
            lastTenFetchRequest.predicate = NSPredicate(format: "job == %@", jobID)
            
            
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        weekFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        lastTenFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        _shifts = FetchRequest(fetchRequest: fetchRequest)
        _weeklyShifts = FetchRequest(fetchRequest: weekFetchRequest)
        
        lastTenFetchRequest.fetchLimit = 10
        
        _lastTenShifts = FetchRequest(fetchRequest: lastTenFetchRequest)
        
        
        
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
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        let jobColor = Color(red: Double(job?.colorRed ?? 0.0), green: Double(job?.colorGreen ?? 0.0), blue: Double(job?.colorBlue ?? 0.0))
        
        
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing){
                List{
                    
                   
                    VStack(alignment: .leading, spacing: 0){
                        HStack(spacing: 8){
                            VStack(spacing: 0) {
                                
                                StatsSquare(shifts: shifts, shiftsThisWeek: weeklyShifts)
                                    .environmentObject(shiftManager)
                                
                                Spacer()
                                
                                ChartSquare(shifts: weeklyShifts)
                                    .environmentObject(shiftManager)
                                
                            }
                            
                            
                            ExportSquare(totalShifts: shifts.count, action: {
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
                        
                        ForEach(lastTenShifts, id: \.self) { shift in
                            
                            NavigationLink(value: shift) {
                                ShiftDetailRow(shift: shift)
                            }
                            
                        
                   
                            
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
            
            .navigationDestination(for: OldShift.self) { shift in
                DetailView(shift: shift, navPath: $navPath)
                    .onAppear {
                        withAnimation {
                            shiftManager.showModePicker = false
                        }
                    }
                
            }
            
            .navigationDestination(for: Int.self) { value in
                
                if value == 1 {
                    ShiftsList(navPath: $navPath).environmentObject(jobSelectionViewModel).environmentObject(shiftManager).environmentObject(navigationState).environmentObject(sortSelection)
                    
                        .onAppear {
                            withAnimation {
                                shiftManager.showModePicker = false
                            }
                        }
                    
                } else if value == 2 {
                    
                    
                    UpdatedHistoryPagesView(navPath: $navPath)
                    
                    
                    
                    
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
                    .offset(x: 0, y: -55)
                
            }
        }
        
        
        
        
        
        .navigationTitle($jobName)
        
        .onChange(of: jobName) { _ in
            
            // inefficient to change it every time, look into combine debouncing in future
            
            saveJobName()
            
            
            
        }
        
        .onChange(of: jobIcon) { _ in
            
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
            
            
            ToolbarItem(placement: .topBarLeading){
                Button{
                    withAnimation{
                        navigationState.showMenu.toggle()
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .bold()
                    
                }
            }
            
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    generateTestData()
                }){
                    Text("Test Data")
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
            .frame(width: dimension * 1.8, height: dimension * 1.8)
        
    }
}
