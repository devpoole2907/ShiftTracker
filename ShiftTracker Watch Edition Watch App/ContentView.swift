//
//  ContentView.swift
//  ShiftTracker Watch Edition Watch App
//
//  Created by James Poole on 25/04/23.
//

import SwiftUI
import WatchConnectivity



struct ContentView: View {
    
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    
    
    
    var body: some View {
        NavigationStack{
                List(connectivityManager.receivedJobs, id: \.id) { job in
                    NavigationLink(destination: TimerView(job: job)){
                        JobRow(job: job)
                    }
                }.onReceive(connectivityManager.$receivedJobs) { jobs in
                    print("Received jobs: \(jobs)")
                }
                .listStyle(CarouselListStyle())
                .navigationBarTitle("ShiftTracker")
            }
                
        }
    }


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct TimerView: View {
    
    var job: JobData
    
    var body: some View{
        
        ScrollView{
            Text("cheese")
                .padding()
        }
        .navigationBarTitle(job.name)
    }
}

/*
struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView(job: <#JobData#>)
    }
} */


struct JobRow: View {
    var job: JobData
    
    var body: some View {
        HStack{
            VStack(alignment: .leading, spacing: 5){
                Image(systemName: job.icon)
                    .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                    .font(.title)
                Text(job.name)
                    .font(.headline)
                    .bold()
                Text(job.title)
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
                        .font(.title2)
                }
                Spacer()
            }
        }
        .padding()
    }
}
 
