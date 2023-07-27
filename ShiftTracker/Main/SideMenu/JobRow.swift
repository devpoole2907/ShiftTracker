//
//  JobRow.swift
//  ShiftTracker
//
//  Created by James Poole on 15/07/23.
//

import SwiftUI

struct JobRow: View {
    let job: Job
    let isSelected: Bool
    let editAction: () -> Void
    var showEdit: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: ContentViewModel
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        HStack(spacing: 10) {
            HStack {
                Image(systemName: job.icon ?? "briefcase.circle")
                    .font(.caption)
                    .foregroundStyle(.white)
                    
            }.padding(10)
                .background {
                    
                    Circle()
                        .foregroundStyle(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)).gradient)
                    
                }.frame(width: 25, alignment: .center)
                .padding(.horizontal, 5)
               
            
            Text(job.name ?? "")
                .bold()
                .foregroundColor(isSelected ? .white : textColor)
                .fontDesign(.rounded)
                .lineLimit(1)
                .allowsTightening(true)
            Spacer()
            if showEdit{
                Button(action: {
                    if (isSelected && viewModel.shift == nil) || !isSelected {
                        editAction()
                    }
                    else {
                        OkButtonPopup(title: "End your current shift before editing.", action: nil).showAndStack()
                    }}) {
                        Image(systemName: "pencil")
                            .foregroundColor(isSelected ? .white : textColor)
                    }.padding(.horizontal, 10)
            }
            
            
        }
    }
}
