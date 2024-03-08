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
    
    var body: some View {
        
      
            VStack(alignment: .leading, spacing: 20) {
                
                HStack {
                    UserDetailsView().padding([.trailing, .bottom])
                    // for pdf gen
                    Spacer(minLength: 200)
                    // for swiftui preview
                    // Spacer()
                    InvoiceDetailsView().padding(.bottom)
                }
                
                ClientDetailsView()
                
                InvoiceTableView(tableCells: tableCells)
                
                    .padding(.bottom, isLastPage ? 0 : 35) // pushes view up slightly to match final page (which is higher due to totalpayview)
               // Spacer()
                
                if isLastPage {
                    
                    TotalPayView(totalPay: totalPay)//.padding(.leading)
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
          ShiftTableCell(date: Date(), duration: 36000, rate: 18.50, pay: 146),
          ShiftTableCell(date: Date(), duration: 36000, rate: 18.50, pay: 146),
          ShiftTableCell(date: Date(), duration: 36000, rate: 18.50, pay: 146),
          ShiftTableCell(date: Date(), duration: 36000, rate: 18.50, pay: 146)]
    
    return InvoiceView(isLastPage: true, tableCells: tableCells, totalPay: 246.0)
}

