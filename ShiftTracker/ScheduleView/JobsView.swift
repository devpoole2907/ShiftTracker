//
//  JobsView.swift
//  ShiftTracker
//
//  Created by James Poole on 28/04/23.
//


// no longer used

import SwiftUI
import Haptics
import UIKit
import CoreLocation
import MapKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth
import PopupView


struct JobsView: View {
    
    
    @ObservedObject var model = JobsViewModel()
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var firebaseJobs: [JobData] = []
    
    @Environment(\.managedObjectContext) private var viewContext
       @FetchRequest(entity: Job.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]) private var jobs: FetchedResults<Job>
    
    @State private var showAddJobView = false
    
    @State private var dateSelected: DateComponents?
    @State private var displayEvents = false
    
    @State private var deleteJobAlert = false
    @State private var jobToDelete: Job?
    
    @State private var showAllScheduledShiftsView = false
    
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    
    init(){
        model.getData()
    }

    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        
        if isSubscriptionActive() {
            List {
                if !model.firebaseJobs.isEmpty{
                    ForEach(model.firebaseJobs) { job in
                        
                        NavigationLink(destination: EditFirebaseJobView(job: job)){
                            Section{
                                HStack(spacing : 25){
                                    Image(systemName: job.icon ?? "briefcase.circle")
                                        .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                                        .font(.system(size: 50))
                                        .frame(width: UIScreen.main.bounds.width / 7)
                                    VStack(alignment: .leading, spacing: 5){
                                        
                                        Text(job.name ?? "")
                                        //.foregroundColor(.white)
                                            .font(.title2)
                                            .bold()
                                        Text(job.title ?? "")
                                        //.foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                                        //.foregroundColor(.white)
                                            .font(.subheadline)
                                            .bold()
                                        Text("$\(job.hourlyPay, specifier: "%.2f") / hr")
                                            .foregroundColor(.gray)
                                            .font(.footnote)
                                            .bold()
                                    }
                                    
                                }//.frame(maxWidth: .infinity)
                                .padding()
                                
                            }
                        }.listRowBackground(Color.primary.opacity(0.05))
                    } .onDelete { indexSet in
                        if let index = indexSet.first {
                            let job = model.firebaseJobs[index]
                            ConfirmFirebaseJobDeletion(action: model.deleteData(jobToDelete:), jobToDelete: job).present()
                        }
                    }
                    
                    
                    
                    
                    
                }
                // .listRowBackground(Color.black)
                
                
                /*   if !jobs.isEmpty{
                 ForEach(jobs, id: \.self) { job in
                 Section{
                 NavigationLink(destination: EditJobView(job: job)){
                 
                 HStack(spacing : 10){
                 Image(systemName: job.icon ?? "briefcase.circle")
                 .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                 .font(.system(size: 30))
                 .frame(width: UIScreen.main.bounds.width / 7)
                 VStack(alignment: .leading, spacing: 5){
                 Text(job.name ?? "")
                 .foregroundColor(textColor)
                 .font(.title2)
                 .bold()
                 Text(job.title ?? "")
                 .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                 .font(.subheadline)
                 .bold()
                 Text("$\(job.hourlyPay, specifier: "%.2f") / hr")
                 .foregroundColor(.gray)
                 .font(.footnote)
                 .bold()
                 }
                 
                 }
                 }
                 }
                 .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                 .listRowBackground(Color.primary.opacity(0.05))
                 }
                 .onDelete(perform: deleteJob)
                 
                 
                 
                 
                 
                 } */
                else {
                    
                    
                    
                    Section {
                        VStack(alignment: .center, spacing: 15){
                            Text("No jobs found.")
                                .font(.title3)
                                .bold()
                            
                            
                            NavigationLink(destination: AddJobView()){
                                Text("Create one now")
                                    .bold()
                                    .foregroundColor(.orange)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 85)
                            
                        } .frame(maxWidth: .infinity)
                            .padding()
                    }
                    
                }
                
                
                
                //.listRowBackground(Color.clear)
                
                
            }.scrollContentBackground(.hidden)
            
            
            
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: AddJobView()) {
                            Image(systemName: "plus").bold()
                        }
                    }
                }
                .toolbarRole(.editor)
            
            // .navigationBarHidden(true)
                .onAppear {
                    if isSubscriptionActive() {
                        model.getData()
                    }
                }
            
        }
        else {
            List {
                if !jobs.isEmpty{
                    ForEach(jobs, id: \.self) { job in
                        
                        NavigationLink(destination: EditJobView(job: job)){
                            Section{
                                HStack(spacing : 25){
                                    Image(systemName: job.icon ?? "briefcase.circle")
                                        .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                                        .font(.system(size: 50))
                                        .frame(width: UIScreen.main.bounds.width / 7)
                                    VStack(alignment: .leading, spacing: 5){
                                        
                                        Text(job.name ?? "")
                                        //.foregroundColor(.white)
                                            .font(.title2)
                                            .bold()
                                        Text(job.title ?? "")
                                        //.foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                                        //.foregroundColor(.white)
                                            .font(.subheadline)
                                            .bold()
                                        Text("$\(job.hourlyPay, specifier: "%.2f") / hr")
                                            .foregroundColor(.gray)
                                            .font(.footnote)
                                            .bold()
                                    }
                                    
                                }//.frame(maxWidth: .infinity)
                                .padding()
                                
                            }
                        }.listRowBackground(Color.primary.opacity(0.05))
                    } .onDelete { indexSet in
                        ConfirmJobDeletion(action: deleteJob, indexSet: indexSet).present()
                    }

                    
                    
                    
                    
                    
                }
                // .listRowBackground(Color.black)
                
                
                /*   if !jobs.isEmpty{
                 ForEach(jobs, id: \.self) { job in
                 Section{
                 NavigationLink(destination: EditJobView(job: job)){
                 
                 HStack(spacing : 10){
                 Image(systemName: job.icon ?? "briefcase.circle")
                 .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                 .font(.system(size: 30))
                 .frame(width: UIScreen.main.bounds.width / 7)
                 VStack(alignment: .leading, spacing: 5){
                 Text(job.name ?? "")
                 .foregroundColor(textColor)
                 .font(.title2)
                 .bold()
                 Text(job.title ?? "")
                 .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                 .font(.subheadline)
                 .bold()
                 Text("$\(job.hourlyPay, specifier: "%.2f") / hr")
                 .foregroundColor(.gray)
                 .font(.footnote)
                 .bold()
                 }
                 
                 }
                 }
                 }
                 .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                 .listRowBackground(Color.primary.opacity(0.05))
                 }
                 .onDelete(perform: deleteJob)
                 
                 
                 
                 
                 
                 } */
                else {
                    
                    
                    
                    Section {
                        VStack(alignment: .center, spacing: 15){
                            Text("No jobs found.")
                                .font(.title3)
                                .bold()
                            
                            
                            NavigationLink(destination: AddJobView()){
                                Text("Create one now")
                                    .bold()
                                    .foregroundColor(.orange)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 85)
                            
                        } .frame(maxWidth: .infinity)
                            .padding()
                    }
                    
                }
                
                
                
                //.listRowBackground(Color.clear)
                
                
            }.scrollContentBackground(.hidden)
            
            
            
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: AddJobView()) {
                            Image(systemName: "plus").bold()
                        }
                    }
                }
                .toolbarRole(.editor)
            
            // .navigationBarHidden(true)
                .onAppear {
                    if isSubscriptionActive() {
                        model.getData()
                    }
                }
        }
        
    }


    
    func deleteJob(indexSet: IndexSet) {
            // Delete job from Core Data
            for index in indexSet {
                let job = jobs[index]
                viewContext.delete(job)
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting job from Core Data: \(error.localizedDescription)")
            }
        
    }



    
    private func confirmDeleteJob() {
        if let job = jobToDelete {
            // Delete associated ScheduledShifts
            if let scheduledShifts = job.scheduledShifts as? Set<ScheduledShift> {
                        for shift in scheduledShifts {
                            viewContext.delete(shift)
                        }
                    }

                    // Delete the job
            sharedUserDefaults.removeObject(forKey: "SelectedJobUUID")
            deleteJobFromWatch(job)
                    viewContext.delete(job)
                    jobToDelete = nil
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete job: \(error.localizedDescription)")
            }
        }
        deleteJobAlert = false
    }
    
    func deleteJobFromWatch(_ job: Job) {
        if let jobId = job.uuid {
            WatchConnectivityManager.shared.sendDeleteJobMessage(jobId)
        }
    }


    
}

struct JobsView_Previews: PreviewProvider {
    static var previews: some View {
        JobsView()
    }
}


struct ConfirmFirebaseJobDeletion: CentrePopup {
    let action: (FirebaseJob) -> ()
        let jobToDelete: FirebaseJob
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        VStack(spacing: 5) {
      
            createTitle()
                .padding(.vertical)
            
            createDescription()
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

private extension ConfirmFirebaseJobDeletion {

    func createTitle() -> some View {
        Text("Are you sure?")
            .bold()
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    func createDescription() -> some View {
        Text("Any shifts scheduled for this job will be deleted.")
                    //.foregroundColor(.onBackgroundSecondary)
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

private extension ConfirmFirebaseJobDeletion {
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
            action(jobToDelete)
            dismiss()
        }) {
            Text("Delete")
                .bold()
                .foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
    }
}

struct ConfirmJobDeletion: CentrePopup {
    let action: (IndexSet) -> ()
        let indexSet: IndexSet
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        VStack(spacing: 5) {
      
            createTitle()
                .padding(.vertical)
            
            createDescription()
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

private extension ConfirmJobDeletion {

    func createTitle() -> some View {
        Text("Are you sure?")
            .bold()
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    func createDescription() -> some View {
        Text("Any shifts scheduled for this job will be deleted.")
                    //.foregroundColor(.onBackgroundSecondary)
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

private extension ConfirmJobDeletion {
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
            action(indexSet)
            dismiss()
        }) {
            Text("Delete")
                .bold()
                .foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
    }
}
