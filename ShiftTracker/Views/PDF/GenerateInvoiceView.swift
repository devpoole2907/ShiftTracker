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
    
    var isFormValid: Bool {
        !viewModel.userName.isEmpty &&
        !viewModel.userStreetAddress.isEmpty &&
        !viewModel.userCity.isEmpty &&
        !viewModel.userState.isEmpty &&
        !viewModel.userPostalCode.isEmpty &&
        !viewModel.userCountry.isEmpty &&
        !viewModel.jobName.isEmpty &&
        !viewModel.clientStreetAddress.isEmpty &&
        !viewModel.clientCity.isEmpty &&
        !viewModel.clientState.isEmpty &&
        !viewModel.clientPostalCode.isEmpty &&
        !viewModel.clientCountry.isEmpty &&
        !viewModel.invoiceNumber.isEmpty
    }
    
    
    
    var body: some View {
        
        let buttonColor: Color = colorScheme == .dark ? Color.white : Color.black
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        NavigationStack {
            
            ZStack(alignment: .bottom) {
            
            ScrollView {
                
                VStack(alignment: .leading, spacing: 12) {
                    
                    Text("Invoice Details")
                        .bold()
                        .padding(.vertical, 5)
                        .padding(.horizontal)
                        .glassModifier(cornerRadius: 20)
                    
                    invoiceDetails
                    
                    Text("Client Details")
                        .bold()
                        .padding(.vertical, 5)
                        .padding(.horizontal)
                        .glassModifier(cornerRadius: 20)
                    
                    clientDetails
                    
                    
                    Text("Your Contact Info")
                        .bold()
                        .padding(.vertical, 5)
                        .padding(.horizontal)
                        .glassModifier(cornerRadius: 20)
                    
                    userDetails
                    
                 
                    Spacer(minLength: 300)
              
                    
                    
                }.padding(.horizontal, 12)
                
                
            }
                
                ActionButtonView(title: "Generate", backgroundColor: buttonColor, textColor: textColor, icon: "printer.fill.and.paper.fill", buttonWidth: UIScreen.main.bounds.width - 60) {

                    viewModel.render()
                    
                    viewModel.showPDFViewer.toggle()
                    
                    
                }.padding(.bottom, getRect().height == 667 ? 10 : 0)
                    .opacity(isFormValid ? 1.0 : 0.5)
                    .disabled(!isFormValid)
                
       
            
        }  .ignoresSafeArea(.keyboard)
            
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
    
    
    var userDetails: some View {
        
        AddressDetailsView(name: $viewModel.userName, streetAddress: $viewModel.userStreetAddress, city: $viewModel.userCity, state: $viewModel.userState, postalCode: $viewModel.userPostalCode, country: $viewModel.userCountry)
        
        
    }
    
    var clientDetails: some View {
        
        AddressDetailsView(name: $viewModel.jobName, streetAddress: $viewModel.clientStreetAddress, city: $viewModel.clientCity, state: $viewModel.clientState, postalCode: $viewModel.clientPostalCode, country: $viewModel.clientCountry)
        
    }
    
    var invoiceDetails: some View {
        
        VStack{
            
            IntegerTextField(placeholder: "Invoice Number", text: $viewModel.invoiceNumber, showAlertSymbol: true)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 20)
            
            DatePicker("Invoice date", selection: $viewModel.invoiceDate, in: Date()..., displayedComponents: .date)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 20)
            
            DatePicker("Due date", selection: $viewModel.dueDate, in: Date()..., displayedComponents: .date)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 20)
            
            
        }.padding() .glassModifier(cornerRadius: 20)
        
    }
    
    
}


