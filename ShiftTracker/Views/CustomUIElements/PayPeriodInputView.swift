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
    
    // for possible monhtly pay period expansion in future
    @State private var monthlyPayPeriodType: Int = 1 // 1 for last business day, 2 for specific date, 3 for calendar month end
    
    @State var showTip = false
    
    var disablePickers: Bool
    
    // to only allow date selection within their pay period frequency
    var allowableDateRange: ClosedRange<Date> {
            let calendar = Calendar.current
            let today = Date()
            var pastDate: Date

            switch payPeriodDuration {
            case 7: // Weekly
                pastDate = calendar.date(byAdding: .day, value: -7, to: today)!
            case 14: // Bi-Weekly
                pastDate = calendar.date(byAdding: .day, value: -14, to: today)!
                
                // again, for future expansion
            case 0: // Monthly
                switch monthlyPayPeriodType {
                case 1: // Last business day
                    // logic for the last business day of the previous month
                    pastDate = getLastBusinessDayOfMonth()
                case 2: // specific date each month
                    // a specific date (like the 15th of every month)
                    pastDate = getSpecificDateOfMonth()
                default: // actual calendar month end
                    // first day of current month
                    let components = calendar.dateComponents([.year, .month], from: today)
                    pastDate = calendar.date(from: components)!
                }
            default:
                // Default to current date
                pastDate = today
            }

            return pastDate...today.endOfDay
        }

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
                   // Text("Monthly").tag(0)
              
                }

            }
            
          
            
            // new job will need to be created if you want to change the pickers values
            .disabled(!payPeriodsEnabled || disablePickers)
            .opacity((payPeriodsEnabled || disablePickers) ? 1.0 : 0.5)
            
            // again for possible future pay period expansion into monthly
            if payPeriodDuration == 0 {
                           Picker("Monthly Type", selection: $monthlyPayPeriodType) {
                               Text("Last Business Day").tag(1)
                               Text("Specific Date").tag(2)
                               Text("Calendar Month End").tag(3)
                           }
                       }
            
            HStack(spacing: 4) {

                Text("Period ends")
                
                if #available(iOS 17.0, *) {
                    // dont show button on ios 17, use tipkit
            
                    
                } else {
                    Button(action: {
                        showTip.toggle()
                    }){
                        Image(systemName: "info.circle")
                    }
                    
                }
            
          
                
                Spacer()
                DatePicker("Period ends", selection: $lastPayPeriodEndedDate, in: allowableDateRange, displayedComponents: .date)
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
    
    // for possible further expansion into monthly pay periods, with 3 varying types per the picker above

        func getLastBusinessDayOfMonth() -> Date {
            // logic to find last business day of previous month
            return Date() // replace with actual date
        }
        
        func getSpecificDateOfMonth() -> Date {
            //  logic to find the specific date of each month (like 15th)
            return Date() // replace with actual date
        }
    
}
