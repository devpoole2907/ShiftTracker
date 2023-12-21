//
//  PayPeriodPickerView.swift
//  ShiftTracker
//
//  Created by James Poole on 21/12/23.
//

import SwiftUI

struct PayPeriodPickerView: View {
    @Binding var selectedPayPeriod: PayPeriod?
    let allPayPeriods: [PayPeriod]

    var body: some View {
        List(allPayPeriods, id: \.self) { period in
            Button(action: {
                selectedPayPeriod = period
            }) {
                HStack {
                                    Text("From: \(period.startDate, formatter: itemFormatter)")
                                    Text("To: \(period.endDate, formatter: itemFormatter)")
                                }
            }
        }
    }

    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
