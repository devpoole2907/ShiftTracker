//
//  WatchTimerView.swift
//  ShiftTracker Watch Edition Watch App
//
//  Created by James Poole on 27/04/23.
//

import SwiftUI

struct WatchTimerView: View {
    @Binding var timeElapsed: TimeInterval

    private let shiftKeys = ShiftKeys()
    
    let sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
   private var isOvertime: Bool {
       let overtimeEnabled = sharedUserDefaults.bool(forKey: shiftKeys.overtimeEnabledKey)
       return overtimeEnabled && timeElapsed > sharedUserDefaults.double(forKey: shiftKeys.overtimeAppliedAfterKey)
    }
    
    
    private var totalPay: Double {
            let hourlyPay = sharedUserDefaults.double(forKey: shiftKeys.hourlyPayKey)
        let overtimeRate = sharedUserDefaults.double(forKey: shiftKeys.overtimeMultiplierKey)
        let overtimeAppliedAfter = sharedUserDefaults.double(forKey: shiftKeys.overtimeAppliedAfterKey)
        let overtimeEnabled = sharedUserDefaults.bool(forKey: shiftKeys.overtimeEnabledKey)

            if !isOvertime {
                let pay = (timeElapsed / 3600.0) * hourlyPay
                return pay
            } else {
                let regularTime = overtimeAppliedAfter //* 3600.0
                print("regular time " + String(regularTime))
                let overtime = timeElapsed - regularTime
                let regularPay = (regularTime / 3600.0) * hourlyPay
                let overtimePay = (overtime / 3600.0) * hourlyPay * overtimeRate
                return regularPay + overtimePay
            }
        }

        private var taxedPay: Double {
            let pay = totalPay
            let taxPercentage = sharedUserDefaults.double(forKey: shiftKeys.taxPercentageKey)
            let afterTax = pay - (pay * taxPercentage / 100.0)
            return afterTax
        }
    
    
    var body: some View {
  
        VStack(alignment: .center, spacing: 5) {
            
            // change to taxed pay at some point
            Text("\(currencyFormatter.string(from: NSNumber(value: totalPay)) ?? "")")
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .font(.system(size: 35).monospacedDigit())
                .fontWeight(.black)
                .background(.green.opacity(0.5))
                .cornerRadius(12)
            
          /*  Text("\(currencyFormatter.string(from: NSNumber(value: totalPay)) ?? "")")
               // .foregroundColor(.green)
                
                .padding(.horizontal, 10)
                .font(.system(size: 20).monospacedDigit())
                .fontWeight(.heavy)
                .background(.pink.opacity(0.5))
                .cornerRadius(12) */
            
            Text("\(timeElapsed.stringFromTimeInterval())")
           
                .foregroundColor(.orange)
                .font(.title).monospacedDigit()
        }
            //.ignoresSafeArea()
    }
}

private func secondsToHoursMinutesSeconds (seconds : Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let seconds = (seconds % 3600) % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

private extension TimeInterval {
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let hours = (time / 3600)
        let minutes = (time / 60) % 60
        let seconds = time % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}

struct WatchTimerView_Previews: PreviewProvider {
    static var previews: some View {
        WatchTimerView(timeElapsed: .constant(3600))
    }
}
