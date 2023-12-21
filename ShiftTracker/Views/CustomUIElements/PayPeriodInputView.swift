//
//  PayPeriodInputView.swift
//  ShiftTracker
//
//  Created by James Poole on 21/12/23.
//

import SwiftUI
import PopupView

struct PayPeriodInputView: View {
    @Binding var payPeriodsEnabled: Bool
    @Binding var payPeriodDuration: Int
    @Binding var lastPayPeriodEndedDate: Date
    
    @State var showTip = false
    
    var disablePickers: Bool

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
            
            // new job will need to be created if you want to change the pickers values
            .disabled(!payPeriodsEnabled || disablePickers)
            .opacity((payPeriodsEnabled || disablePickers) ? 1.0 : 0.5)
            
            HStack(spacing: 4) {
                
                Text("Period ends")
                Button(action: {
                    showTip.toggle()
                }){
                    Image(systemName: "info.circle")
                }
                Spacer()
                DatePicker("Period ends", selection: $lastPayPeriodEndedDate, displayedComponents: .date)
                    .labelsHidden()
                    .disabled(!payPeriodsEnabled || disablePickers)
                
            }
          
            .opacity((payPeriodsEnabled || disablePickers) ? 1.0 : 0.5)
           
        
            
        }
        
        .sheet(isPresented: $showTip){
            NavigationStack{
                Text("Enter the date your last pay period ended.")
                    .trailingCloseButton()
            }
                .presentationDetents([.fraction(0.25)])
                .customSheetBackground()
                .customSheetRadius()
                
        }
        
    }
}
