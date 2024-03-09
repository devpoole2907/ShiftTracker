//
//  InvoiceInputPreviews.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI

struct InvoiceInputPreviews: View {
    
    @State private var jobName = ""
    
    @State private var streetAddress = ""
        @State private var city = ""
        @State private var state = ""
        @State private var postalCode = ""
        @State private var country = ""
    
    @State private var invoiceNumber = "" // should be number maybe not string??
    @State private var dueDate = Date()
    @State private var invoiceDate = Date()
    
    @State private var taxSelection: InterestOption = .single
    
    var body: some View {
        
        
        NavigationStack {
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
                
                    
                 //   clientDetails
                    
                    Text("Your Contact Info")
                        .bold()
                        .padding(.vertical, 5)
                        .padding(.horizontal)
                        .glassModifier(cornerRadius: 20)
                     
                    
                 //   userDetails
                    
                    Text("Tax Details")
                        .bold()
                        .padding(.vertical, 5)
                        .padding(.horizontal)
                        .glassModifier(cornerRadius: 20)
                    
                    taxDetails
                    
                }.padding(.horizontal, 12)
                
            }
            
            .navigationTitle("Generate Invoice")
            
            .navigationBarTitleDisplayMode(.inline)
            
                .toolbar {
                    CloseButton()
                }
        }
    }
    
  /*  var userDetails: some View {
        
        AddressDetailsView(name: $jobName, streetAddress: $jobName, city: $jobName, state: $jobName, postalCode: $invoiceNumber, country: $jobName)
        
        
    }
    
    var clientDetails: some View {
        
     

        AddressDetailsView(name: $jobName, streetAddress: $jobName, city: $jobName, state: $jobName, postalCode: $invoiceNumber, country: $jobName)
        
    }*/
    
    var taxDetails: some View {
        
        VStack {
            
          
            
            HStack {
                Text("Type")
                Spacer()
                Picker("Tax Type", selection: $taxSelection) {
                    ForEach(InterestOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                        
                    }
                }
            }
            
            .padding(.horizontal)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 20)
     
            CustomTextField(text: $jobName, hint: "Rate", leadingIcon: "percent", hasPersistentLeadingIcon: true).keyboardType(.decimalPad)
                .disabled(taxSelection == .none)
            
            CustomTextField(text: $jobName, hint: "Abbreviation e.g GST, VAT", hasPersistentLeadingIcon: true)
                .disabled(taxSelection == .none)
            
        }.frame(maxWidth: .infinity)
            .padding() .glassModifier(cornerRadius: 20)
        
    }
    
    var invoiceDetails: some View {
        
        VStack{
            
            IntegerTextField(placeholder: "Invoice Number", text: $invoiceNumber)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 20)
            
            DatePicker("Invoice date", selection: $invoiceDate, in: Date()..., displayedComponents: .date)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 20)
            
            DatePicker("Due date", selection: $dueDate, in: Date()..., displayedComponents: .date)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 20)
            
            
        }.padding() .glassModifier(cornerRadius: 20)
        
    }
    
}

#Preview {
    InvoiceInputPreviews()
}

enum InterestOption: String, CaseIterable, Identifiable {
    case none = "None"
    case single = "Single"
    case compound = "Compound"

    var id: String { self.rawValue }
}
