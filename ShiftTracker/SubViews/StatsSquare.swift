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
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    
    var body: some View {
        
        let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)
        let headerColor: Color = colorScheme == .dark ? .white : .black
        HStack{
            VStack(alignment: .leading) {
                
                Text("This Week")
                    .font(.callout)
                    .bold()
                    .foregroundStyle(headerColor)
                if shiftManager.statsMode == .earnings {
                    Text("\(shiftManager.currencyFormatter.string(from: NSNumber(value: shiftManager.weeklyTotalPay)) ?? "0")")
                        .font(.title)
                        .bold()
                        .foregroundStyle(headerColor)
                } else {
                    
                    Text("\(shiftManager.formatTime(timeInHours: shiftManager.weeklyTotalHours))")
                    
                        .font(.title)
                        .bold()
                        .foregroundStyle(headerColor)
                }
                
                if shiftManager.statsMode == .earnings {
                    Text("\(shiftManager.currencyFormatter.string(from: NSNumber(value: shiftManager.totalPay)) ?? "0") Total")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(subTextColor)
                } else {

                    Text("\(shiftManager.formatTime(timeInHours: shiftManager.totalHours)) Total")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(subTextColor)
                }
                
            }
            .padding(.leading)
            Spacer()
        }
            .padding(.vertical, 16)
            .background(Color("SquaresColor"))
            .cornerRadius(12)
        
          
    }
}

struct StatsSquare_Previews: PreviewProvider {
    static var previews: some View {
        StatsSquare()
            .previewLayout(.fixed(width: 400, height: 200)) // Change the width and height as per your requirement
    }
}

