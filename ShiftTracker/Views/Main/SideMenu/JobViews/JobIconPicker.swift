//
//  JobIconPicker.swift
//  ShiftTracker
//
//  Created by James Poole on 7/10/23.
//

import SwiftUI

struct JobIconPicker: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var jobViewModel: JobViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 50)), count: 4), spacing: 50) {
                    ForEach(jobViewModel.jobIcons, id: \.self) { icon in
                        Button(action: {
                            
                            jobViewModel.selectedIcon = icon
                            
                            dismiss()
                        }) {
                            VStack {
                                Image(systemName: icon)
                                    .font(.title2)
                                
                                    .frame(height: 20)
                                    .shadow(color: .white, radius: 0.7)
                                    .foregroundStyle(.white)
                                
                            }.padding()
                                .background{
                                    Circle()
                                        .foregroundStyle(jobViewModel.selectedColor.gradient)
                                    
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Icon", displayMode: .inline)
            
            
            .toolbar {
                
                
                CloseButton()
                
            }
            
        }
    }
}

#Preview {
    JobIconPicker().environmentObject(JobViewModel())
}
