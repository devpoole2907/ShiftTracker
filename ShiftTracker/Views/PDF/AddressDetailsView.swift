//
//  AddressDetailsView.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI

struct AddressDetailsView: View {
    @Binding var name: String
    @Binding var streetAddress: String
    @Binding var city: String
    @Binding var state: String
    @Binding var postalCode: String
    @Binding var country: String
    
    var focused: FocusState<GenerateInvoiceView.Field?>.Binding
    
    var isClient: Bool
   

    var body: some View {
        VStack {
            CustomTextField(text: $name, hint: "Name/Company Name", capitaliseWords: true, isBold: true)
                .focused(focused, equals: isClient ? .clientName : .userName)
            
            CustomTextField(text: $streetAddress, hint: "Address", capitaliseWords: true)
                .focused(focused, equals: isClient ? .clientAddress : .userAddress)
            
            CustomTextField(text: $city, hint: "City", capitaliseWords: true)
                .focused(focused, equals: isClient ? .clientCity : .userCity)
            
            CustomTextField(text: $state, hint: "State", capitaliseWords: true)
                .focused(focused, equals: isClient ? .clientState : .userState)
            
            CustomTextField(text: $postalCode, hint: "Postal Code", capitaliseWords: true).keyboardType(.numberPad)
                .focused(focused, equals: isClient ? .clientPostalCode : .userPostalCode)

            
            CustomTextField(text: $country, hint: "Country", capitaliseWords: true)
                .focused(focused, equals: isClient ? .clientCountry : .userCountry)
        }
        .padding()
        .glassModifier(cornerRadius: 20)
    }
}


