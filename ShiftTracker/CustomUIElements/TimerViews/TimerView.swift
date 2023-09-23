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
    
    private let lightGradientColors = [
        Color.white.opacity(0.3),
        Color.white.opacity(0.1),
        Color.white.opacity(0.1),
        Color.white.opacity(0.4),
        Color.white.opacity(0.5),
    ]
    
    private let darkGradientColors = [
        Color.gray.opacity(0.2),
        Color.gray.opacity(0.1),
        Color.gray.opacity(0.1),
        Color.gray.opacity(0.3),
        Color.gray.opacity(0.2),
    ]
    
    let sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    // using the viewmodels variables directly causes a black screen/freeze
    
    private var totalPay: Double {
        
        if viewModel.isOnBreak && viewModel.totalPayAtBreakStart > 0.0 {
            return viewModel.totalPayAtBreakStart
        }
        
        let adjustedTimeElapsed = viewModel.timeElapsed - viewModel.totalBreakDuration() // Subtract break duration
        let adjustedTimeElapsedUntilOvertime = viewModel.timeElapsedUntilOvertime > 0 ? viewModel.timeElapsedUntilOvertime - viewModel.totalBreakDuration() : adjustedTimeElapsed
        
        if adjustedTimeElapsed >= viewModel.applyOvertimeAfter && viewModel.timeElapsedUntilOvertime == 0 && viewModel.overtimeRate > 1.0 {
            viewModel.timeElapsedUntilOvertime = adjustedTimeElapsed
            viewModel.overtimeEnabled = true
        }
        
        let basePay = adjustedTimeElapsedUntilOvertime / 3600.0 * viewModel.hourlyPay
        let overtimePay = viewModel.overtimeEnabled ? (adjustedTimeElapsed - viewModel.timeElapsedUntilOvertime) / 3600.0 * viewModel.hourlyPay * viewModel.overtimeRate : 0
        
        let pay = basePay + overtimePay

        return viewModel.isMultiplierEnabled ? pay * viewModel.payMultiplier : pay < 0 ? 0 : pay
    }



        private var taxedPay: Double {
            let pay = totalPay
            let taxPercentage = sharedUserDefaults.double(forKey: shiftKeys.taxPercentageKey)
            let afterTax = pay - (pay * taxPercentage / 100.0)
            return afterTax
        }
    
    
    var body: some View {
        
        var timeDigits = digitsFromTimeString(timeString: viewModel.timeElapsed.stringFromTimeInterval())
        
        let gradientColors = colorScheme == .dark ? darkGradientColors : lightGradientColors
        
        ZStack{
            
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
                .overlay {
               
                        RoundedRectangle(cornerRadius: 12)
                         .stroke(LinearGradient(colors: gradientColors,
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing))
              
                }
                .frame(width: getRect().width - 60)
               
        VStack(alignment: .center, spacing: 5) {
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
                    }.frame(maxWidth: getRect().width / 1.5 )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top)

            
            if sharedUserDefaults.double(forKey: shiftKeys.taxPercentageKey) > 0 {
                HStack(spacing: 2){
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 15).monospacedDigit())
                   
                    Text("\(currencyFormatter.string(from: NSNumber(value: taxedPay)) ?? "")")
                        .font(.system(size: 20).monospacedDigit())
                        .bold()
                        .lineLimit(1)
                        .allowsTightening(true)
                }.foregroundStyle(themeManager.taxColor)
                    .fontDesign(.rounded)
                
                
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







