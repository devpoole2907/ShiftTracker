//
//  HourlyPayCalculator.swift
//  ShiftTracker
//
//  Created by James Poole on 27/03/23.
//

import SwiftUI

struct HourlyPayCalculator: View {
    @State private var annualPay: Double = 0.0
    @State private var workHours: Double = 0.0
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    private let shiftKeys = ShiftKeys()
    
    @Environment(\.colorScheme) var colorScheme
    
    private var hourlyPay: Double {
        let weeksInYear = 52.0
        let hoursInWeek = workHours
        return annualPay / (weeksInYear * hoursInWeek)
    }
    
    var body: some View {
        
        
        let annualBackgroundColor: Color = colorScheme == .dark ? Color.green.opacity(0.5) : Color.green.opacity(0.8)
        let hoursBackgroundColor: Color = colorScheme == .dark ? Color.orange.opacity(0.5) : Color.orange.opacity(0.8)
        let buttonColor: Color = colorScheme == .dark ? Color.gray.opacity(0.5) : Color.black.opacity(0.5)
        
        NavigationStack {
            VStack(spacing: 1) {
                Text("Annual Pay")
                    .font(.headline)
                RoundedRectangle(cornerRadius: 20)
                    .fill(annualBackgroundColor)
                    .frame(height: 80)
                    .overlay(
                            TextField("p/yr", value: $annualPay, formatter: NumberFormatter())
                                
                                .font(.system(size: 50))
                                .fontWeight(.black)
                                .padding()
                                .multilineTextAlignment(.center)
                            )
                            .foregroundColor(.white)
                            .padding()
                    
                    .padding([.leading, .trailing, .bottom], 20)
                Text("Hours per Week")
                    .font(.headline)
                RoundedRectangle(cornerRadius: 20)
                    .fill(hoursBackgroundColor)
                    .frame(height: 100)
                    .overlay(
                        TextField("hr/wk", value: $workHours, formatter: NumberFormatter())
                            .font(.system(size: 60))
                            .fontWeight(.black)
                            .padding()
                            .multilineTextAlignment(.center)
                    )
                    .foregroundColor(.white)
                    .padding()
                    .padding([.leading, .trailing, .bottom], 10)
                
                Text("Hourly Pay")
                    .font(.title)
                    .bold()
                RoundedRectangle(cornerRadius: 20)
                    .fill(buttonColor)
                    .frame(height: 80)
                    .overlay(
                        Text(hourlyPay.isNaN ? "" : String(format: "$%.2f", hourlyPay))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(hourlyPay.isNaN || hourlyPay.isInfinite ? .clear : .white)
                    )
                    .foregroundColor(.white)
                    .padding()
                    .padding([.leading, .trailing, .bottom], 20)
                
                
                
                Spacer()
            }
            .padding(.top, 40)
            .padding()
            
        }
        .toolbar{
                   ToolbarItem(placement: .navigationBarTrailing) {
                       Button(action: {
                           sharedUserDefaults.set(hourlyPay, forKey: shiftKeys.hourlyPayKey)
                           sharedUserDefaults.synchronize()
                       }) {
                           Text("Save")
                       }
                   }
               }
    }
}


struct HourlyPayCalculator_Previews: PreviewProvider {
    static var previews: some View {
        HourlyPayCalculator()
    }
}

