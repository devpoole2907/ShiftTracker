//
//  TotalPayView.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI

struct TotalPayView: View {
    
    var totalPay: Double
    var taxTaken: Double
    var taxedPay: Double
    var abbreviation: String
    var taxRate: Double
    
    var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current // This will use the current locale of the device
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    func formatCurrency(_ value: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: value)) ?? ""
    }
    
    var body: some View {
        
        VStack(alignment: .trailing, spacing: 5) {
            Divider()
            // hide tax stuff if no tax taken, taxedPay will be the total in that case
            if taxTaken != 0.0 {
                Text("Subtotal: \(formatCurrency(totalPay))")
                Text("\(abbreviation) (\(taxRate.formatted(.number.precision(.fractionLength(2))))%): \(formatCurrency(taxTaken))")
            }
            Text("Total: \(formatCurrency(taxedPay))").bold()
        }.font(.system(size: 8))
        
    }
    
}

#Preview {
    TotalPayView(totalPay: 296.00, taxTaken: 30.00, taxedPay: 243.00, abbreviation: "GST", taxRate: 18.50)
}
