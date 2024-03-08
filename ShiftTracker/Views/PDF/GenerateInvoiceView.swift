//
//  GenerateInvoiceView.swift
//  ShiftTracker
//
//  Created by James Poole on 8/03/24.
//

import SwiftUI
import CoreData

struct GenerateInvoiceView: View {
    
    @ObservedObject var viewModel: InvoiceViewModel
    
    @State var username = ""
    
    init(shifts: FetchedResults<OldShift>? = nil, job: Job? = nil, selectedShifts: Set<NSManagedObjectID>? = nil, arrayShifts: [OldShift]? = nil, singleExportShift: OldShift? = nil) {
        self.viewModel = InvoiceViewModel(shifts: shifts, selectedShifts: selectedShifts, job: job, viewContext: PersistenceController.shared.container.viewContext, arrayShifts: arrayShifts, singleExportShift: singleExportShift)
    }
    
    
    
    var body: some View {
        
        NavigationStack {
            
            ZStack(alignment: .bottom) {
            
            ScrollView {
                
                VStack {
                    
                    TextField("Your name", text: $username)
                    TextField("Street address", text: $username)
                    
              
                    
                    
                }.padding()
                    .glassModifier()
                    .padding()
                
                
            }
                
                ShareLink(item: viewModel.render(), label: {
                    
                    
                    
                    VStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up.fill")//.customAnimatedSymbol(value: $isActionButtonTapped)
                        //  .foregroundColor(textColor)
                        Text("Export")
                            .font(.subheadline)
                            .bold()
                        //  .foregroundColor(textColor)
                    }
                    .padding(.horizontal, 25)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .glassModifier(cornerRadius: 20, darker: true)
                    //.haptics(onChangeOf: isActionButtonTapped, type: .success)
                }).padding(.horizontal)
            
        }
            
        .toolbar{
            CloseButton()
        }
            
        
        .navigationTitle("Generate Invoice")
        .navigationBarTitleDisplayMode(.inline)
    }
        
        
    //
        
    }
    
    
}


