//
//  SideMenu.swift
//  ShiftTracker
//
//  Created by James Poole on 28/04/23.
//

import SwiftUI
import PopupView


struct SideMenu: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var showMenu: Bool
    
    @EnvironmentObject var authModel: FirebaseAuthModel
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Job.entity(), sortDescriptors: [])
    private var jobs: FetchedResults<Job>
    
    @State private var showJobs: Bool = false
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    
    
    
    @AppStorage("selectedJobUUID") private var storedSelectedJobUUID: String?
    
    
    
    @State private var isJobsExpanded: Bool = false
    
    @State private var selectedJobForEditing: Job?
    @State private var isEditJobPresented: Bool = false
    
    @State private var showAddJobView = false
    
    var body: some View {
        
        
        let jobBackground: Color = colorScheme == .dark ? Color(.systemGray5) : .black
        
        
        VStack(alignment: .leading, spacing: 0){
            
            VStack(alignment: .leading, spacing: 14){
                
                Text("ShiftTracker")
                    .font(.largeTitle)
                    .bold()
                
                
            }
            .padding(.horizontal)
            .padding(.leading)
            
            ScrollView(.vertical, showsIndicators: false){
                VStack{
                    VStack(alignment: .leading, spacing: 30) {
                        Button(action: {
                            withAnimation(.easeInOut) {
                                isJobsExpanded.toggle()
                            }
                        }) {
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
                                Image(systemName: isJobsExpanded ? "chevron.up" : "chevron.down")
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        VStack{
                            if isJobsExpanded {
                                VStack(spacing: 10){
                                    ForEach(jobs) { job in
                                        
                                        
                                        
                                        VStack(spacing: 0) {
                                            JobRow(job: job, isSelected: jobSelectionViewModel.selectedJobUUID == job.uuid, editAction: {
                                                selectedJobForEditing = job
                                                isEditJobPresented = true
                                            }, showEdit: true)
                                            .contentShape(Rectangle()) // Make the whole row tappable
                                            .onTapGesture {
                                                jobSelectionViewModel.selectJob(job, with: jobs, shiftViewModel: viewModel)
                                            }
                                            
                                        }.padding()
                                            .background(jobSelectionViewModel.selectedJobUUID == job.uuid ? jobBackground : Color.primary.opacity(0.04))
                                            .cornerRadius(50)
                                            .offset(y: isJobsExpanded ? 0 : jobSelectionViewModel.selectedJobOffset)
                                            .animation(.spring(), value: isJobsExpanded)
                                        
                                    }
                                    .padding(.leading, 40)
                                    
                                    .fullScreenCover(item: $selectedJobForEditing) { job in
                                        EditJobView(job: job)
                                            .onDisappear {
                                                selectedJobForEditing = nil
                                            }
                                    }
                                }
                            }
                            else if let selectedJob = findSelectedJob() {
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
                                    .foregroundColor(.black)
                            }
                            
                            
                        } .transition(.move(edge: .top))
                        
                        Button(action: {
                            showAddJobView = true
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .padding(.leading, 40)
                        }
                        
                        
                        TabButton(title: "Upgrade", image: "plus.diamond.fill", destination: { AnyView(ProView()) })
                    }
                    .padding()
                    .padding(.leading)
                    .padding(.top, 35)
                    
                    
                    
                }
            }
            VStack{
                Divider()
                
                TabButton(title: "Settings", image: "gearshape.fill", destination: { AnyView(SettingsView()) })
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
            AddJobView()
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
        MainWithSideBarView()
    }
}

extension View {
    func getRect()->CGRect {
        return UIScreen.main.bounds
    }
}

struct LogOutPopUp: CentrePopup {
    let logoutAction: () -> Void
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        VStack(spacing: 5) {
            
            createTitle()
                .padding(.vertical)
            //Spacer(minLength: 32)
            //  Spacer.height(32)
            createButtons()
            // .padding()
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background(.primary.opacity(0.05))
    }
}

private extension LogOutPopUp {
    
    func createTitle() -> some View {
        Text("Are you sure you want to log out?")
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    func createButtons() -> some View {
        HStack(spacing: 4) {
            createCancelButton()
            createUnlockButton()
        }
    }
}

private extension LogOutPopUp {
    func createCancelButton() -> some View {
        Button(action: dismiss) {
            Text("Cancel")
            
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.primary.opacity(0.1))
                .cornerRadius(8)
        }
    }
    func createUnlockButton() -> some View {
        Button(action: {
            logoutAction()
            dismiss()
        }) {
            Text("Logout")
                .bold()
                .foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
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
            Spacer()
            if showEdit{
                Button(action: {
                    if (isSelected && viewModel.shift == nil) || !isSelected {
                        editAction()
                    }
                    else {
                        OkButtonPopup(title: "End your current shift before editing.").present()
                    }}) {
                        Image(systemName: "pencil")
                            .foregroundColor(isSelected ? .white : textColor)
                    }
            }
            
            
        }
    }
}


/*
 Button(action: {
 //
 
 LogOutPopUp(logoutAction: authModel.signOut).present()
 
 }) {
 Text("Logout")
 .bold()
 .padding()
 .padding(.leading)
 
 }
 .frame(maxWidth: .infinity, alignment: .leading)
 
 */

//  TabButton(title: "Profile", image: "person.fill", destination: { AnyView(SettingsView()) })
