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

    var body: some View {
        VStack {
            CustomUIKitTextField(placeholder: "Name/Company Name", text: $name, largeFont: false, rightAlign: true, capitaliseWords: true, showAlertSymbol: true)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 20)

            CustomUIKitTextField(placeholder: "Address", text: $streetAddress, largeFont: false, rightAlign: true, notBold: true, capitaliseWords: true, showAlertSymbol: true)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 20)

            CustomUIKitTextField(placeholder: "City", text: $city, largeFont: false, rightAlign: true, notBold: true, capitaliseWords: true, showAlertSymbol: true)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 20)

        
            CustomUIKitTextField(placeholder: "State", text: $state, largeFont: false, rightAlign: true, notBold: true, capitaliseWords: true, showAlertSymbol: true)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .glassModifier(cornerRadius: 20)

            IntegerTextField(placeholder: "Postal Code", text: $postalCode, showAlertSymbol: true)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .glassModifier(cornerRadius: 20)
            

            CustomUIKitTextField(placeholder: "Country", text: $country, largeFont: false, rightAlign: true, notBold: true, capitaliseWords: true, showAlertSymbol: true)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 20)
        }
        .padding()
        .glassModifier(cornerRadius: 20)
    }
}


