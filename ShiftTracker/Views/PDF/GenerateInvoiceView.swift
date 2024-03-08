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
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var username = ""
    
    init(shifts: FetchedResults<OldShift>? = nil, job: Job? = nil, selectedShifts: Set<NSManagedObjectID>? = nil, arrayShifts: [OldShift]? = nil, singleExportShift: OldShift? = nil) {
        self.viewModel = InvoiceViewModel(shifts: shifts, selectedShifts: selectedShifts, job: job, viewContext: PersistenceController.shared.container.viewContext, arrayShifts: arrayShifts, singleExportShift: singleExportShift)
    }
    
    
    
    var body: some View {
        
        let buttonColor: Color = colorScheme == .dark ? Color.white : Color.black
        let textColor: Color = colorScheme == .dark ? .white : .black
        
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
                
                ActionButtonView(title: "Export", backgroundColor: buttonColor, textColor: textColor, icon: "square.and.arrow.up.fill", buttonWidth: UIScreen.main.bounds.width - 60) {
                    
                   // dismiss()
                    
                    viewModel.render()
                    
                    viewModel.showPDFViewer.toggle()
                    
                    
                }.padding(.bottom, getRect().height == 667 ? 10 : 0)
                
       
            
        }
            
            .fullScreenCover(isPresented: $viewModel.showPDFViewer){
                
                if let url = viewModel.url {
                    InvoiceViewSheet(url: url)
                } else {
                    Text("Error")
                }
                
                
              
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


