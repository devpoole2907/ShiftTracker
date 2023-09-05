//
//  SettingsRow.swift
//  ShiftTracker
//
//  Created by James Poole on 5/09/23.
//

import SwiftUI

struct SettingsRow: View {
    var icon: String
    var title: String
    var secondaryInfo: String?
    var secondaryImage: String?
    
    init(icon: String, title: String, secondaryInfo: String? = nil, secondaryImage: String? = nil) {
        self.icon = icon
        self.title = title
        self.secondaryInfo = secondaryInfo
        self.secondaryImage = secondaryImage
    }
    
    var body: some View{
        HStack {
            
            Image(systemName: icon)
                .frame(width: 25, alignment: .center)
            Text(title)
                .font(.title2)
                .bold()
            
            Spacer()
            
            if let secondInfo = secondaryInfo {
                HStack(alignment: .center, spacing: 5){
                    Text(secondInfo)
                        .foregroundStyle(.gray)
                        .bold()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                        .bold()
                        .font(.caption)
                        .padding(.top, 1)
                }.fontDesign(.rounded)
                
            } else if let secondImage = secondaryImage {
                
                Image(systemName: secondImage)
                    .foregroundStyle(.gray)
                    .bold()
                
            }
            
            
            
        }
    }
}
