//
//  StatsSquare.swift
//  ShiftTracker
//
//  Created by James Poole on 2/07/23.
//

import SwiftUI
import CoreData

struct StatsSquare: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    
     var shifts: FetchedResults<OldShift>
    var shiftsThisWeek: FetchedResults<OldShift>
    
    var body: some View {
        
        let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)
        let headerColor: Color = colorScheme == .dark ? .white : .black
        
        let totalEarnings = shifts.reduce(0) { $0 + $1.totalPay }
        let totalHours = shifts.reduce(0) { $0 + ($1.duration / 3600.0) }
        let totalBreaks = shifts.reduce(0) { $0 + ($1.breakDuration / 3600.0) }
        
        let weeklyEarnings = shiftsThisWeek.reduce(0) { $0 + $1.totalPay }
        let weeklyHours = shiftsThisWeek.reduce(0) { $0 + ($1.duration / 3600.0) }
        let weeklyBreaks = shiftsThisWeek.reduce(0) { $0 + ($1.breakDuration / 3600.0) }
        
        HStack{
            VStack(alignment: .leading) {
                
                Text("This Week")
                    .font(.callout)
                    .bold()
                    .foregroundStyle(headerColor)
                if shiftManager.statsMode == .earnings {
                    Text("\(shiftManager.currencyFormatter.string(from: NSNumber(value: weeklyEarnings)) ?? "0")")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(headerColor)
                    
                    Text("\(shiftManager.currencyFormatter.string(from: NSNumber(value: totalEarnings)) ?? "0") Total")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(subTextColor)
                        .roundedFontDesign()
                    
                } else if shiftManager.statsMode == .hours {
                    
                    Text("\(shiftManager.formatTime(timeInHours: weeklyHours))")
                    
                        .font(.title2)
                        .bold()
                        .foregroundStyle(headerColor)
                    
                    Text("\(shiftManager.formatTime(timeInHours: totalHours)) Total")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(subTextColor)
                        .roundedFontDesign()
                    
                } else {
                    
                    Text("\(shiftManager.formatTime(timeInHours: weeklyBreaks))")
                    
                        .font(.title2)
                        .bold()
                        .foregroundStyle(headerColor)
                    
                    Text("\(shiftManager.formatTime(timeInHours: totalBreaks)) Total")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(subTextColor)
                        .roundedFontDesign()
                    
                }
                
                
                
            }
            .padding(.leading)
            Spacer()
        }
            .padding(.vertical, 16)
            .glassModifier(cornerRadius: 12, applyPadding: false)
        
          
    }
}


