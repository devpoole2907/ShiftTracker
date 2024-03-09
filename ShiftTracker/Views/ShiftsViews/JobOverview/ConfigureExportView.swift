//
//  ConfigureExportView.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import SwiftUI
import CoreData
import TipKit

struct ConfigureExportView: View {
    @StateObject var viewModel: ExportViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    init(shifts: FetchedResults<OldShift>? = nil, job: Job? = nil, selectedShifts: Set<NSManagedObjectID>? = nil, arrayShifts: [OldShift]? = nil, singleExportShift: OldShift? = nil) {
        _viewModel = StateObject(wrappedValue: ExportViewModel(shifts: shifts, selectedShifts: selectedShifts, job: job, viewContext: PersistenceController.shared.container.viewContext, arrayShifts: arrayShifts, singleExportShift: singleExportShift))

        
    }
    
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
                  
            
                
                    if viewModel.selectedShifts == nil && viewModel.singleExportShift == nil {
                        
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
                       
                    }
                    
                    if #available(iOS 17.0, *) {
                        TipView(ExportCSVTip(), arrowEdge: .none)
                            .padding()
                    }
                
                    Spacer(minLength: 150)
                
                }.padding(.horizontal)
            
                
                
            }.scrollContentBackground(.hidden)
       
                  
                    ActionButtonView(title: "Export to CSV", backgroundColor: buttonColor, textColor: textColor, icon: "square.and.arrow.up.fill", buttonWidth: UIScreen.main.bounds.width - 60) {
                        
                        dismiss()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                            viewModel.exportCSV()
                        }
                        
                        
                    }.padding(.bottom, getRect().height == 667 ? 10 : 0)
                    
                
             
            
        }
            
                .navigationTitle("Export")
                .navigationBarTitleDisplayMode(.inline)
            
            
                .trailingCloseButton()
            
        }
    }
}




