//
//  InvoiceDetailsView.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI

struct InvoiceDetailsView: View {
    
    var body: some View {
        
        VStack(alignment: .trailing, spacing: 2){
            Text("Invoice").bold().font(.subheadline)
            Text("Invoice No: IN00007")
            Text("Invoice date: \(Date().formatted())")
            Text("Due date: \(Date().formatted())")
        }.font(.system(size: 8))
    }
    
}

#Preview {
    InvoiceDetailsView()
}
