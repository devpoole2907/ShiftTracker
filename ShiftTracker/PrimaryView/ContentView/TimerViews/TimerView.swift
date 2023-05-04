//
//  TimerView.swift
//  ShiftTracker
//
//  Created by James Poole on 19/03/23.
//

import SwiftUI

struct TimerView: View {
    @Binding var timeElapsed: TimeInterval

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
        
        let taxedBackgroundColor: Color = colorScheme == .dark ? Color.green.opacity(0.5) : Color.green.opacity(0.8)
        let totalBackgroundColor: Color = colorScheme == .dark ? Color.pink.opacity(0.5) : Color.pink.opacity(0.8)
        let timerBackgroundColor: Color = colorScheme == .dark ? Color.orange.opacity(0.5) : Color.orange.opacity(0.8)

        var timeDigits = digitsFromTimeString(timeString: timeElapsed.stringFromTimeInterval())

        
        
        VStack(alignment: .center, spacing: 10) {
            if isOvertime{
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
            }
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                                   .frame(width: 350, height: 100)

                                  .foregroundColor(taxedBackgroundColor)
                                  .shadow(radius: 5, x: 0, y: 4)
                
                Text("\(currencyFormatter.string(from: NSNumber(value: taxedPay)) ?? "")")
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .font(.system(size: 70).monospacedDigit())
                    .fontWeight(.black)
                
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)
                    
                    
                    HStack(spacing: 0) {
                        ForEach(0..<timeDigits.count, id: \.self) { index in
                            RollingDigit(digit: timeDigits[index])
                                .frame(width: 30, height: 50)
                                .mask(FadeMask())
                            if index == 1 || index == 3 {
                                Text(":")
                                    .font(.system(size: 50, weight: .bold).monospacedDigit())
                            }
                        }
                    }
                    .foregroundColor(.orange)
                    .frame(width: 250, height: 70)
                
            
                
            
            if taxEnabled{
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: 175, height: 50)
                    .foregroundColor(totalBackgroundColor)
                    .shadow(radius: 5, x: 0, y: 4)
                
                Text("\(currencyFormatter.string(from: NSNumber(value: totalPay)) ?? "")")
                    .foregroundColor(.white)
                
                    .padding(.horizontal, 20)
                    .font(.system(size: 30).monospacedDigit())
                    .fontWeight(.heavy)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)
        }
            
             
        }
            .ignoresSafeArea()
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
        TimerView(timeElapsed: .constant(3600))
    }
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

struct RollingDigit: View {
    let digit: Int
    @State private var shouldAnimate = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach((0...10), id: \.self) { index in
                    Text(index == 10 ? "0" : "\(index)")
                        .font(.system(size: geometry.size.height).monospacedDigit())
                        .bold()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .offset(y: -CGFloat(digit) * geometry.size.height)
            .animation(shouldAnimate ? .easeOut(duration: 0.2) : nil)
            .onAppear {
                shouldAnimate = true
            }
            .onDisappear {
                shouldAnimate = false
            }
        }
    }
}

private func digitsFromTimeString(timeString: String) -> [Int] {
    return timeString.flatMap { char in
        if let digit = Int(String(char)) {
            return [digit]
        } else {
            return []
        }
    }
}
struct FadeMask: View {
    var body: some View {
        LinearGradient(gradient: Gradient(stops: [
            Gradient.Stop(color: Color.clear, location: 0),
            Gradient.Stop(color: Color.black, location: 0.1), // Adjust these values
            Gradient.Stop(color: Color.black, location: 0.9), // Adjust these values
            Gradient.Stop(color: Color.clear, location: 1),
        ]), startPoint: .top, endPoint: .bottom)
    }
}

