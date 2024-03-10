//
//  PayPeriodDetailRow.swift
//  ShiftTracker
//
//  Created by James Poole on 10/03/24.
//

import SwiftUI

struct PayPeriodDetailRow: View {
    
    var payPeriod: PayPeriod
    
    init(_ payPeriod: PayPeriod) {
        self.payPeriod = payPeriod
    }
    
    var body: some View {
        
        
        Text("Pay period.")
        
    }
    
    
}
