//
//  ShiftDetailRow.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI

struct ShiftDetailRow: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    let shift: OldShift
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        HStack{
            let shiftStartDate = shift.shiftStartDate ?? Date()
            let shiftEndDate = shift.shiftEndDate ?? Date()
            let duration = shiftEndDate.timeIntervalSince(shiftStartDate) / 3600.0
            let durationString = String(format: "%.1f", duration)
            
            let dateString = dateFormatter.string(from: shiftStartDate)
            let payString = String(format: "%.2f", shift.taxedPay)
            
            VStack(alignment: .leading, spacing: 5){
                Text("\(currencyFormatter.currencySymbol ?? "")\(payString)")
                    .foregroundColor(textColor)
                    .font(.title)
                    .bold()
                Text(" \(durationString) hours")
                    .foregroundStyle(themeManager.timerColor)
                    .font(.subheadline)
                    .bold()
                Text(dateString)
                    .foregroundColor(.gray)
                    .font(.footnote)
                    .bold()
            }
            
        }
    }
}
