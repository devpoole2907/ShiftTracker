//
//  ChartSquareViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 10/10/23.
//

import Foundation
import SwiftUI

class ChartSquareViewModel: ObservableObject {
    @Published var weeklyData: [Double] = Array(repeating: 0, count: 7)
    
    init(shifts: FetchedResults<OldShift>, statsMode: StatsMode) {
        
        // gcd here not swift concurrency (too strict, unnecessary complexity imo)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            var tempData: [Double] = Array(repeating: 0, count: 7)
            
            for shift in shifts {
                guard let startDate = shift.shiftStartDate else { continue }
                
                let daysAgo = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
                
                if daysAgo < 7 {
                    var valueToAdd = 0.0
                    
                    switch statsMode {
                    case .earnings:
                        valueToAdd = shift.totalPay
                    case .hours:
                        valueToAdd = shift.duration
                    case .breaks:
                        valueToAdd = shift.breakDuration
                    }

                    tempData[daysAgo] += valueToAdd
                }
            }
            
            DispatchQueue.main.async {
                self?.weeklyData = tempData
            }
        }
    }
}
