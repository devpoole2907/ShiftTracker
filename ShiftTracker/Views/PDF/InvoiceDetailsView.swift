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
    
    var fileType: PdfFileType = .invoice
    
    init(invoiceNumber: String, invoiceDate: Date, dueDate: Date = Date(), fileType: PdfFileType = .invoice) {
        self.invoiceNumber = invoiceNumber
        self.invoiceDate = invoiceDate
        self.dueDate = dueDate
        self.fileType = fileType
    }
    
    var body: some View {
        
        VStack(alignment: .trailing, spacing: 2){
            Text("\(fileType.singularDescription)").bold().font(.subheadline)
            Text("\(fileType.singularDescription) No: \(invoiceNumber)")
            Text("\(fileType == .invoice ? "Invoice date:" : "Date:") \(invoiceDate.formatted(date: .long, time: .omitted))")
            if fileType == .invoice {
                Text("Due date: \(dueDate.formatted(date: .long, time: .omitted))")
            }
        }.font(.system(size: 8))
    }
    
}

#Preview {
    InvoiceDetailsView(invoiceNumber: "00001", invoiceDate: Date(), dueDate: Date())
}
