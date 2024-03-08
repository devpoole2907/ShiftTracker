//
//  TotalPayView.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI

struct TotalPayView: View {
    
    var totalPay: Double
    
    var body: some View {
        
        VStack(alignment: .trailing, spacing: 5) {
            Divider()
            Text("Subtotal: $130.00")
            Text("GST (18.50%): $24.05")
            Text("Total: $\(totalPay)").bold()
        }.font(.system(size: 8))
        
    }
    
}

#Preview {
    TotalPayView(totalPay: 296.00)
}
