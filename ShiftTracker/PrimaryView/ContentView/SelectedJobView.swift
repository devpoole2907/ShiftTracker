//
//  SelectedJobView.swift
//  ShiftTracker
//
//  Created by James Poole on 18/05/23.
//

import SwiftUI

struct SelectedJobView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("Selected Job")
                .font(.headline)
                .bold()
                .padding(.bottom, -1)
            Divider().frame(maxWidth: 300)
            if let job = jobSelectionViewModel.fetchJob(in: viewContext) {
                HStack{
                    Image(systemName: job.icon ?? "briefcase.circle")
                        .font(.callout)
                        .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                    VStack(alignment: .leading, spacing: 3){
                        Text(job.name ?? "")
                            .font(.callout)
                            .bold()
                        Text(job.title ?? "")
                            .foregroundColor(.gray)
                            .bold()
                            .font(.caption)
                    }
                }.padding(.vertical, 3)
            
        }else {
                HStack{
                    Image(systemName: "briefcase.circle")
                    Text("None")
                        
                }.foregroundColor(.gray)
                    .font(.caption)
                    .bold()
                    .padding(.vertical, 2)
            }
            
            
        }
    }
}
