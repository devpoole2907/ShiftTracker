//
//  InvoiceDetailsView.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI

struct InvoiceDetailsView: View {
    
    var invoiceNumber: String
    var invoiceDate: Date
    var dueDate: Date
    
    var body: some View {
        
        VStack(alignment: .trailing, spacing: 2){
            Text("Invoice").bold().font(.subheadline)
            Text("Invoice No: \(invoiceNumber)")
            Text("Invoice date: \(invoiceDate.formatted(date: .long, time: .omitted))")
            Text("Due date: \(dueDate.formatted(date: .long, time: .omitted))")
        }.font(.system(size: 8))
    }
    
}

#Preview {
    InvoiceDetailsView(invoiceNumber: "00001", invoiceDate: Date(), dueDate: Date())
}
