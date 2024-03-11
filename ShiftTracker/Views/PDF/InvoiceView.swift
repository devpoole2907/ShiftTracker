//
//  InvoiceView.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI

// never displayed in the app, only used for the generated pdf/invoice

struct InvoiceView: View {
    
    // only show totals on last page
    var isLastPage: Bool
    
    var tableCells: [ShiftTableCell]
    var totalPay: Double
    var taxedPay: Double
    var taxTaken: Double
    var taxRate: Double
    var abbreviation: String
    
    var invoiceNumber: String
    var invoiceDate: Date
    var dueDate: Date
    
    var clientName: String
    var clientStreetAddress: String
    var clientCity: String
    var clientState: String
    var clientPostalCode: String
    var clientCountry: String
    
    var userName: String
    var userStreetAddress: String
    var userCity: String
    var userState: String
    var userPostalCode: String
    var userCountry: String
    
    
    
    var body: some View {
        
      
            VStack(alignment: .leading, spacing: 20) {
                
                HStack {
                    InvoiceAddressView(clientName: userName, streetAddress: userStreetAddress, city: userCity, state: userState, postalCode: userPostalCode, country: userCountry, isClient: false).padding([.trailing, .bottom])
                    // for pdf gen
                    Spacer(minLength: 200)
                    // for swiftui preview
                    // Spacer()
                    InvoiceDetailsView(invoiceNumber: invoiceNumber, invoiceDate: invoiceDate, dueDate: dueDate).padding(.bottom)
                }
                
                InvoiceAddressView(clientName: clientName, streetAddress: clientStreetAddress, city: clientCity, state: clientState, postalCode: clientPostalCode, country: clientCountry, isClient: true)
                
                InvoiceTableView(tableCells: tableCells)
                
                    .padding(.bottom, isLastPage ? 0 : 35) // pushes view up slightly to match final page (which is higher due to totalpayview)
               // Spacer()
                
                if isLastPage {
           
                    
                    TotalPayView(totalPay: totalPay, taxTaken: taxTaken, taxedPay: taxedPay, abbreviation: abbreviation, taxRate: taxRate)
                        .padding(.bottom)
                } else {
                    Spacer(minLength: 30)
                }
                
               // Spacer()
            }.padding(20)
                .background(Color.white)//.ignoresSafeArea()
            //   .ignoresSafeArea()
            

            
        
        
    }
}

#Preview {
    
    
    let tableCells = [
          ShiftTableCell(date: Date(), duration: 36000, rate: 18.50, pay: 146, endtime: Date(), breakDuration: 3600, overtimeDuration: 1800),
          ShiftTableCell(date: Date(), duration: 36000, rate: 18.50, pay: 146, endtime: Date(), breakDuration: 3600, overtimeDuration: 1800),
          ShiftTableCell(date: Date(), duration: 36000, rate: 18.50, pay: 146, endtime: Date(), breakDuration: 3600, overtimeDuration: 1800),
          ShiftTableCell(date: Date(), duration: 36000, rate: 18.50, pay: 146, endtime: Date(), breakDuration: 3600, overtimeDuration: 1800)]
    
    return InvoiceView(isLastPage: true, tableCells: tableCells, totalPay: 246.0, taxedPay: 296.00, taxTaken: 30.00, taxRate: 18.50, abbreviation: "GST", invoiceNumber: "0007", invoiceDate: Date(), dueDate: Date(), clientName: "Apple, Inc", clientStreetAddress: "One Apple Park Way", clientCity: "Cupertino", clientState: "CA", clientPostalCode: "95014", clientCountry: "United States", userName: "Steve Jobs", userStreetAddress: "2044 Crist Drive", userCity: "Palo Alto", userState: "CA", userPostalCode: "94024", userCountry: "United States")
}

