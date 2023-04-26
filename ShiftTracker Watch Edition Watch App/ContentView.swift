//
//  ContentView.swift
//  ShiftTracker Watch Edition Watch App
//
//  Created by James Poole on 25/04/23.
//

import SwiftUI
import WatchConnectivity
import CoreData
import CloudKit


struct ContentView: View {
    
    private let connectivityManager = WatchConnectivityManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    
    
    @FetchRequest(
            entity: Job.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]
        ) private var jobs: FetchedResults<Job>
    
    @State private var showAlert = false
    @State private var jobToDelete: Job?
    
    private func deleteJob(at offsets: IndexSet) {
        if let index = offsets.first {
            jobToDelete = jobs[index]
            showAlert = true
        }
    }
    
    private func confirmDelete() {
        if let job = jobToDelete {
            viewContext.delete(job)
            do {
                try viewContext.save()
                connectivityManager.deleteJob(job)
            } catch {
                print("Failed to delete job: \(error.localizedDescription)")
            }
        }
        jobToDelete = nil
        showAlert = false
    }
    
    var body: some View {
        NavigationStack{
            List{
                ForEach(jobs, id: \.self) { job in
                    NavigationLink(destination: TimerView(job: job)){
                        JobRow(job: job)
                    }
                }.onDelete(perform: deleteJob)
            }
                .listStyle(CarouselListStyle())
                .navigationBarTitle("ShiftTracker")
            }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Confirm Delete"),
                message: Text("Are you sure you want to delete this job?"),
                primaryButton: .destructive(Text("Delete"), action: confirmDelete),
                secondaryButton: .cancel()
            )
        }

                
        }
    }


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct TimerView: View {
    
    var job: Job
    
    var body: some View{
        
        NavigationStack{
        ScrollView{
            VStack{
                Text("cheese")
                    .padding()
                HStack{
                    Button(action: {
                        
                    }) {
                        Text("Start")
                            .bold()
                        
                    }
                    Button(action: {
                        
                    }) {
                        Text("End")
                            .bold()
                    }
                }
            }
        }
        .navigationBarTitle(job.name ?? "Unnamed Job")
    }
        }
    }
    
    /*
     struct TimerView_Previews: PreviewProvider {
     static var previews: some View {
     TimerView(job: <#JobData#>)
     }
     } */
    
    
    struct JobRow: View {
        var job: Job
        
        var body: some View {
            HStack{
                VStack(alignment: .leading, spacing: 5){
                    Image(systemName: job.icon ?? "briefcase.circle")
                        .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                        .font(.largeTitle)
                    Text(job.name ?? "Unnamed Job")
                        .font(.headline)
                        .bold()
                    Text(job.title ?? "")
                        .font(.footnote)
                        .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                        .bold()
                    
                }
                Spacer()
                
                VStack{
                    Button(action: {
                        
                    }) {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                    }
                    Spacer()
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 2)
        }
}
 
