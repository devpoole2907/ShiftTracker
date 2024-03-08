//
//  InvoiceTableView.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI

struct InvoiceTableView: View {
    
    var tableCells: [ShiftTableCell]
    
    let shiftManager = ShiftDataManager()
    
    var body: some View {
        
       
                    Grid {
                        GridRow {
                            Text("Date")
                            Text("Hours")
                            Text("Rate")
                            Text("Cost")
                        }
                        .bold()
                        Divider()
                        ForEach(tableCells) { cell in
                            GridRow {
                                
                                if !cell.isEmpty {
                                    
                                    Text("\(cell.date.formatted(date: .abbreviated, time: .omitted))")
                                    
                                    Text("\(shiftManager.formatTime(timeInHours: cell.duration / 3600))")
                                    Text(cell.rate, format: .currency(code: "NZD"))
                                    Text(cell.pay, format: .currency(code: "NZD"))
                                } else {
                                    Text(" ").hidden()
                                                           Text(" ").hidden()
                                                           Text(" ").hidden()
                                                           Text(" ").hidden()
                                }
                            }
                            
                        }
                    }.font(.system(size: 8))
                .foregroundStyle(.black)
       
        
    }
    
}
