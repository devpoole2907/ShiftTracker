//
//  PayPeriodInputView.swift
//  ShiftTracker
//
//  Created by James Poole on 21/12/23.
//

import SwiftUI

struct PayPeriodInputView: View {
    @Binding var payPeriodsEnabled: Bool
    @Binding var payPeriodDuration: Int
    @Binding var lastPayPeriodEndedDate: Date

    var body: some View {
        
        VStack {
            Toggle(isOn: $payPeriodsEnabled){
                
                Text("Pay Periods").bold()
                
            }.toggleStyle(CustomToggleStyle())
            
            HStack {
                
                Text("Schedule")
                Spacer()
                Picker("Pay Period Duration", selection: $payPeriodDuration) {
                    Text("Weekly").tag(7)
                    Text("Bi-Weekly").tag(14)
                   // Text("Monthly").tag(30)
                    // Add more options as needed
                }
                
            }
            .disabled(!payPeriodsEnabled)
            .opacity(payPeriodsEnabled ? 1.0 : 0.5)
            
            HStack(spacing: 4) {
                
                Text("Period ends")
                Button(action: {
                    
                }){
                    Image(systemName: "info.circle")
                }
                Spacer()
                DatePicker("Period ends", selection: $lastPayPeriodEndedDate, displayedComponents: .date)
                    .labelsHidden()
                
            }
            .disabled(!payPeriodsEnabled)
            .opacity(payPeriodsEnabled ? 1.0 : 0.5)
           
        
            
        }
    }
}
