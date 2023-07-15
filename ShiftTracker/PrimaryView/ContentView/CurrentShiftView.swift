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
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    let startDate: Date
    
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM 'at' h:mm a"
        return formatter
    }()
    
    @State private var job: Job?
    
    var body: some View {
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
                            .bold()
                            .padding(.bottom, -1)
                    }
                }
            if startDate > Date(){
                Divider().frame(maxWidth: 240)
            }
            else {
                Divider().frame(maxWidth: 200)
            }
            if let job = job {
                HStack{
                    Image(systemName: job.icon ?? "")
                        .font(.callout)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background {
                            let color = Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)).gradient
                            Circle()
                                .foregroundStyle(color)
                          
                            
                                
                            
                        }
                    
                    VStack(alignment: .leading, spacing: 5){
                        Text(job.name ?? "No Job Found")
                            .bold()
                        Text("\(startDate,formatter: Self.dateFormatter)")
                            .foregroundColor(.gray)
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
            job = jobSelectionViewModel.fetchJob(in: viewContext)
        }
    }
}
/*
 struct Previews_CurrentShiftView_Previews: PreviewProvider {
 static var previews: some View {
 CurrentShiftView(jobUUID: UUID(), startDate: Date())
 }
 }
 */
