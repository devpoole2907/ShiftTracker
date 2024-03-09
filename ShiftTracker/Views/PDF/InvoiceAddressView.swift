//
//  ClientDetailsView.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI

struct InvoiceAddressView: View {
    
    var clientName: String
    var streetAddress: String
    var city: String
    var state: String
    var postalCode: String
    var country: String
    
    var isClient: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if isClient {
                Text("Invoice to").foregroundStyle(.white).padding(.horizontal).background(Color.black.opacity(0.5)).padding(.vertical, 2).font(.caption)
            }
            Text(clientName).bold()
            Text(streetAddress)
            Text(city)
            Text("\(state) \(postalCode)")
            Text(country)
        }.font(.system(size: 8))
    }
    
}

#Preview {
    InvoiceAddressView(clientName: "Steve Jobs", streetAddress: "2066 Crist Drive", city: "Palo Alto", state: "CA", postalCode: "94024", country: "United States", isClient: true)
}
