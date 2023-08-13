//
//  TimerView.swift
//  ShiftTracker
//
//  Created by James Poole on 19/03/23.
//

import SwiftUI

struct TimerView: View {
    
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var viewModel: ContentViewModel

    @Environment(\.colorScheme) var colorScheme
    
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
       return overtimeEnabled && viewModel.timeElapsed > sharedUserDefaults.double(forKey: shiftKeys.overtimeAppliedAfterKey)
    }
    
    
    // using the viewmodels variables directly causes a black screen/freeze
    
    private var totalPay: Double {
            let hourlyPay = sharedUserDefaults.double(forKey: shiftKeys.hourlyPayKey)
        let overtimeRate = sharedUserDefaults.double(forKey: shiftKeys.overtimeMultiplierKey)
        let overtimeAppliedAfter = sharedUserDefaults.double(forKey: shiftKeys.overtimeAppliedAfterKey)
        let overtimeEnabled = sharedUserDefaults.bool(forKey: shiftKeys.overtimeEnabledKey)
        let payMultiplier = sharedUserDefaults.double(forKey: shiftKeys.payMultiplierKey)
           let isMultiplierEnabled = sharedUserDefaults.bool(forKey: shiftKeys.multiplierEnabledKey)
        

        let rawPay: Double
            if !isOvertime {
                rawPay = (viewModel.timeElapsed / 3600.0) * hourlyPay
            } else {
                let regularTime = overtimeAppliedAfter //* 3600.0
                let overtime = viewModel.timeElapsed - regularTime
                let regularPay = (regularTime / 3600.0) * hourlyPay
                let overtimePay = (overtime / 3600.0) * hourlyPay * overtimeRate
                rawPay = regularPay + overtimePay
            }
        
        let totalPay = isMultiplierEnabled ? rawPay * payMultiplier : rawPay
            return totalPay < 0 ? 0 : totalPay
        
        
        
        }

        private var taxedPay: Double {
            let pay = totalPay
            let taxPercentage = sharedUserDefaults.double(forKey: shiftKeys.taxPercentageKey)
            let afterTax = pay - (pay * taxPercentage / 100.0)
            return afterTax
        }
    
    
    var body: some View {
        
        var timeDigits = digitsFromTimeString(timeString: viewModel.timeElapsed.stringFromTimeInterval())
        
        
        ZStack{
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(Color("SquaresColor"))
                .frame(width: UIScreen.main.bounds.width - 60)
                .shadow(radius: 5, x: 2, y: 4)
               
        VStack(alignment: .center, spacing: 5) {
           /* if isOvertime{
                Text("OVERTIME")
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 200, height: 20)
                    .background(.red.opacity(0.8))
                    .cornerRadius(12)
                    .fixedSize()
            }
            else {
                Text("")
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 200, height: 20)
                    .background(Color.clear)
                    .cornerRadius(12)
                    .fixedSize()
            } */
            ZStack {
                // This is the center aligned text
                Text("\(currencyFormatter.string(from: NSNumber(value: totalPay)) ?? "")")
                    .padding(.horizontal, 20)
                    .font(.system(size: 60).monospacedDigit())
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, alignment: .center) // added this
                
                // This is the conditionally displayed multiplier text
                if viewModel.isMultiplierEnabled {
                    HStack {
                        Spacer()
                        Text("x\(viewModel.payMultiplier, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .bold()
                    }.frame(maxWidth: UIScreen.main.bounds.width / 1.5 )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top)

            
            if sharedUserDefaults.double(forKey: shiftKeys.taxPercentageKey) > 0 {
                HStack(spacing: 2){
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 15).monospacedDigit())
                        .fontWeight(.light)
                    Text("\(currencyFormatter.string(from: NSNumber(value: taxedPay)) ?? "")")
                        .font(.system(size: 20).monospacedDigit())
                        .bold()
                        .lineLimit(1)
                        .allowsTightening(true)
                }.foregroundStyle(themeManager.taxColor)
                
                    .padding(.horizontal, 20)
                
                
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 5)
            }
            
            Divider().frame(maxWidth: 200)
            
            HStack(spacing: 0) {
                ForEach(0..<timeDigits.count, id: \.self) { index in
                    RollingDigit(digit: timeDigits[index])
                        .frame(width: 20, height: 30)
                        .mask(FadeMask())
                    if index == 1 || index == 3 {
                        Text(":")
                            .font(.system(size: 30, weight: .bold).monospacedDigit()).fontDesign(.rounded)
                    }
                }
            }
            .foregroundStyle(themeManager.timerColor)
            .frame(maxWidth: .infinity)
            .padding(.bottom)
            
            
            
            
           
            
            
        }
        
        }
        
    }
}

private func secondsToHoursMinutesSeconds (seconds : Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let seconds = (seconds % 3600) % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
    }
}







