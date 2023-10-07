//
//  JobForShiftView.swift
//  ShiftTracker
//
//  Created by James Poole on 7/10/23.
//

import SwiftUI

struct JobForShiftView: View {
    
    @EnvironmentObject var viewModel: DetailViewModel
    
    var job: Job? = nil // used for when this view is displayed in the createshiftform where detailviewmodel isnt in the environment
    
    var body: some View {
        let jobData = job ?? viewModel.job ?? viewModel.shift?.job
        HStack{
            VStack(alignment: .leading, spacing: 2) {
                
                if let job = jobData {
                    let jobColor = Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue))
                    HStack{
                        
                        JobIconView(icon: job.icon ?? "", color: jobColor, font: .subheadline)
                        
                        
                    
                        
                        VStack(alignment: .leading, spacing: 3){
                            Text(job.name ?? "No Job Found")
                                .bold()
                                .font(.subheadline)
                                .roundedFontDesign()
                            
                            Divider().frame(maxWidth: 300)
                            
                            
                            Text(job.title ?? "No Job Title")
                                .foregroundStyle(jobColor.gradient)
                                .roundedFontDesign()
                                .bold()
                                .font(.caption)
                                .padding(.leading, 1.4)
                        }
                    }.padding(.vertical, 2)
                }
                
                
            }.frame(maxWidth: .infinity)
            Spacer()
        }
        
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
            .glassModifier(cornerRadius: 20)
    }
    
}

