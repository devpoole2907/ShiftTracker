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
    
    @FocusState var focusField: Field?
    
    @State var username = ""
    
    init(shifts: FetchedResults<OldShift>? = nil, job: Job? = nil, selectedShifts: Set<NSManagedObjectID>? = nil, arrayShifts: [OldShift]? = nil, singleExportShift: OldShift? = nil) {
        self.viewModel = InvoiceViewModel(shifts: shifts, selectedShifts: selectedShifts, job: job, viewContext: PersistenceController.shared.container.viewContext, arrayShifts: arrayShifts, singleExportShift: singleExportShift)
    }
    
    enum Field: CaseIterable {
        case invoiceNo, clientName, clientAddress, clientCity, clientState, clientPostalCode, clientCountry, userName, userAddress, userCity, userState, userPostalCode, userCountry
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
    
    func updateFocus(direction: Direction) {
        guard let currentField = focusField else { return }
        
        let allFields = Field.allCases
        if let currentIndex = allFields.firstIndex(of: currentField) {
            let nextIndex = direction == .up ? max(currentIndex - 1, 0) : min(currentIndex + 1, allFields.count - 1)
            focusField = allFields[nextIndex]
        }
    }

    enum Direction {
        case up, down
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
                    
                 
                    Spacer(minLength: 400)
              
                    
                    
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
                    NavigationStack {
                        InvoiceViewSheet(isSheet: true, url: url).environmentObject(viewModel)
                    }
                } else {
                    Text("Error")
                }
                
                
              
            }
            
        .toolbar{
            ToolbarItem(placement: .topBarTrailing) {
                CloseButton()
            }
            
            
            
            
                            ToolbarItemGroup(placement: .keyboard) {
                                HStack {
                               
                                            Button(action: { updateFocus(direction: .up) }) {
                                                Image(systemName: "chevron.up")
                                            }.bold()
                                            Button(action: { updateFocus(direction: .down) }) {
                                                Image(systemName: "chevron.down")
                                            }.bold()
                                        
                                    Spacer()
                                    Button("Done") {
                                        hideKeyboard()
                                    }.bold()
                                }
                            }
                        
        }
            
        
        .navigationTitle("Generate Invoice")
        .navigationBarTitleDisplayMode(.inline)
    }
        
        
    //
        
    }
    
    
    var userDetails: some View {
        
        AddressDetailsView(name: $viewModel.userName, streetAddress: $viewModel.userStreetAddress, city: $viewModel.userCity, state: $viewModel.userState, postalCode: $viewModel.userPostalCode, country: $viewModel.userCountry, focused: $focusField, isClient: false)
        
        
    }
    
    var clientDetails: some View {
        
        AddressDetailsView(name: $viewModel.jobName, streetAddress: $viewModel.clientStreetAddress, city: $viewModel.clientCity, state: $viewModel.clientState, postalCode: $viewModel.clientPostalCode, country: $viewModel.clientCountry, focused: $focusField, isClient: true)
        
    }
    
    var invoiceDetails: some View {
        
        VStack{

            CustomTextField(text: $viewModel.invoiceNumber, hint: "Invoice Number", capitaliseWords: true).focused($focusField, equals: .invoiceNo)
             
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


