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
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Job.entity(), sortDescriptors: [])
    private var jobs: FetchedResults<Job>
    @FetchRequest(entity: Tag.entity(), sortDescriptors: [])
    private var tags: FetchedResults<Tag>
    
    @State private var showJobs: Bool = false
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @AppStorage("selectedJobUUID") private var storedSelectedJobUUID: String?
    // used for sub expiry
    @AppStorage("lastSelectedJobUUID") private var lastSelectedJobUUID: String?

    
    @State private var selectedJobForEditing: Job?
    @State private var isEditJobPresented: Bool = false
    
    @State private var showAddJobView = false
    @State private var showingTagSheet = false
    @State private var showUpgradeScreen = false
    
    @Binding var currentTab: Tab
    
    var body: some View {
        
        let proColor: Color = colorScheme == .dark ? .orange : .cyan
        
        
        VStack(alignment: .leading, spacing: 0){
            
            VStack(alignment: .leading, spacing: 14){
                HStack{
                    if purchaseManager.hasUnlockedPro{
                        Text("ShiftTracker")
                            .font(.title)
                            .bold()
                        Text("PRO")
                            .font(.largeTitle)
                            .foregroundStyle(proColor.gradient)
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
                                    if purchaseManager.hasUnlockedPro || jobs.isEmpty {
                                        showAddJobView = true
                                    } else {
                                        showUpgradeScreen = true
                                    }
                                }) {
                                    Image(systemName: "plus").customAnimatedSymbol(value: $showAddJobView)
                                        .bold()
                                }.padding(.trailing)
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .haptics(onChangeOf: showAddJobView, type: .light)
                        
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
                                            if purchaseManager.hasUnlockedPro
                                                || jobSelectionViewModel.selectedJobUUID == job.uuid
                                                || (job.uuid?.uuidString == lastSelectedJobUUID)
                                                || (lastSelectedJobUUID == nil) {
                                                if !(jobSelectionViewModel.selectedJobUUID == job.uuid) {
                                                    jobSelectionViewModel.selectJob(job, with: jobs, shiftViewModel: viewModel)
                                                    lastSelectedJobUUID = job.uuid?.uuidString
                                                } else {
                                                    jobSelectionViewModel.deselectJob(shiftViewModel: viewModel)
                                                }

                                                withAnimation(.easeInOut) {
                                                    navigationState.showMenu = false
                                                }
                                            } else {
                                  
                                                showUpgradeScreen = true
                                            }
                                        }


                                        
                                    }.padding(.horizontal, 8)
                                        .padding(.vertical, 10)
                                    
                                    
                                    
                                    
                                        .glassModifier(cornerRadius: 50)
                                    
                                        .shadow(radius: jobSelectionViewModel.selectedJobUUID == job.uuid ? 5 : 0)
                                    
                                    
                                        .opacity(purchaseManager.hasUnlockedPro
                                                 || jobSelectionViewModel.selectedJobUUID == job.uuid
                                                 || (job.uuid?.uuidString == lastSelectedJobUUID)
                                                 || (lastSelectedJobUUID == nil)
                                            ? 1.0
                                            : 0.5)
                                    
                                    
                                    
                                    
                                    
                                }
                                
                                .fullScreenCover(item: $selectedJobForEditing) { job in
                                    JobView(job: job, isEditJobPresented: $isEditJobPresented, selectedJobForEditing: $selectedJobForEditing)
                                        .onDisappear {
                                            selectedJobForEditing = nil
                                        }
                                        .presentationBackground(.ultraThinMaterial)
                                }
                                
                                
                                
                                .haptics(onChangeOf: selectedJobForEditing, type: .light)
                                
                                
                                
                            }
                            
                            
                        } .transition(.move(edge: .top))
                            .haptics(onChangeOf: jobSelectionViewModel.selectedJobUUID, type: .light)
                        
                        
                        
                    }
                    .padding()
                    .padding(.leading)
                    .padding(.top, 35)
                    
                    
                    
                }
            }
            
            VStack{
                HStack(spacing: 8){

                    Button(action: {
                        
                        showingTagSheet = true
                        
                    }){
                        HStack(spacing: 8){
                            Image(systemName: "tag.fill")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 20, height: 20)
                                .customAnimatedSymbol(value: $showingTagSheet)
                            
                            Text("Tags")
                                .font(.title2)
                                .bold()
                            
                            
                            Image(systemName: "plus").customAnimatedSymbol(value: $showingTagSheet)
                                .bold()
                            
                            
                        }
                        
                    }.padding(.top, 1)
                    .haptics(onChangeOf: showingTagSheet, type: .light)
                    Spacer()
                }
                
            }.padding()
            
                .sheet(isPresented: $showingTagSheet){
                    
                    AddTagView()
                        .presentationDetents([.medium])
                        .presentationCornerRadius(35)
                        .presentationBackground(.ultraThinMaterial)
                    
                }
            
            
            VStack{
                
                if !purchaseManager.hasUnlockedPro{
                    
                    Divider()
                    
                    Button(action: { showUpgradeScreen.toggle()}){
                        HStack(spacing: 25) {
                            Image(systemName: "plus.diamond.fill")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 30, height: 30)
                            Text("Upgrade")
                                .font(.largeTitle)
                                .bold()
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .padding(.leading)
                }
                    
                
                
                
            }
            
        }
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(width: getRect().width-90)
        .frame(maxHeight: .infinity)
        .glassModifier(cornerRadius: 20)
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
            JobView(isEditJobPresented: $isEditJobPresented, selectedJobForEditing: .constant(nil))
            
                .presentationBackground(.ultraThinMaterial)
            
        }
        
        .fullScreenCover(isPresented: $showUpgradeScreen){
      
            ProView()
               
                .presentationBackground(.ultraThinMaterial)
        
        }
        
    }
    
    @ViewBuilder
    func TabButton(title: String, image: String, destination: @escaping () -> AnyView) -> some View {
        NavigationLink(destination: destination().toolbar(.hidden)) {
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
       // MainWithSideBarView(currentTab: .constant(.home))
        MainWithSideBarView()
    }
}




