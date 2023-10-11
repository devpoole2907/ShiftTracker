//
//  StatsSquareViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 10/10/23.
//

import Foundation
import SwiftUI

class StatsSquareViewModel: ObservableObject {
    @Published var totalEarnings: Double = 0
    @Published var totalHours: Double = 0
    @Published var totalBreaks: Double = 0
    @Published var weeklyEarnings: Double = 0
    @Published var weeklyHours: Double = 0
    @Published var weeklyBreaks: Double = 0

    init(shifts: FetchedResults<OldShift>, weeklyShifts: FetchedResults<OldShift>) {
        
        // gcd here not swift concurrency (too strict, unnecessary complexity imo)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let totalEarnings = shifts.reduce(0) { $0 + $1.totalPay }
                        let totalHours = shifts.reduce(0) { $0 + ($1.duration / 3600.0) }
                        let totalBreaks = shifts.reduce(0) { $0 + ($1.breakDuration / 3600.0) }
            let weeklyEarnings = weeklyShifts.reduce(0) { $0 + $1.totalPay }
                  let weeklyHours = weeklyShifts.reduce(0) { $0 + ($1.duration / 3600.0) }
                  let weeklyBreaks = weeklyShifts.reduce(0) { $0 + ($1.breakDuration / 3600.0) }

            DispatchQueue.main.async {
                self?.totalEarnings = totalEarnings
                               self?.totalHours = totalHours
                               self?.totalBreaks = totalBreaks
                self?.weeklyEarnings = weeklyEarnings
                               self?.weeklyHours = weeklyHours
                               self?.weeklyBreaks = weeklyBreaks
            }
        }
    }
}
