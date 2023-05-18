//
//  SelectedJobView.swift
//  ShiftTracker
//
//  Created by James Poole on 18/05/23.
//

import SwiftUI

struct SelectedJobView: View {
    
    let jobName: String?
    let jobTitle: String?
    let jobIcon: String?
    let jobColor: Color?
    
    init(jobName: String? = nil, jobTitle: String? = nil, jobIcon: String? = nil, jobColor: Color? = nil) {
            self.jobName = jobName
            self.jobTitle = jobTitle
            self.jobIcon = jobIcon
            self.jobColor = jobColor
        }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("Selected Job")
                .font(.headline)
                .bold()
            Divider().frame(maxWidth: 300)
            
            if let jobName = jobName, let jobTitle = jobTitle, let jobIcon = jobIcon, let jobColor = jobColor {
                HStack{
                    Image(systemName: jobIcon)
                        .font(.callout)
                        .foregroundColor(jobColor)
                    VStack(alignment: .leading, spacing: 3){
                        Text(jobName)
                            .font(.callout)
                            .bold()
                        Text(jobTitle)
                            .foregroundColor(.gray)
                            .bold()
                            .font(.caption)
                    }
                }.padding(.vertical, 3)
            }  else {
                HStack{
                    Image(systemName: "briefcase.circle")
                    Text("None")
                        
                }.foregroundColor(.gray)
                    .font(.caption)
                    .bold()
                    .padding(.vertical, 3)
            }
            
            
        }
    }
}
