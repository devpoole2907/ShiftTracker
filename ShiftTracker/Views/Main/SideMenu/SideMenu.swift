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
    
    @StateObject var menuModel = MenuViewModel()
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Job.entity(), sortDescriptors: [])
    private var jobs: FetchedResults<Job>
    
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            
            menuTitle
            
            ScrollView(.vertical, showsIndicators: false){
                VStack{
                    VStack(alignment: .leading, spacing: 30) {
                        jobsHeader
                        jobsList
                            .transition(.move(edge: .top))
                            .haptics(onChangeOf: selectedJobManager.selectedJobUUID, type: .light)
                    }
                    .padding()
                    .padding(.leading)
                    .padding(.top, 35)
                }
            }
            
            tagButton
            
            
            upgradeButton.environmentObject(purchaseManager)
            
        }
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(width: getRect().width-90)
        .frame(maxHeight: .infinity)
        .glassModifier(cornerRadius: 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            // Initialize the selected job to be the stored job when the view appears
            if let storedUUIDString = menuModel.storedSelectedJobUUID,
               let storedUUID = UUID(uuidString: storedUUIDString),
               let storedJob = jobs.first(where: { $0.uuid == storedUUID }) {
                selectedJobManager.selectedJobUUID = storedJob.uuid
                viewModel.selectedJobUUID = storedJob.uuid
            }
        }
        
        
        .fullScreenCover(isPresented: $menuModel.showAddJobView){
            JobView(isEditJobPresented: $menuModel.isEditJobPresented)
            
                .customSheetBackground()
            
        }
        
        .fullScreenCover(isPresented: $menuModel.showUpgradeScreen){
            
            ProView()
            
                .customSheetBackground()
            
        }
        
    }
    
    var upgradeButton: some View {
        
        return VStack{
            
            if !purchaseManager.hasUnlockedPro{
                
                Divider()
                
                Button(action: { menuModel.showUpgradeScreen.toggle()}){
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
    
    var menuTitle: some View {
        
        let proColor: Color = colorScheme == .dark ? .orange : .cyan
        
        return VStack(alignment: .leading, spacing: 14){
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
    }
    
    var jobsHeader: some View {
        return HStack(spacing: 25) {
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
                    menuModel.showAddJobView = true
                } else {
                    menuModel.showUpgradeScreen = true
                }
            }) {
                Image(systemName: "plus").customAnimatedSymbol(value: $menuModel.showAddJobView)
                    .bold()
            }.padding(.trailing)
        }
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .haptics(onChangeOf: menuModel.showAddJobView, type: .light)
    }
    
    var jobsList: some View {
        return  LazyVStack(alignment: .leading, spacing: 10){
            ForEach(jobs) { job in
                
                
                
                VStack(spacing: 0) {
                    JobRow(job: job, isSelected: selectedJobManager.selectedJobUUID == job.uuid, editAction: {
                        menuModel.selectedJobForEditing = job
                        menuModel.isEditJobPresented = true
                    }, showEdit: true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if purchaseManager.hasUnlockedPro
                            || selectedJobManager.selectedJobUUID == job.uuid
                            || (job.uuid?.uuidString == menuModel.lastSelectedJobUUID)
                            || (menuModel.lastSelectedJobUUID == nil) {
                            if !(selectedJobManager.selectedJobUUID == job.uuid) {
                                selectedJobManager.selectJob(job, with: jobs, shiftViewModel: viewModel)
                                menuModel.lastSelectedJobUUID = job.uuid?.uuidString
                            } else {
                                withAnimation {
                                    selectedJobManager.deselectJob(shiftViewModel: viewModel)
                                }
                            }
                            
                            withAnimation(.easeInOut) {
                                navigationState.showMenu = false
                            }
                        } else {
                            
                            menuModel.showUpgradeScreen = true
                        }
                    }
                    
                    
                    
                }.padding(.horizontal, 8)
                    .padding(.vertical, 10)
                
                
                
                
                    .glassModifier(cornerRadius: 50)
                
                    .shadow(radius: selectedJobManager.selectedJobUUID == job.uuid ? 5 : 0)
                
                
                    .opacity(purchaseManager.hasUnlockedPro
                             || selectedJobManager.selectedJobUUID == job.uuid
                             || (job.uuid?.uuidString == menuModel.lastSelectedJobUUID)
                             || (menuModel.lastSelectedJobUUID == nil)
                             ? 1.0
                             : 0.5)
                
                
                
                
                
            }
            
            .fullScreenCover(item: $menuModel.selectedJobForEditing) { job in
                JobView(job: job, isEditJobPresented: $menuModel.isEditJobPresented, selectedJobForEditing: $menuModel.selectedJobForEditing)
                    .onDisappear {
                        menuModel.selectedJobForEditing = nil
                    }
                    .customSheetBackground()
            }
            
            
            
            .haptics(onChangeOf: menuModel.selectedJobForEditing, type: .light)
            
            
            
        }
    }
    
    var tagButton: some View {
        return VStack{
            HStack(spacing: 8){
                
                Button(action: {
                    
                    menuModel.showingTagSheet = true
                    
                }){
                    HStack(spacing: 8){
                        Image(systemName: "tag.fill")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 20, height: 20)
                            .customAnimatedSymbol(value: $menuModel.showingTagSheet)
                        
                        Text("Tags")
                            .font(.title2)
                            .bold()
                        
                        
                        Image(systemName: "plus").customAnimatedSymbol(value: $menuModel.showingTagSheet)
                            .bold()
                        
                        
                    }
                    
                }.padding(.top, 1)
                    .haptics(onChangeOf: menuModel.showingTagSheet, type: .light)
                Spacer()
            }
            
        }.padding()
            .sheet(isPresented: $menuModel.showingTagSheet){
                
                AddTagView()
                    .presentationDetents([.medium])
                    .customSheetRadius(35)
                    .customSheetBackground()
                
            }
    }
    
}






