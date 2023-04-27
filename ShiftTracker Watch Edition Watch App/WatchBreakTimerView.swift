//
//  WatchBreakTimerView.swift
//  ShiftTracker Watch Edition Watch App
//
//  Created by James Poole on 27/04/23.
//

import SwiftUI

struct WatchBreakTimerView: View {
    @Binding var timeElapsed: TimeInterval
    
    @Environment(\.colorScheme) var colorScheme
    
    private let shiftKeys = ShiftKeys()
    
    let sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    var body: some View {
   
        VStack(alignment: .center, spacing: 5) {
            Text("\(timeElapsed.stringFromTimeInterval())")
                .foregroundColor(.indigo)
                .font(.caption).monospacedDigit() 
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

struct WatchBreakTimerView_Previews: PreviewProvider {
    static var previews: some View {
        WatchBreakTimerView(timeElapsed: .constant(3600))
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

