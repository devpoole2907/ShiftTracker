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
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    
    @AppStorage("lastSelectedJobUUID") private var lastSelectedJobUUID: String?
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        HStack(spacing: 10) {
            
                JobIconView(icon: job.icon ?? "briefcase.circle", color: Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)), font: .caption)
                
       
          
               
            
            Text(job.name ?? "")
                .bold()
                .foregroundStyle(textColor)
                .roundedFontDesign()
                .lineLimit(1)
                .allowsTightening(true)
            Spacer()
            if showEdit{
                Button(action: {
                    if (isSelected && viewModel.shift == nil) || !isSelected {
                        editAction()
                    }
                    else {
                        OkButtonPopup(title: "End your current shift before editing.").showAndStack()
                    }}) {
                        Image(systemName: purchaseManager.hasUnlockedPro
                                                   || selectedJobManager.selectedJobUUID == job.uuid
                                                   || (job.uuid?.uuidString == lastSelectedJobUUID)
                                                   || (lastSelectedJobUUID == nil)
                                              ? "pencil"
                                                   : "lock.fill")
                           
                        .foregroundStyle(textColor)
                    }.padding(.horizontal, 10)
            }
            
            
        }
    }
}
