//
//  SideMenu.swift
//  ShiftTracker
//
//  Created by James Poole on 28/04/23.
//

import SwiftUI
import PopupView
import Haptics


struct SideMenu: View {
    
    @AppStorage("isProVersion", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isProVersion = false
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Job.entity(), sortDescriptors: [])
    private var jobs: FetchedResults<Job>
    
    @State private var showJobs: Bool = false
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var themeManager: ThemeDataManager
    
    @AppStorage("selectedJobUUID") private var storedSelectedJobUUID: String?
    
    @State private var selectedJobForEditing: Job?
    @State private var isEditJobPresented: Bool = false
    
    @State private var showAddJobView = false
    @State private var showUpgradeScreen = false
    
    var body: some View {
        
        
        let jobBackground: Color = colorScheme == .dark ? Color(.systemGray5) : .black
        
        let proColor: Color = colorScheme == .dark ? .orange : .cyan
        
        
        VStack(alignment: .leading, spacing: 0){
            
            VStack(alignment: .leading, spacing: 14){
                HStack{
                    if isProVersion{
                        Text("ShiftTracker")
                            .font(.title)
                            .bold()
                        Text("PRO")
                            .font(.largeTitle)
                            .foregroundColor(proColor)
                            .bold()
                    } else {
                        Text("ShiftTracker")
                            .font(.largeTitle)
                            .bold()
                    }
                    
                }
                
            }
  
            .padding(.leading)
            
            ScrollView(.vertical, showsIndicators: false){
                VStack{
               /*     if viewModel.shift != nil{
                        TimerView(timeElapsed: $viewModel.timeElapsed)
                            .scaleEffect(0.8)
                    } */
                    VStack(alignment: .leading, spacing: 30) {
                        
                            HStack(spacing: 25) {
                                Image(systemName: "briefcase.fill")
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 30, height: 30)
                                Text("Jobs")
                                    .font(.largeTitle)
                                    .bold()
                                Spacer()
                                Button(action: {
                                    if isSubscriptionActive() || jobs.isEmpty {
                                        showAddJobView = true
                                    } else {
                                        showUpgradeScreen = true
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .bold()
                                }.padding(.trailing)
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack{
                          //  if isJobsExpanded {
                                VStack(alignment: .leading, spacing: 10){
                                    ForEach(jobs) { job in
                                        
                                        
                                        
                                        VStack(spacing: 0) {
                                            JobRow(job: job, isSelected: jobSelectionViewModel.selectedJobUUID == job.uuid, editAction: {
                                                selectedJobForEditing = job
                                                isEditJobPresented = true
                                            }, showEdit: true)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                
                                                if !(jobSelectionViewModel.selectedJobUUID == job.uuid) {
                                                    jobSelectionViewModel.selectJob(job, with: jobs, shiftViewModel: viewModel)
                                                    
                                                } else {
                                                    jobSelectionViewModel.deselectJob()
                                                }
                                                
                                                withAnimation(.easeInOut) {
                                                    
                                                    navigationState.showMenu = false
                                                    
                                                }
                                                
                                            }
                                            
                                        }.padding()
                                            .background(jobSelectionViewModel.selectedJobUUID == job.uuid ? jobBackground : Color.primary.opacity(0.04))
                                            .cornerRadius(50)
                                        
                                    }
                                    
                                    .fullScreenCover(item: $selectedJobForEditing) { job in
                                        JobView(job: job)
                                            .onDisappear {
                                                selectedJobForEditing = nil
                                            }
                                    }
                                    
                                    
                                /*    Button(action: {
                                        if isSubscriptionActive() || jobs.isEmpty {
                                            showAddJobView = true
                                        } else {
                                            showUpgradeScreen = true
                                        }
                                    }) {
                                        Image(systemName: "plus")
                                            .resizable()
                                            .frame(width: 25, height: 25)
                                            .padding(.leading, 40)
                                    }.padding()
                                        .frame(alignment: .leading)*/
                                    
                                }
                                //  }
                          /*  else if let selectedJob = findSelectedJob() {
                                VStack(spacing: 0) {
                                    JobRow(job: selectedJob, isSelected: jobSelectionViewModel.selectedJobUUID == selectedJob.uuid, editAction: {
                                        selectedJobForEditing = selectedJob
                                        isEditJobPresented = true
                                    }, showEdit: false)
                                    .contentShape(Rectangle()) // Make the whole row tappable
                                    
                                }.padding()
                                    .background(jobSelectionViewModel.selectedJobUUID == selectedJob.uuid ? jobBackground : Color.primary.opacity(0.04))
                                    .cornerRadius(50)
                                    .padding(.leading, 40)
                            } else {
                                // Handle the case when the selected job is not found
                                Text("No job selected")
                                    .bold()
                            }*/
                            
                            
                        } .transition(.move(edge: .top))
                            .haptics(onChangeOf: jobSelectionViewModel.selectedJobUUID, type: .light)
                        
                        
                        if !isSubscriptionActive(){
                            TabButton(title: "Upgrade", image: "plus.diamond.fill", destination: { AnyView(
                                ProView().toolbarRole(.editor)
                            ) })
                        }
                    }
                    .padding()
                    .padding(.leading)
                    .padding(.top, 35)
                    
                    
                    
                }
            }
            VStack{
                Divider()
                
                TabButton(title: "Settings", image: "gearshape.fill", destination: { AnyView(SettingsView().environmentObject(themeManager)) })
                    .padding()
                    .padding(.leading)
                
                
                
            }
            
        }
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(width: getRect().width-90)
        .frame(maxHeight: .infinity)
        .background(
            Color.primary
                .opacity(0.04)
                .ignoresSafeArea(.container, edges: .vertical))
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            // Initialize the selected job to be the stored job when the view appears
            if let storedUUIDString = storedSelectedJobUUID,
               let storedUUID = UUID(uuidString: storedUUIDString),
               let storedJob = jobs.first(where: { $0.uuid == storedUUID }) {
                jobSelectionViewModel.selectedJobUUID = storedJob.uuid
                viewModel.selectedJobUUID = storedJob.uuid
            }
        }
        
        
        .fullScreenCover(isPresented: $showAddJobView){
            JobView()
        }
        
        .fullScreenCover(isPresented: $showUpgradeScreen){
            NavigationStack{
            ProView()
                .toolbar{
                    ToolbarItem(placement: .navigationBarLeading){
                        CloseButton{
                            self.showUpgradeScreen = false
                        }
                    }
                }
        }
        }
        
    }
    
    @ViewBuilder
    func TabButton(title: String, image: String, destination: @escaping () -> AnyView) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 25) {
                Image(systemName: image)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30)
                Text(title)
                    .font(.largeTitle)
                    .bold()
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    func findSelectedJob() -> Job? {
        return jobs.first(where: { $0.uuid == viewModel.selectedJobUUID })
        
    }
    
    private func deleteJob(_ job: Job) {
        viewContext.delete(job)
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
}

struct SideMenu_Previews: PreviewProvider {
    static var previews: some View {
        MainWithSideBarView(currentTab: .constant(.home))
    }
}

extension View {
    func getRect()->CGRect {
        return UIScreen.main.bounds
    }
}

struct JobRow: View {
    let job: Job
    let isSelected: Bool
    let editAction: () -> Void
    var showEdit: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: ContentViewModel
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        HStack {
            
            Image(systemName: job.icon ?? "briefcase.circle")
                .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
            
            Text(job.name ?? "")
                .bold()
                .foregroundColor(isSelected ? .white : textColor)
                .lineLimit(1)
                .allowsTightening(true)
            Spacer()
            if showEdit{
                Button(action: {
                    if (isSelected && viewModel.shift == nil) || !isSelected {
                        editAction()
                    }
                    else {
                        OkButtonPopup(title: "End your current shift before editing.", action: nil).showAndStack()
                    }}) {
                        Image(systemName: "pencil")
                            .foregroundColor(isSelected ? .white : textColor)
                    }
            }
            
            
        }
    }
}
