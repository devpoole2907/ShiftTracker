//
//  CurrentShiftView.swift
//  ShiftTracker
//
//  Created by James Poole on 18/05/23.
//

import SwiftUI
import CoreData

struct CurrentShiftView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var viewModel: ContentViewModel
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM 'at' h:mm a"
        return formatter
    }()
    
    @State private var job: Job?
    
    var body: some View {
        
        let startDate = viewModel.shift?.startDate ?? Date()
        
        VStack(alignment: .leading) {
             
                HStack{
                    Text("Current Shift")
                        .font(.title3)
                        .bold()
                        .padding(.bottom, -1)
                    if startDate > Date(){
                        Text("Starting Soon")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .roundedFontDesign()
                            .bold()
                            .padding(.bottom, -1)
                    }
                }
    
                Divider().frame(maxWidth: startDate > Date() ? 240 : 200)
         
            if let job = job {
                HStack{
                    
                    let color = Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue))
                    JobIconView(icon: job.icon ?? "", color: color, font: .callout)
                 
                    
                    VStack(alignment: .leading, spacing: 5){
                        Text(job.name ?? "No Job Found")
                            .bold()
                        
                        Text("\(startDate,formatter: Self.dateFormatter)")
                            .foregroundColor(.gray)
                            .roundedFontDesign()
                            .bold()
                            .font(.footnote)
                            .padding(.leading, 1.4)
                    }
                }.padding(.vertical, 2)
            } else {
                Text("No Job Found")
                    .bold()
            }
            
            
        }.onAppear {
            job = selectedJobManager.fetchJob(in: viewContext)
        }
        
        .onReceive(viewModel.$timeElapsed) { _ in
            // listen to the time elapsed, refreshing view each time
        }
        
    }
}

