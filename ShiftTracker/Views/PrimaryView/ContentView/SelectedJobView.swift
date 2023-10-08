//
//  SelectedJobView.swift
//  ShiftTracker
//
//  Created by James Poole on 18/05/23.
//

import SwiftUI

struct SelectedJobView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("Selected Job")
                .font(.headline)
                .bold()
                .padding(.bottom, -1)
            Divider().frame(maxWidth: 300)
            if let job = selectedJobManager.fetchJob(in: viewContext) {
                HStack{
                    
                    JobIconView(icon: job.icon ?? "briefcase", color: Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)), font: .callout)
                
                    VStack(alignment: .leading, spacing: 3){
                        Text(job.name ?? "")
                            .font(.callout)
                            .bold()
                        Text(job.title ?? "")
                            .foregroundColor(.gray)
                            .roundedFontDesign()
                            .bold()
                            .font(.caption)
                    }
                }.padding(.vertical, 3)
            
        }else {
                HStack{
                    Image(systemName: "briefcase.circle")
                    Text("None")
                        
                }.foregroundColor(.gray)
                .roundedFontDesign()
                    .font(.caption)
                    .bold()
                    .padding(.vertical, 2)
            }
            
            
        }
    }
}
