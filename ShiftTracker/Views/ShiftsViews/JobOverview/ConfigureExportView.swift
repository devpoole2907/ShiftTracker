//
//  ConfigureExportView.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import SwiftUI
import CoreData

struct ConfigureExportView: View {
    @ObservedObject var viewModel: ExportViewModel = ExportViewModel()
    var shifts: FetchedResults<OldShift>
    var job: Job?
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        let buttonColor: Color = colorScheme == .dark ? Color.white : Color.black
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        NavigationStack {
            
            ZStack(alignment: .bottom) {
            ScrollView{
                VStack(alignment: .leading) {
                    
                    Text("Include Columns").bold().textCase(nil) .roundedFontDesign().padding(.leading)
                    
                    ForEach(viewModel.selectedColumns.indices, id: \.self) { index in
                        Toggle(viewModel.selectedColumns[index].title, isOn: $viewModel.selectedColumns[index].isSelected).toggleStyle(CustomToggleStyle())
                            .bold()
                    }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .glassModifier(cornerRadius: 20)
            
                
            
                    HStack {
                        Text("Date Range").bold()
                        Spacer()
                        Picker("Date Range", selection: $viewModel.selectedDateRange) {
                            ForEach(ExportViewModel.DateRange.allCases, id: \.self) { range in
                                Text(range.title).tag(range)
                            }
                        }.bold()
                            .pickerStyle(.menu)
                    }
                        .padding(.horizontal)
                        .padding(.vertical, 7)
                        .glassModifier(cornerRadius: 20)
                    
                
                
                }.padding(.horizontal)
            
                
            }.scrollContentBackground(.hidden)
            
                ActionButtonView(title: "Export", backgroundColor: buttonColor, textColor: textColor, icon: "square.and.arrow.up.fill", buttonWidth: UIScreen.main.bounds.width - 60) {
                    
                    dismiss()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                        viewModel.exportCSV(shifts: shifts, viewContext: viewContext, job: job)
                    }
                    
                    
                }
            
        }
            
                .navigationTitle("Export")
                .navigationBarTitleDisplayMode(.inline)
            
            
                .trailingCloseButton()
            
        }
    }
}




