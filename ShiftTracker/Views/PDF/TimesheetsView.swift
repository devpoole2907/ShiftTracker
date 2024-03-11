//
//  TimesheetsView.swift
//  ShiftTracker
//
//  Created by James Poole on 11/03/2024.
//

import SwiftUI

// never displayed in the app, only used for the generated pdf/timesheet

struct TimesheetsView: View {
    
    // only show totals on last page
    var isLastPage: Bool
    var showDescription: Bool
    
    var tableCells: [ShiftTableCell]
    var totalSeconds: Double
    var breakSeconds: Double
    var overtimeSeconds: Double
    
    var timesheetNumber: String
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
    
    let shiftManager = ShiftDataManager()
    
    
    
    var body: some View {
        
      
            VStack(alignment: .leading, spacing: 20) {
                
                HStack {
                    InvoiceAddressView(clientName: userName, streetAddress: userStreetAddress, city: userCity, state: userState, postalCode: userPostalCode, country: userCountry, isClient: false).padding([.trailing, .bottom])
                    // for pdf gen
                    Spacer(minLength: 200)
                    // for swiftui preview
                    // Spacer()
                    InvoiceDetailsView(invoiceNumber: timesheetNumber, invoiceDate: invoiceDate, fileType: .timesheet).padding(.bottom)
                }
                
                InvoiceAddressView(clientName: clientName, streetAddress: clientStreetAddress, city: clientCity, state: clientState, postalCode: clientPostalCode, country: clientCountry, isClient: true, fileType: .timesheet)
                
                TimesheetTableView(tableCells: tableCells, showDescription: showDescription)
                
                    .padding(.bottom, isLastPage ? 0 : 35) // pushes view up slightly to match final page (which is higher due to totalpayview)
               // Spacer()
                
                if isLastPage {
           
                    VStack(alignment: .trailing, spacing: 5) {
                        Divider()
                        
                        Text("Total hours: \(shiftManager.formatTime(timeInHours: totalSeconds / 3600))")
                        
                        
                        
                        
                        
                    }.bold()
                .font(.system(size: 8))
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
        ShiftTableCell(date: Date(), duration: 36000, rate: 18.50, pay: 146, endtime: Date(), breakDuration: 3600, overtimeDuration: 1800, notes: "One two three four, so one two, then three and four. One and two, but also guten abend der zug kommt um drei minuten"),
        ShiftTableCell(date: Date(), duration: 36000, rate: 18.50, pay: 146, endtime: Date(), breakDuration: 3600, overtimeDuration: 1800),
        ShiftTableCell(date: Date(), duration: 36000, rate: 18.50, pay: 146, endtime: Date(), breakDuration: 3600, overtimeDuration: 1800),
        ShiftTableCell(date: Date(), duration: 36000, rate: 18.50, pay: 146, endtime: Date(), breakDuration: 3600, overtimeDuration: 1800)]
    
    return TimesheetsView(isLastPage: true, showDescription: true, tableCells: tableCells, totalSeconds: 3600, breakSeconds: 1800, overtimeSeconds: 600, timesheetNumber: "0007", invoiceDate: Date(), dueDate: Date(), clientName: "Apple, Inc", clientStreetAddress: "One Apple Park Way", clientCity: "Cupertino", clientState: "CA", clientPostalCode: "95014", clientCountry: "United States", userName: "Steve Jobs", userStreetAddress: "2044 Crist Drive", userCity: "Palo Alto", userState: "CA", userPostalCode: "94024", userCountry: "United States")
}
